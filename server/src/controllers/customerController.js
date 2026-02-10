const mongoose = require('mongoose')
const Customer = require('../models/Customer')
const Transaction = require('../models/Transaction')
const { validationResult } = require('express-validator')
const { errorResponse, successResponse } = require('../utils/responseHandler')

/**
 * @desc    Get all customers with filtering and pagination
 * @route   GET /api/customers
 * @access  Private (Company users)
 */
exports.getCustomers = async (req, res) => {
  try {
    const {
      type,
      search,
      isActive,
      page = 1,
      limit = 20,
      sortBy = 'createdAt',
      sortOrder = 'desc'
    } = req.query

    // Build query with company filter
    const query = { ...req.companyFilter }

    if (type) query.customerType = type
    if (isActive !== undefined) query.isActive = isActive === 'true'

    if (search) {
      query.$or = [
        { name: { $regex: search, $options: 'i' } },
        { phone: { $regex: search, $options: 'i' } },
        { email: { $regex: search, $options: 'i' } }
      ]
    }

    // Build sort
    const sort = {}
    sort[sortBy] = sortOrder === 'desc' ? -1 : 1

    // Execute query with pagination
    const customers = await Customer.find(query)
      .sort(sort)
      .limit(limit * 1)
      .skip((page - 1) * limit)

    const total = await Customer.countDocuments(query)
    const pages = Math.ceil(total / limit)

    const data = {
      customers: customers.map(c => c.getSummary()),
      pagination: {
        total,
        page: parseInt(page),
        limit: parseInt(limit),
        pages
      }
    }

    return successResponse(res, 'Customers retrieved successfully', data)
  } catch (error) {
    console.error('Get Customers Error:', error)
    return errorResponse(res, 'Error retrieving customers', 500, error.message)
  }
}

/**
 * @desc    Get customer by ID with transaction history
 * @route   GET /api/customers/:id
 * @access  Private (Company users)
 */
exports.getCustomerById = async (req, res) => {
  try {
    const id = req.params.id
    const query = mongoose.Types.ObjectId.isValid(id)
      ? { _id: id, ...req.companyFilter }
      : { clientId: id, ...req.companyFilter }

    const customer = await Customer.findOne(query)

    if (!customer) {
      return errorResponse(res, 'Customer not found', 404)
    }

    // Get recent transactions
    const recentTransactions = await Transaction.find({
      customerId: customer._id,
      ...req.companyFilter
    })
      .sort({ transactionDate: -1 })
      .limit(10)
      .select('transactionNumber type totalAmount paidAmount balance status transactionDate')

    // Get transaction statistics
    const transactionStats = await Transaction.aggregate([
      { $match: { customerId: customer._id, companyId: new mongoose.Types.ObjectId(req.companyId) } },
      {
        $group: {
          _id: '$type',
          count: { $sum: 1 },
          totalAmount: { $sum: '$totalAmount' }
        }
      }
    ])

    const buyStats = transactionStats.find(s => s._id === 'buy') || { count: 0, totalAmount: 0 }
    const sellStats = transactionStats.find(s => s._id === 'sell') || { count: 0, totalAmount: 0 }

    const data = {
      customer: customer.getSummary(),
      recentTransactions,
      statistics: {
        totalTransactions: buyStats.count + sellStats.count,
        totalBuyAmount: buyStats.totalAmount,
        totalSellAmount: sellStats.totalAmount,
        balance: customer.balance,
        netAmount: sellStats.totalAmount - buyStats.totalAmount
      }
    }

    return successResponse(res, 'Customer details retrieved successfully', data)
  } catch (error) {
    console.error('Get Customer Error:', error)
    return errorResponse(res, 'Error retrieving customer details', 500, error.message)
  }
}

/**
 * @desc    Check if phone number exists
 * @route   GET /api/customers/check-phone/:phone
 * @access  Private (Company users)
 */
exports.checkPhone = async (req, res) => {
  try {
    const phone = req.params.phone

    const customer = await Customer.findOne({
      phone,
      ...req.companyFilter
    })

    if (customer) {
      return successResponse(res, 'Phone number found', {
        exists: true,
        customer: customer.getSummary()
      })
    } else {
      return successResponse(res, 'Phone number available', {
        exists: false
      })
    }
  } catch (error) {
    console.error('Check Phone Error:', error)
    return errorResponse(res, 'Error checking phone number', 500, error.message)
  }
}

