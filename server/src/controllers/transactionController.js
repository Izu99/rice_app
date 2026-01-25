const Transaction = require('../models/Transaction')
const Customer = require('../models/Customer')
const StockItem = require('../models/StockItem')
const { validationResult } = require('express-validator')
const { errorResponse, successResponse } = require('../utils/responseHandler')
const mongoose = require('mongoose')

/**
 * @desc    Get all transactions with filtering and pagination
 * @route   GET /api/transactions
 * @access  Private (Company users)
 */
exports.getTransactions = async (req, res) => {
  try {
    const {
      type,
      status,
      customerId,
      startDate,
      endDate,
      page = 1,
      limit = 20,
      sortBy = 'transactionDate',
      sortOrder = 'desc'
    } = req.query

    // Build query with company filter
    const query = { ...req.companyFilter }

    if (type) query.type = type
    if (status) query.status = status
    if (customerId) query.customerId = customerId

    if (startDate || endDate) {
      query.transactionDate = {}
      if (startDate) query.transactionDate.$gte = new Date(startDate)
      if (endDate) query.transactionDate.$lte = new Date(endDate)
    }

    // Build sort
    const sort = {}
    sort[sortBy] = sortOrder === 'desc' ? -1 : 1

    // Get transactions
    const transactions = await Transaction.find(query)
      .populate('customerId', 'name phone')
      .populate('createdBy', 'name')
      .sort(sort)
      .limit(limit * 1)
      .skip((page - 1) * limit)

    // Calculate summary
    const summaryStats = await Transaction.aggregate([
      { $match: query },
      {
        $group: {
          _id: '$type',
          count: { $sum: 1 },
          totalAmount: { $sum: '$totalAmount' },
          totalPaid: { $sum: '$paidAmount' }
        }
      }
    ])

    const buyStats = summaryStats.find(s => s._id === 'buy') || { count: 0, totalAmount: 0 }
    const sellStats = summaryStats.find(s => s._id === 'sell') || { count: 0, totalAmount: 0 }

    const total = await Transaction.countDocuments(query)
    const pages = Math.ceil(total / limit)

    const data = {
      transactions,
      summary: {
        totalBuyTransactions: buyStats.count,
        totalSellTransactions: sellStats.count,
        totalBuyAmount: buyStats.totalAmount,
        totalSellAmount: sellStats.totalAmount,
        totalRevenue: sellStats.totalAmount,
        totalExpenses: buyStats.totalAmount,
        pendingPayments: Math.max(0, buyStats.totalAmount - sellStats.totalAmount)
      },
      pagination: {
        total,
        page: parseInt(page),
        limit: parseInt(limit),
        pages
      }
    }

    return successResponse(res, 'Transactions retrieved successfully', data)
  } catch (error) {
    console.error('Get Transactions Error:', error)
    return errorResponse(res, 'Error retrieving transactions', 500, error.message)
  }
}

/**
 * @desc    Get single transaction with details
 * @route   GET /api/transactions/:id
 * @access  Private (Company users)
 */
exports.getTransactionById = async (req, res) => {
  try {
    const transaction = await Transaction.findOne({
      _id: req.params.id,
      ...req.companyFilter
    })
      .populate('customerId', 'name phone email address')
      .populate('createdBy', 'name')

    if (!transaction) {
      return errorResponse(res, 'Transaction not found', 404)
    }

    const data = {
      transaction,
      customer: transaction.customerId,
      paymentHistory: transaction.paymentHistory,
      paymentSummary: transaction.getPaymentSummary()
    }

    return successResponse(res, 'Transaction details retrieved successfully', data)
  } catch (error) {
    console.error('Get Transaction Error:', error)
    return errorResponse(res, 'Error retrieving transaction details', 500, error.message)
  }
}

/**
 * @desc    Get today's transactions summary
 * @route   GET /api/transactions/today
 * @access  Private (Company users)
 */
