const express = require('express')
const router = express.Router()
const auth = require('../middleware/auth')
const companyGuard = require('../middleware/companyGuard')
const { validationResult } = require('express-validator')
const { errorResponse, successResponse } = require('../utils/responseHandler')

// Import models
const Transaction = require('../models/Transaction')
const Customer = require('../models/Customer')
const StockItem = require('../models/StockItem')

// Import validators (to be implemented)
const {
  validateTransactionCreation,
  validateTransactionUpdate,
  validatePayment
} = require('../validators/transactionValidator')

// Import controller
const {
  getTransactions,
  getTransactionById,
  getTodayTransactions,
  createBuyTransaction,
  createSellTransaction,
  updateTransaction,
  addPayment,
  getReceipt,
  syncTransactions
} = require('../controllers/transactionController')

// Apply authentication and company isolation to all routes
router.use(auth)
router.use(companyGuard)

/**
 * @route   POST /api/transactions/sync
 * @desc    Sync transactions from local database
 * @access  Private (Company users)
 */
router.post('/sync', syncTransactions)

/**
 * @route   GET /api/transactions/today
 * @desc    Get today's transactions summary
 * @access  Private (Company users)
 */
router.get('/today', getTodayTransactions)

/**
 * @route   GET /api/transactions/date-range
 * @desc    Get transactions by date range
 * @access  Private (Company users)
 */
router.get('/date-range', getTransactions)

/**
 * @route   GET /api/transactions/:id/receipt
 * @desc    Get receipt data for PDF generation
 * @access  Private (Company users)
 */
router.get('/:id/receipt', getReceipt)

/**
 * @route   GET /api/transactions/:id
 * @desc    Get single transaction details
 * @access  Private (Company users)
 */
router.get('/:id', getTransactionById)

/**
 * @route   GET /api/transactions
 * @desc    Get all transactions with filtering and pagination
 * @access  Private (Company users)
 */
router.get('/', getTransactions)

/**
 * @route   POST /api/transactions
 * @desc    Create a transaction (Buy or Sell)
 * @access  Private (Company users)
 */
router.post('/', validateTransactionCreation, (req, res, next) => {
  const { type } = req.body
  if (type === 'sell') {
    return createSellTransaction(req, res, next)
  }
  return createBuyTransaction(req, res, next)
})

/**
 * @route   PUT /api/transactions/:id
 * @desc    Update transaction (limited fields)
 * @access  Private (Company users)
 */
router.put('/:id', validateTransactionUpdate, async (req, res) => {
  try {
    const errors = validationResult(req)
    if (!errors.isEmpty()) {
      return errorResponse(res, 'Validation failed', 400, errors.array())
    }

    const { notes, status } = req.body

    const transaction = await Transaction.findOne({
      _id: req.params.id,
      ...req.companyFilter
    })

    if (!transaction) {
      return errorResponse(res, 'Transaction not found', 404)
    }

    // Handle status change to cancelled
    if (status === 'cancelled' && transaction.status !== 'cancelled') {
      // TODO: Reverse stock changes
      // For buy transactions: deduct from stock
      // For sell transactions: add back to stock
    }

    const updates = {}
    if (notes !== undefined) updates.notes = notes
    if (status !== undefined) updates.status = status

    const updatedTransaction = await Transaction.findByIdAndUpdate(
      req.params.id,
      updates,
      { new: true }
    )

    return successResponse(res, 'Transaction updated successfully', { transaction: updatedTransaction })
  } catch (error) {
    console.error('Update Transaction Error:', error)
    return errorResponse(res, 'Error updating transaction', 500, error.message)
  }
})

/**
 * @route   POST /api/transactions/:id/payment
 * @desc    Add payment to transaction
 * @access  Private (Company users)
 */
router.post('/:id/payment', validatePayment, async (req, res) => {
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
      }
    }

    return successResponse(res, 'Payment recorded successfully', data)
  } catch (error) {
    console.error('Add Payment Error:', error)
    return errorResponse(res, 'Error recording payment', 500, error.message)
  }
})

/**
 * @route   GET /api/transactions/:id/receipt
 * @desc    Get receipt data for PDF generation
 * @access  Private (Company users)
 */
router.get('/:id/receipt', async (req, res) => {
  try {
    const transaction = await Transaction.findOne({
      _id: req.params.id,
      ...req.companyFilter
    }).populate('customerId', 'name phone address')

    if (!transaction) {
      return errorResponse(res, 'Transaction not found', 404)
    }

    // Get company details
    const Company = require('../models/Company')
    const company = await Company.findById(req.companyId)

    const data = {
      transaction,
      company,
      customer: transaction.customerId,
      items: transaction.items,
      receiptNumber: `REC-${transaction.transactionNumber}`
    }

    return successResponse(res, 'Receipt data retrieved successfully', data)
  } catch (error) {
    console.error('Get Receipt Error:', error)
    return errorResponse(res, 'Error retrieving receipt data', 500, error.message)
  }
})

module.exports = router