/**
 * @desc    Create a new customer
 * @route   POST /api/customers
 * @access  Private (Company users)
 */
exports.createCustomer = async (req, res) => {
  try {
    const errors = validationResult(req)
    if (!errors.isEmpty()) {
      return errorResponse(res, 'Validation failed', 400, errors.array())
    }

    const {
      name,
      phone,
      email,
      address,
      city,
      nic,
      customer_type,
      notes,
      clientId
    } = req.body

    // Check if customer with same phone already exists for this company
    const existingCustomer = await Customer.findOne({
      phone,
      ...req.companyFilter
    })

    if (existingCustomer) {
      return successResponse(res, 'Customer with this phone already exists', {
        exists: true,
        customer: existingCustomer.getSummary()
      })
    }

    // Create customer
    const customer = await Customer.create({
      name,
      phone,
      email,
      address,
      city,
      nic,
      customerType: customer_type || 'seller',
      notes,
      companyId: req.companyId,
      clientId
    })

    return successResponse(res, 'Customer created successfully', {
      customer: customer.getSummary()
    }, 201)
  } catch (error) {
    console.error('Create Customer Error:', error)

    // Handle duplicate key errors
    if (error.code === 11000) {
      const field = Object.keys(error.keyPattern)[0]
      return errorResponse(res, `Customer with this ${field} already exists`, 409)
    }

    return errorResponse(res, 'Error creating customer', 500, error.message)
  }
}

/**
 * @desc    Update customer
 * @route   PUT /api/customers/:id
 * @access  Private (Company users)
 */
exports.updateCustomer = async (req, res) => {
  try {
    const errors = validationResult(req)
    if (!errors.isEmpty()) {
      return errorResponse(res, 'Validation failed', 400, errors.array())
    }

    const id = req.params.id
    const query = mongoose.Types.ObjectId.isValid(id)
      ? { _id: id, ...req.companyFilter }
      : { clientId: id, ...req.companyFilter }

    const customer = await Customer.findOne(query)

    if (!customer) {
      return errorResponse(res, 'Customer not found', 404)
    }

    const allowedUpdates = [
      'name', 'phone', 'email', 'address', 'nic', 'city',
      'customerType', 'notes', 'isActive'
    ]

    const updates = {}
    allowedUpdates.forEach(field => {
      if (req.body[field] !== undefined) {
        updates[field] = req.body[field]
      }
    })

    // Map API customer_type to DB customerType
    if (req.body.customer_type !== undefined) {
      updates.customerType = req.body.customer_type
    }

    // Prevent phone number conflicts within company
    if (updates.phone) {
      const existingCustomer = await Customer.findOne({
        phone: updates.phone,
        _id: { $ne: customer._id },
        ...req.companyFilter
      })

      if (existingCustomer) {
        return errorResponse(res, 'Another customer with this phone number already exists', 409)
      }
    }

    Object.assign(customer, updates)
    await customer.save()

    return successResponse(res, 'Customer updated successfully', {
      customer: customer.getSummary()
    })
  } catch (error) {
    console.error('Update Customer Error:', error)

    // Handle duplicate key errors
    if (error.code === 11000) {
      const field = Object.keys(error.keyPattern)[0]
      return errorResponse(res, `Customer with this ${field} already exists`, 409)
    }

    return errorResponse(res, 'Error updating customer', 500, error.message)
  }
}

/**
 * @desc    Sync offline customers
 * @route   POST /api/customers/sync
 * @access  Private (Company users)
 */