exports.getTodayTransactions = async (req, res) => {
  try {
    const today = new Date()
    today.setHours(0, 0, 0, 0)
    const tomorrow = new Date(today)
    tomorrow.setDate(tomorrow.getDate() + 1)

    const query = {
      ...req.companyFilter,
      transactionDate: { $gte: today, $lt: tomorrow }
    }

    // Get buy transactions
    const buyTransactions = await Transaction.find({
      ...query,
      type: 'buy'
    })
      .populate('customerId', 'name')
      .sort({ createdAt: -1 })
      .limit(10)

    // Get sell transactions
    const sellTransactions = await Transaction.find({
      ...query,
      type: 'sell'
    })
      .populate('customerId', 'name')
      .sort({ createdAt: -1 })
      .limit(10)

    // Calculate summary
    const summaryStats = await Transaction.aggregate([
      { $match: query },
      {
        $group: {
          _id: '$type',
          count: { $sum: 1 },
          totalAmount: { $sum: '$totalAmount' }
        }
      }
    ])

    const buyStats = summaryStats.find(s => s._id === 'buy') || { count: 0, totalAmount: 0 }
    const sellStats = summaryStats.find(s => s._id === 'sell') || { count: 0, totalAmount: 0 }

    const data = {
      buyTransactions,
      sellTransactions,
      summary: {
        totalBuyCount: buyStats.count,
        totalSellCount: sellStats.count,
        totalBuyAmount: buyStats.totalAmount,
        totalSellAmount: sellStats.totalAmount,
        netAmount: sellStats.totalAmount - buyStats.totalAmount
      }
    }

    return successResponse(res, 'Today\'s transactions retrieved successfully', data)
  } catch (error) {
    console.error('Get Today Transactions Error:', error)
    return errorResponse(res, 'Error retrieving today\'s transactions', 500, error.message)
  }
}

/**
 * @desc    Create buy transaction (purchase from farmer)
 * @route   POST /api/transactions/buy
 * @access  Private (Company users)
 */
exports.createBuyTransaction = async (req, res) => {
  const session = await mongoose.startSession()
  session.startTransaction()

  try {
    const errors = validationResult(req)
    if (!errors.isEmpty()) {
      return errorResponse(res, 'Validation failed', 400, errors.array())
    }

    const {
      id, // Unique ID from client
      customerId,
      items,
      paidAmount = 0,
      paymentMethod,
      notes,
      transactionDate,
      clientId
    } = req.body

    // Check for existing transaction to prevent duplicates
    const clientRef = id || clientId
    if (clientRef) {
      const existing = await Transaction.findOne({
        $or: [
          { clientId: clientRef },
          { id: clientRef }
        ],
        ...req.companyFilter
      }).session(session)

      if (existing) {
        await session.commitTransaction()
        return successResponse(res, 'Transaction already exists', { transaction: existing }, 200)
      }
    }

    // Verify customer belongs to company (try _id first, then clientId)
    let customer
    if (mongoose.Types.ObjectId.isValid(customerId)) {
      customer = await Customer.findOne({
        _id: customerId,
        ...req.companyFilter
      }).session(session)
    }

    if (!customer) {
      customer = await Customer.findOne({
        clientId: customerId,
        ...req.companyFilter
      }).session(session)
    }

    if (!customer) {
      return errorResponse(res, 'Customer not found (ID: ' + customerId + ')', 404)
    }

    // Use the resolved customer ID
    const resolvedCustomerId = customer._id

    // Process items and calculate totals
    let totalWeightKg = 0
    let totalBags = 0
    let totalAmount = 0
    const processedItems = []
    const stockUpdates = []

    for (const item of items) {
      const itemTotal = item.weightKg * item.pricePerKg
      totalWeightKg += item.weightKg
      totalBags += item.bags || 0
      totalAmount += itemTotal

      processedItems.push({
        itemName: item.name,
        itemType: item.itemType,
        weightKg: item.weightKg,
        bags: item.bags || 0,
        pricePerKg: item.pricePerKg,
        totalPrice: itemTotal
      })

      const name = item.name || item.itemName || item.variety || 'Unknown'
      const itemType = item.itemType || item.item_type || 'paddy'

      // Update or create stock item
      let stockItem = await StockItem.findOne({
        name,
        itemType,
        ...req.companyFilter
      }).session(session)

      if (stockItem) {
        // Update existing item
        const previousQuantity = stockItem.totalWeightKg

        // Update average purchase price BEFORE updating stock quantity
        await stockItem.updateAvgPurchasePrice(item.pricePerKg, item.weightKg)

        await stockItem.updateStock(item.weightKg, item.bags || 0, 'add')

        stockUpdates.push({
          itemId: stockItem._id,
          itemName: item.name,
          addedKg: item.weightKg,
          newTotalKg: stockItem.totalWeightKg
        })

        // Update item reference in processedItems
        const processedItem = processedItems[processedItems.length - 1]
        processedItem.stockItemId = stockItem._id
      } else {
        // Create new stock item
        stockItem = await StockItem.create([{
          name,
          itemType,
          totalWeightKg: item.weightKg,
          totalBags: item.bags || 0,
          pricePerKg: item.pricePerKg,
          companyId: req.companyId
        }], { session })

        stockUpdates.push({
          itemId: stockItem[0]._id,
          itemName: item.name,
          addedKg: item.weightKg,
          newTotalKg: item.weightKg
        })

        // Update item reference in processedItems
        const processedItem = processedItems[processedItems.length - 1]
        processedItem.stockItemId = stockItem[0]._id
      }
    }

    // Generate transaction number
    const transactionNumber = Transaction.generateTransactionNumber('buy', new Date(transactionDate))

    // Create transaction
    const transaction = await Transaction.create([{
      transactionNumber,
      type: 'buy',
      customerId: resolvedCustomerId,
      customerName: customer.name,
      items: processedItems,
      totalWeightKg,
      totalBags,
      totalAmount,
      paidAmount,
      balance: totalAmount - paidAmount,
      status: paidAmount >= totalAmount ? 'completed' : (paidAmount > 0 ? 'partially_paid' : 'pending'),
      paymentMethod,
      notes,
      companyId: req.companyId,
      createdBy: req.user.id,
      transactionDate: new Date(transactionDate),
      clientId
    }], { session })

    // Update customer totals
    await customer.updateBuyAmount(totalAmount)

    await session.commitTransaction()

    const data = {
      transaction: transaction[0],
      stockUpdates
    }

    return successResponse(res, 'Purchase transaction created successfully', data, 201)
  } catch (error) {
    await session.abortTransaction()
    console.error('Create Buy Transaction Error:', error)
    return errorResponse(res, 'Error creating purchase transaction', 500, error.message)
  } finally {
    session.endSession()
  }
}

