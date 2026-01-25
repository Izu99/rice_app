const express = require('express')
const router = express.Router()
const mongoose = require('mongoose')
const auth = require('../middleware/auth')
const companyGuard = require('../middleware/companyGuard')
const roleGuard = require('../middleware/roleGuard')
const { validationResult } = require('express-validator')
const { errorResponse, successResponse } = require('../utils/responseHandler')

// Import models
const Customer = require('../models/Customer')
const Transaction = require('../models/Transaction')

// Helper to find customer by ID or clientId
const findCustomer = async (id, companyFilter) => {
  const query = mongoose.Types.ObjectId.isValid(id)
    ? { _id: id, ...companyFilter }
    : { clientId: id, ...companyFilter }
  return await Customer.findOne(query)
}

// Import validators (to be implemented)
const {
  validateCustomerCreation,
  validateCustomerUpdate
} = require('../validators/customerValidator')

// Apply authentication and company isolation to all routes
router.use(auth)
router.use(companyGuard)

/**
 * @route   GET /api/customers
 * @desc    Get all customers with filtering and pagination
 * @access  Private (Company users)
 */
router.get('/', async (req, res) => {
  try {
    const {
      search,
      isActive,
      page = 1,
      limit = 20,
      sortBy = 'createdAt',
      sortOrder = 'desc'
    } = req.query

    // Build query with company filter
    const query = { ...req.companyFilter }

    if (isActive !== undefined) query.isActive = isActive === 'true'

    if (search) {
      query.$or = [
        { name: { $regex: search, $options: 'i' } },
        { phone: { $regex: search, $options: 'i' } }
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
      customers,
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
})

/**
 * @route   GET /api/customers/check-phone/:phone
 * @desc    Check if phone number exists for company
 * @access  Private (Company users)
 */
router.get('/check-phone/:phone', async (req, res) => {
  try {
    const customer = await Customer.findOne({
      phone: req.params.phone,
      ...req.companyFilter
    })

    if (customer) {
      return successResponse(res, 'Phone number exists', {
        exists: true,
        customer: {
          id: customer._id,
          name: customer.name,
          phone: customer.phone,

          isActive: customer.isActive
        }
      })
    }

    return successResponse(res, 'Phone number available', {
      exists: false
    })
  } catch (error) {
    console.error('Check Phone Error:', error)
    return errorResponse(res, 'Error checking phone number', 500, error.message)
  }
})

/**
 * @route   GET /api/customers/phone
 * @desc    Get single customer by phone query param
 * @access  Private (Company users)
 */
router.get('/phone', async (req, res) => {
  try {
    const { phone } = req.query
    if (!phone) {
      return errorResponse(res, 'Phone number is required', 400)
    }

    const customer = await Customer.findOne({
      phone,
      ...req.companyFilter
    })

    if (!customer) {
      return errorResponse(res, 'Customer not found', 404)
    }

    return successResponse(res, 'Customer details retrieved successfully', customer)
  } catch (error) {
    console.error('Get Customer By Phone Error:', error)
    return errorResponse(res, 'Error retrieving customer details', 500, error.message)
  }
})

/**
 * @route   GET /api/customers/:id
 * @desc    Get single customer details with statistics
 * @access  Private (Company users)
 */
router.get('/:id', async (req, res) => {
  try {
    const customer = await findCustomer(req.params.id, req.companyFilter)

    if (!customer) {
      return errorResponse(res, 'Customer not found', 404)
    }

    // Get recent transactions (last 10)
    const recentTransactions = await Transaction.find({
      customerId: customer._id,
      ...req.companyFilter
    })
      .sort({ createdAt: -1 })
      .limit(10)
      .select('transactionNumber type totalAmount paidAmount balance status transactionDate')

    // Get customer statistics
    const statistics = {
      totalTransactions: await Transaction.countDocuments({
        customerId: customer._id,
        ...req.companyFilter
      }),
      totalBuyAmount: customer.totalBuyAmount,
      totalSellAmount: customer.totalSellAmount,
      balance: customer.balance
    }

    const data = {
      customer,
      recentTransactions,
      statistics
    }

    return successResponse(res, 'Customer details retrieved successfully', data)
  } catch (error) {
    console.error('Get Customer Error:', error)
    return errorResponse(res, 'Error retrieving customer details', 500, error.message)
  }
})

/**
 * @route   GET /api/customers/check-phone/:phone
 * @desc    Check if phone number exists for company
 * @access  Private (Company users)
 */
router.get('/check-phone/:phone', async (req, res) => {
  try {
    const customer = await Customer.findOne({
      phone: req.params.phone,
      ...req.companyFilter
    })

    if (customer) {
      return successResponse(res, 'Phone number exists', {
        exists: true,
        customer: {
          id: customer._id,
          name: customer.name,
          phone: customer.phone,

          isActive: customer.isActive
        }
      })
    }

    return successResponse(res, 'Phone number available', {
      exists: false
    })
  } catch (error) {
    console.error('Check Phone Error:', error)
    return errorResponse(res, 'Error checking phone number', 500, error.message)
  }
})

/**
 * @route   POST /api/customers
 * @desc    Create new customer
 * @access  Private (Company users)
 */
router.post('/', validateCustomerCreation, async (req, res) => {
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
      nic,
      notes,
      clientId
    } = req.body

    // Check if phone already exists for this company
    const existingCustomer = await Customer.findOne({
      phone,
      ...req.companyFilter
    })

    if (existingCustomer) {
      return errorResponse(res, 'Customer with this phone already exists', 409, {
        existingCustomer: {
          id: existingCustomer._id,
          name: existingCustomer.name,
          phone: existingCustomer.phone
        }
      })
    }

    // Create customer
    const customer = await Customer.create({
      name,
      phone,
      email,
      address,
      nic,
      notes,
      clientId,
      companyId: req.companyId
    })

    return successResponse(res, 'Customer created successfully', { customer }, 201)
  } catch (error) {
    console.error('Create Customer Error:', error)

    // Handle duplicate clientId
    if (error.code === 11000 && error.keyPattern?.clientId) {
      return errorResponse(res, 'Customer with this client ID already exists', 409)
    }

    return errorResponse(res, 'Error creating customer', 500, error.message)
  }
})

/**
 * @route   POST /api/customers/sync
 * @desc    Sync offline customers
 * @access  Private (Company users)
 */
router.post('/sync', async (req, res) => {
  try {
    const { customers } = req.body
    if (!customers || !Array.isArray(customers)) {
      return errorResponse(res, 'Customers array is required', 400)
    }

    const synced = []
    for (const customerData of customers) {
      /* eslint-disable camelcase */
      const { local_id, phone, name, address, city, nic_number, email, notes } = customerData

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
          companyId: req.companyId,
          clientId: local_id
        })
      }
      /* eslint-enable camelcase */

      synced.push(customer)
    }

    return successResponse(res, 'Customers synced successfully', { synced })
  } catch (error) {
    console.error('Sync Customers Error:', error)
    return errorResponse(res, 'Error syncing customers', 500, error.message)
  }
})