exports.syncCustomers = async (req, res) => {
  try {
    const { customers } = req.body
    if (!customers || !Array.isArray(customers)) {
      return errorResponse(res, 'Customers array is required', 400)
    }

    const synced = []
    for (const customerData of customers) {
      const { local_id, phone, name, address, city, nic_number, email, notes, customer_type } = customerData

      // Try to find existing customer by phone or client_id (local_id)
      let customer = await Customer.findOne({
        $or: [
          { phone },
          { clientId: local_id }
        ],
        companyId: req.companyId
      })

      if (customer) {
        // Update existing
        customer.name = name || customer.name
        customer.address = address || customer.address
        customer.city = city || customer.city
        customer.email = email || customer.email
        customer.nic = nic_number || customer.nic
        customer.notes = notes || customer.notes
        customer.customerType = customer_type || customer.customerType
        await customer.save()
      } else {
        // Create new
        customer = await Customer.create({
          name,
          phone,
          address,
          city,
          email,
          nic: nic_number,
          notes,
          customerType: customer_type,
          companyId: req.companyId,
          clientId: local_id
        })
      }

      synced.push(customer.getSummary())
    }

    return successResponse(res, 'Customers synced successfully', { synced })
  } catch (error) {
    console.error('Sync Customers Error:', error)
    return errorResponse(res, 'Error syncing customers', 500, error.message)
  }
}

/**
 * @desc    Delete customer (soft delete)
 * @route   DELETE /api/customers/:id
 * @access  Private (Company users)
 */
exports.deleteCustomer = async (req, res) => {
  try {
    const id = req.params.id
    const query = mongoose.Types.ObjectId.isValid(id)
      ? { _id: id, ...req.companyFilter }
      : { clientId: id, ...req.companyFilter }

    const customer = await Customer.findOne(query)

    if (!customer) {
      return errorResponse(res, 'Customer not found', 404)
    }

    // Check if customer has transactions
    const transactionCount = await Transaction.countDocuments({
      customerId: customer._id,
      ...req.companyFilter
    })

    if (transactionCount > 0) {
      return errorResponse(res, 'Cannot delete customer with existing transactions. Deactivate instead.', 400)
    }

    customer.isActive = false
    await customer.save()

    return successResponse(res, 'Customer deactivated successfully')
  } catch (error) {
    console.error('Delete Customer Error:', error)
    return errorResponse(res, 'Error deleting customer', 500, error.message)
  }
}

/**
 * @desc    Get customer's transaction history
 * @route   GET /api/customers/:id/transactions
 * @access  Private (Company users)
 */
exports.getCustomerTransactions = async (req, res) => {
  try {
    const {
      type,
      startDate,
      endDate,
      page = 1,
      limit = 20
    } = req.query

    const id = req.params.id
    const query = mongoose.Types.ObjectId.isValid(id)
      ? { _id: id, ...req.companyFilter }
      : { clientId: id, ...req.companyFilter }

    const customer = await Customer.findOne(query)

    if (!customer) {
      return errorResponse(res, 'Customer not found', 404)
    }

    // Build transaction query
    const transactionQuery = {
      customerId: customer._id,
      companyId: new mongoose.Types.ObjectId(req.companyId)
    }

    if (type) transactionQuery.type = type

    if (startDate || endDate) {
      transactionQuery.transactionDate = {}
      if (startDate) transactionQuery.transactionDate.$gte = new Date(startDate)
      if (endDate) transactionQuery.transactionDate.$lte = new Date(endDate)
    }

    // Get transactions
    const transactions = await Transaction.find(transactionQuery)
      .sort({ transactionDate: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit)

    const total = await Transaction.countDocuments(transactionQuery)
    const pages = Math.ceil(total / limit)

    // Calculate summary
    const summary = await Transaction.aggregate([
      { $match: transactionQuery },
      {
        $group: {
          _id: '$type',
          totalAmount: { $sum: '$totalAmount' },
          count: { $sum: 1 }
        }
      }
    ])

    const buyStats = summary.find(s => s._id === 'buy') || { totalAmount: 0 }
    const sellStats = summary.find(s => s._id === 'sell') || { totalAmount: 0 }

    const data = {
      customer: customer.getSummary(),
      transactions,
      summary: {
        totalBuy: buyStats.totalAmount,
        totalSell: sellStats.totalAmount,
        balance: customer.balance,
        transactionCount: total
      },
      pagination: {
        total,
        page: parseInt(page),
        limit: parseInt(limit),
        pages
      }
    }

    return successResponse(res, 'Customer transactions retrieved successfully', data)
  } catch (error) {
    console.error('Get Customer Transactions Error:', error)
    return errorResponse(res, 'Error retrieving customer transactions', 500, error.message)
  }
}