/**
 * @desc    Create sell transaction (sale to buyer)
 * @route   POST /api/transactions/sell
 * @access  Private (Company users)
 */
exports.createSellTransaction = async (req, res) => {
  const session = await mongoose.startSession()
  session.startTransaction()

  try {
    const errors = validationResult(req)
    if (!errors.isEmpty()) {
      return errorResponse(res, 'Validation failed', 400, errors.array())
    }

    const {
      id, // Unique ID from client
      customerId,
      items,
      paidAmount = 0,
      paymentMethod,
      notes,
      transactionDate,
      clientId
    } = req.body

    // Check for existing transaction to prevent duplicates
    const clientRef = id || clientId
    if (clientRef) {
      const existing = await Transaction.findOne({
        $or: [
          { clientId: clientRef },
          { id: clientRef }
        ],
        ...req.companyFilter
      }).session(session)

      if (existing) {
        await session.commitTransaction()
        return successResponse(res, 'Transaction already exists', { transaction: existing }, 200)
      }
    }

    // Verify customer belongs to company (try _id first, then clientId)
    let customer
    if (mongoose.Types.ObjectId.isValid(customerId)) {
      customer = await Customer.findOne({
        _id: customerId,
        ...req.companyFilter
      }).session(session)
    }

    if (!customer) {
      customer = await Customer.findOne({
        clientId: customerId,
        ...req.companyFilter
      }).session(session)
    }

    if (!customer) {
      return errorResponse(res, 'Customer not found (ID: ' + customerId + ')', 404)
    }

    // Use the resolved customer ID
    const resolvedCustomerId = customer._id

    // Check stock availability for all items first
    const stockErrors = []
    for (const item of items) {
      if (!item.stockItemId) {
        stockErrors.push({
          item: item.itemName,
          error: 'Stock item ID is required for sales'
        })
        continue
      }

      const stockItem = await StockItem.findOne({
        _id: item.stockItemId,
        ...req.companyFilter
      }).session(session)

      if (!stockItem) {
        stockErrors.push({
          item: item.itemName,
          error: 'Stock item not found'
        })
      } else if (stockItem.totalWeightKg < item.weightKg) {
        stockErrors.push({
          item: item.itemName,
          requested: item.weightKg,
          available: stockItem.totalWeightKg,
          error: 'Insufficient stock'
        })
      }
    }

    if (stockErrors.length > 0) {
      return errorResponse(res, 'Stock validation failed', 400, stockErrors)
    }

    // Process items and calculate totals
    let totalWeightKg = 0
    let totalBags = 0
    let totalAmount = 0
    const processedItems = []
    const stockUpdates = []

    for (const item of items) {
      const stockItem = await StockItem.findById(item.stockItemId).session(session)
      const itemTotal = item.weightKg * item.pricePerKg
      totalWeightKg += item.weightKg
      totalBags += item.bags || 0
      totalAmount += itemTotal

      processedItems.push({
        stockItemId: item.stockItemId,
        itemName: stockItem.name,
        itemType: stockItem.itemType,
        weightKg: item.weightKg,
        bags: item.bags || 0,
        pricePerKg: item.pricePerKg,
        totalPrice: itemTotal
      })

      // Deduct from stock
      const previousQuantity = stockItem.totalWeightKg
      await stockItem.updateStock(item.weightKg, item.bags || 0, 'subtract')

      stockUpdates.push({
        itemId: stockItem._id,
        itemName: stockItem.name,
        deductedKg: item.weightKg,
        newTotalKg: stockItem.totalWeightKg
      })
    }

    // Generate transaction number
    const transactionNumber = Transaction.generateTransactionNumber('sell', new Date(transactionDate))

    // Create transaction
    const transaction = await Transaction.create([{
      transactionNumber,
      type: 'sell',
      customerId: resolvedCustomerId,
      customerName: customer.name,
      items: processedItems,
      totalWeightKg,
      totalBags,
      totalAmount,
      paidAmount,
      balance: totalAmount - paidAmount,
      status: paidAmount >= totalAmount ? 'completed' : (paidAmount > 0 ? 'partially_paid' : 'pending'),
      paymentMethod,
      notes,
      companyId: req.companyId,
      createdBy: req.user.id,
      transactionDate: new Date(transactionDate),
      clientId
    }], { session })

    // Update customer totals
    await customer.updateSellAmount(totalAmount)

    await session.commitTransaction()

    const data = {
      transaction: transaction[0],
      stockUpdates
    }

    return successResponse(res, 'Sales transaction created successfully', data, 201)
  } catch (error) {
    await session.abortTransaction()
    console.error('Create Sell Transaction Error:', error)
    return errorResponse(res, 'Error creating sales transaction', 500, error.message)
  } finally {
    session.endSession()
  }
}