/**
 * @route   PUT /api/customers/:id
 * @desc    Update customer details
 * @access  Private (Company users)
 */
router.put('/:id', validateCustomerUpdate, async (req, res) => {
  try {
    const errors = validationResult(req)
    if (!errors.isEmpty()) {
      return errorResponse(res, 'Validation failed', 400, errors.array())
    }

    const customer = await findCustomer(req.params.id, req.companyFilter)
    if (!customer) {
      return errorResponse(res, 'Customer not found', 404)
    }

    const allowedUpdates = [
      'name', 'phone', 'email', 'address', 'nic',
      'notes', 'isActive'
    ]

    const updates = {}
    allowedUpdates.forEach(field => {
      if (req.body[field] !== undefined) {
        updates[field] = req.body[field]
      }
    })

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

    return successResponse(res, 'Customer updated successfully', { customer })
  } catch (error) {
    console.error('Update Customer Error:', error)
    return errorResponse(res, 'Error updating customer', 500, error.message)
  }
})

/**
 * @route   DELETE /api/customers/:id
 * @desc    Delete customer (soft delete)
 * @access  Private (Company users)
 */
router.delete('/:id', async (req, res) => {
  try {
    const customer = await findCustomer(req.params.id, req.companyFilter)

    if (!customer) {
      return errorResponse(res, 'Customer not found', 404)
    }

    // Check for existing transactions
    const transactionCount = await Transaction.countDocuments({
      customerId: customer._id,
      ...req.companyFilter
    })

    if (transactionCount > 0) {
      return errorResponse(res, 'Cannot delete customer with existing transactions', 400)
    }

    // Soft delete by deactivating
    customer.isActive = false
    await customer.save()

    return successResponse(res, 'Customer deleted successfully')
  } catch (error) {
    console.error('Delete Customer Error:', error)
    return errorResponse(res, 'Error deleting customer', 500, error.message)
  }
})

/**
 * @route   GET /api/customers/:id/transactions
 * @desc    Get customer's transaction history
 * @access  Private (Company users)
 */
router.get('/:id/transactions', async (req, res) => {
  try {
    const {
      startDate,
      endDate,
      page = 1,
      limit = 20,
      type
    } = req.query

    // Verify customer exists and belongs to company
    const customer = await findCustomer(req.params.id, req.companyFilter)

    if (!customer) {
      return errorResponse(res, 'Customer not found', 404)
    }

    // Build transaction query
    const transactionQuery = {
      customerId: customer._id,
      ...req.companyFilter
    }

    if (type) transactionQuery.type = type

    if (startDate || endDate) {
      transactionQuery.transactionDate = {}
      if (startDate) transactionQuery.transactionDate.$gte = new Date(startDate)
      if (endDate) transactionQuery.transactionDate.$lte = new Date(endDate)
    }

    // Get transactions with pagination
    const transactions = await Transaction.find(transactionQuery)
      .sort({ transactionDate: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit)
      .select('transactionNumber type totalAmount paidAmount balance status transactionDate')

    const total = await Transaction.countDocuments(transactionQuery)
    const pages = Math.ceil(total / limit)

    // Get summary statistics
    const summary = {
      totalBuy: customer.totalBuyAmount,
      totalSell: customer.totalSellAmount,
      balance: customer.balance
    }

    const data = {
      transactions,
      summary,
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
})

module.exports = router