/**
 * @desc    Update transaction (limited fields)
 * @route   PUT /api/transactions/:id
 * @access  Private (Company users)
 */
exports.updateTransaction = async (req, res) => {
  try {
    const errors = validationResult(req)
    if (!errors.isEmpty()) {
      return errorResponse(res, 'Validation failed', 400, errors.array())
    }

    const { notes, status } = req.body
    const allowedUpdates = ['notes']

    // Only allow status update for cancellation
    if (status === 'cancelled') {
      allowedUpdates.push('status')
    }

    const updates = {}
    allowedUpdates.forEach(field => {
      if (req.body[field] !== undefined) {
        updates[field] = req.body[field]
      }
    })

    const transaction = await Transaction.findOneAndUpdate(
      { _id: req.params.id, ...req.companyFilter },
      updates,
      { new: true, runValidators: true }
    )

    if (!transaction) {
      return errorResponse(res, 'Transaction not found', 404)
    }

    // If cancelling transaction, reverse stock changes
    if (status === 'cancelled' && transaction.status !== 'cancelled') {
      await reverseStockChanges(transaction, req.companyId)
    }

    return successResponse(res, 'Transaction updated successfully', { transaction })
  } catch (error) {
    console.error('Update Transaction Error:', error)
    return errorResponse(res, 'Error updating transaction', 500, error.message)
  }
}

/**
 * @desc    Add payment to transaction
 * @route   POST /api/transactions/:id/payment
 * @access  Private (Company users)
 */
exports.addPayment = async (req, res) => {
  try {
    const errors = validationResult(req)
    if (!errors.isEmpty()) {
      return errorResponse(res, 'Validation failed', 400, errors.array())
    }

    const { amount, paymentMethod, notes } = req.body

    const transaction = await Transaction.findOne({
      _id: req.params.id,
      ...req.companyFilter
    })

    if (!transaction) {
      return errorResponse(res, 'Transaction not found', 404)
    }

    const previousBalance = transaction.balance

    // Add payment
    await transaction.addPayment({
      amount,
      paymentMethod,
      receivedBy: req.user.id,
      notes
    })

    const data = {
      transaction,
      payment: {
        amount,
        previousBalance,
        newBalance: transaction.balance
      },
      paymentSummary: transaction.getPaymentSummary()
    }

    return successResponse(res, 'Payment recorded successfully', data)
  } catch (error) {
    console.error('Add Payment Error:', error)
    return errorResponse(res, 'Error recording payment', 500, error.message)
  }
}

/**
 * @desc    Get receipt data for PDF generation
 * @route   GET /api/transactions/:id/receipt
 * @access  Private (Company users)
 */
exports.getReceipt = async (req, res) => {
  try {
    const transaction = await Transaction.findOne({
      _id: req.params.id,
      ...req.companyFilter
    })
      .populate('customerId', 'name phone address')
      .populate('createdBy', 'name')

    if (!transaction) {
      return errorResponse(res, 'Transaction not found', 404)
    }

    // Get company details
    const company = await require('../models/Company').findById(req.companyId)

    const data = {
      transaction,
      company: {
        name: company.name,
        address: company.address,
        phone: company.phone,
        email: company.email
      },
      customer: transaction.customerId,
      items: transaction.items,
      paymentHistory: transaction.paymentHistory,
      receiptNumber: `REC-${transaction.transactionNumber}`,
      generatedAt: new Date()
    }

    return successResponse(res, 'Receipt data retrieved successfully', data)
  } catch (error) {
    console.error('Get Receipt Error:', error)
    return errorResponse(res, 'Error retrieving receipt data', 500, error.message)
  }
}

/**
 * Helper function to reverse stock changes when cancelling transaction
 */
async function reverseStockChanges (transaction, companyId) {
  try {
    for (const item of transaction.items) {
      const stockItem = await StockItem.findById(item.stockItemId)

      if (stockItem && stockItem.companyId.toString() === companyId.toString()) {
        // Reverse the operation
        if (transaction.type === 'buy') {
          // Remove from stock (reverse purchase)
          await stockItem.updateStock(item.weightKg, item.bags || 0, 'subtract')
        } else if (transaction.type === 'sell') {
          // Add back to stock (reverse sale)
          await stockItem.updateStock(item.weightKg, item.bags || 0, 'add')
        }
      }
    }

    // Reverse customer amounts
    const customer = await Customer.findById(transaction.customerId)
    if (customer && customer.companyId.toString() === companyId.toString()) {
      if (transaction.type === 'buy') {
        await customer.updateBuyAmount(-transaction.totalAmount)
      } else if (transaction.type === 'sell') {
        await customer.updateSellAmount(-transaction.totalAmount)
      }
    }
  } catch (error) {
    console.error('Error reversing stock changes:', error)
    throw error
  }
}

/**
 * @desc    Sync transactions from local database
 * @route   POST /api/transactions/sync
 * @access  Private (Company users)
 */
exports.syncTransactions = async (req, res) => {
  const session = await mongoose.startSession()
  session.startTransaction()

  try {
    const { transactions } = req.body

    if (!transactions || !Array.isArray(transactions)) {
      return errorResponse(res, 'Invalid data format', 400)
    }

    const synced = []
    const errors = []

    for (const txnData of transactions) {
      try {
        // Check if transaction already exists
        const existing = await Transaction.findOne({
          transactionNumber: txnData.transaction_number,
          companyId: req.companyId
        }).session(session)

        if (existing) {
          synced.push(existing)
          continue
        }

        // Verify customer
        const customer = await Customer.findOne({
          _id: txnData.customer_id,
          companyId: req.companyId
        }).session(session)

        if (!customer) {
          // Try to find by name if ID mismatch (e.g. local ID vs server ID issue)
          // Or just log error.
          // For now, if no customer, we can't link it strictly.
          // But usually customer sync runs before transaction sync.
          errors.push({ transaction: txnData.transaction_number, error: 'Customer not found' })
          continue
        }

        // Prepare items
        const processedItems = []
        for (const item of txnData.items) {
          // Try to map stock item
          let stockItem = await StockItem.findOne({
            _id: item.stock_item_id,
            companyId: req.companyId
          }).session(session)

          if (!stockItem) {
            stockItem = await StockItem.findOne({
              name: item.variety || item.name || item.item_name,
              itemType: item.item_type,
              companyId: req.companyId
            }).session(session)
          }

          if (stockItem) {
            // Update stock impacts
            if (txnData.type === 'buy') {
              await stockItem.updateAvgPurchasePrice(item.price_per_kg || item.price || 0, item.weight_kg || item.quantity || 0)
              await stockItem.updateStock(item.weight_kg || item.quantity, item.bags || 0, 'add')
            } else {
              await stockItem.updateStock(item.weight_kg || item.quantity, item.bags || 0, 'subtract')
            }
          } else if (txnData.type === 'buy') {
            // Create new stock item if it doesn't exist
            const newStockItem = await StockItem.create([{
              name: item.variety || item.name || item.item_name || 'Unknown',
              itemType: item.item_type || 'paddy',
              totalWeightKg: item.weight_kg || item.quantity,
              totalBags: item.bags || 0,
              pricePerKg: item.price_per_kg || item.price || 0,
              avgPurchasePrice: item.price_per_kg || item.price || 0,
              companyId: req.companyId
            }], { session })
            stockItem = newStockItem[0]
          }

          processedItems.push({
            stockItemId: stockItem ? stockItem._id : null,
            itemName: item.variety || item.name || item.item_name || 'Unknown',
            itemType: item.item_type,
            weightKg: item.weight_kg || item.quantity,
            bags: item.bags || 0,
            pricePerKg: item.price_per_kg || item.price,
            totalPrice: item.total_amount || item.totalPrice
          })
        }

        // Create Transaction
        const newTransaction = await Transaction.create([{
          transactionNumber: txnData.transaction_number,
          type: txnData.type,
          customerId: customer._id,
          customerName: customer.name,
          items: processedItems,
          totalWeightKg: txnData.subtotal || txnData.total_weight_kg,
          totalBags: processedItems.reduce((sum, i) => sum + (i.bags || 0), 0),
          totalAmount: txnData.total_amount,
          paidAmount: txnData.paid_amount,
          balance: (txnData.total_amount || 0) - (txnData.paid_amount || 0),
          status: txnData.status || ((txnData.paid_amount || 0) >= (txnData.total_amount || 0) ? 'completed' : 'pending'),
          paymentMethod: txnData.payment_method || 'cash',
          notes: txnData.notes,
          companyId: req.companyId,
          createdBy: req.user.id,
          transactionDate: new Date(txnData.transaction_date),
          isSynced: true
        }], { session })

        // Update customer balance/totals
        if (txnData.type === 'buy') {
          await customer.updateBuyAmount(txnData.total_amount)
        } else {
          await customer.updateSellAmount(txnData.total_amount)
        }

        synced.push(newTransaction[0])
      } catch (err) {
        console.error(`Failed to sync transaction ${txnData.transaction_number}:`, err)
        errors.push({ transaction: txnData.transaction_number, error: err.message })
      }
    }

    await session.commitTransaction()

    return successResponse(res, 'Sync completed', { synced, errors })
  } catch (error) {
    await session.abortTransaction()
    console.error('Sync Transactions Error:', error)
    return errorResponse(res, 'Error syncing transactions', 500, error.message)
  } finally {
    session.endSession()
  }
}
