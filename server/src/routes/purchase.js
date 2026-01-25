const express = require('express')
const router = express.Router()
const Purchase = require('../models/Purchase')

// Import middleware
const auth = require('../middleware/auth')
const companyGuard = require('../middleware/companyGuard')
const { validateObjectId } = require('../middleware/validator')
const { body } = require('express-validator')

// Validation rules
const createPurchaseValidation = [
  body('customerId')
    .notEmpty().withMessage('Customer ID is required')
    .isMongoId().withMessage('Invalid customer ID'),
  body('paddyTypeId')
    .notEmpty().withMessage('Paddy type ID is required')
    .isMongoId().withMessage('Invalid paddy type ID'),
  body('numberOfBags')
    .notEmpty().withMessage('Number of bags is required')
    .isInt({ min: 1 }).withMessage('Number of bags must be at least 1'),
  body('totalWeight')
    .notEmpty().withMessage('Total weight is required')
    .isFloat({ min: 0.1 }).withMessage('Total weight must be greater than 0'),
  body('pricePerKg')
    .notEmpty().withMessage('Price per kg is required')
    .isFloat({ min: 0 }).withMessage('Price must be a positive number'),
  body('paidAmount')
    .optional()
    .isFloat({ min: 0 }).withMessage('Paid amount must be a positive number'),
  body('paymentMethod')
    .optional()
    .isIn(['cash', 'bank_transfer', 'cheque', 'credit']).withMessage('Invalid payment method'),
  body('purchaseDate')
    .notEmpty().withMessage('Purchase date is required')
    .isISO8601().withMessage('Invalid date format'),
  body('notes')
    .optional()
    .trim()
    .isLength({ max: 500 }).withMessage('Notes cannot exceed 500 characters')
]

const updatePurchaseValidation = [
  body('numberOfBags')
    .optional()
    .isInt({ min: 1 }).withMessage('Number of bags must be at least 1'),
  body('totalWeight')
    .optional()
    .isFloat({ min: 0.1 }).withMessage('Total weight must be greater than 0'),
  body('pricePerKg')
    .optional()
    .isFloat({ min: 0 }).withMessage('Price must be a positive number'),
  body('paidAmount')
    .optional()
    .isFloat({ min: 0 }).withMessage('Paid amount must be a positive number'),
  body('paymentMethod')
    .optional()
    .isIn(['cash', 'bank_transfer', 'cheque', 'credit']).withMessage('Invalid payment method'),
  body('notes')
    .optional()
    .trim()
    .isLength({ max: 500 }).withMessage('Notes cannot exceed 500 characters')
]

/**
 * All routes require authentication and company isolation
 */
router.use(auth)
router.use(companyGuard)

/**
 * @route   GET /api/purchases
 * @desc    Get all purchases with filtering and pagination
 * @access  Private (Company users)
 */
router.get('/', async (req, res) => {
  try {
    const {
      status,
      customerId,
      paddyTypeId,
      startDate,
      endDate,
      page = 1,
      limit = 20,
      sortBy = 'purchaseDate',
      sortOrder = 'desc'
    } = req.query

    // Build query with company filter
    const query = { ...req.companyFilter }

    if (status) query.status = status
    if (customerId) query.customerId = customerId
    if (paddyTypeId) query.paddyTypeId = paddyTypeId

    if (startDate || endDate) {
      query.purchaseDate = {}
      if (startDate) query.purchaseDate.$gte = new Date(startDate)
      if (endDate) query.purchaseDate.$lte = new Date(endDate)
    }

    // Build sort
    const sort = {}
    sort[sortBy] = sortOrder === 'desc' ? -1 : 1

    // Get purchases with population
    const purchases = await Purchase.find(query)
      .populate('customerId', 'name phone')
      .populate('paddyTypeId', 'name qualityGrade')
      .populate('createdBy', 'name')
      .sort(sort)
      .limit(limit * 1)
      .skip((page - 1) * limit)

    // Calculate summary
    const summaryStats = await Purchase.aggregate([
      { $match: query },
      {
        $group: {
          _id: '$status',
          count: { $sum: 1 },
          totalAmount: { $sum: '$totalPrice' },
          totalPaid: { $sum: '$paidAmount' },
          totalBalance: { $sum: '$balance' }
        }
      }
    ])

    const pendingStats = summaryStats.find(s => s._id === 'pending') || {}
    const partiallyPaidStats = summaryStats.find(s => s._id === 'partially_paid') || {}
    const completedStats = summaryStats.find(s => s._id === 'completed') || {}

    const total = await Purchase.countDocuments(query)
    const pages = Math.ceil(total / limit)

    const data = {
      purchases: purchases.map(p => p.getDetailedInfo()),
      summary: {
        totalPurchases: total,
        pendingPurchases: pendingStats.count || 0,
        pendingAmount: pendingStats.totalBalance || 0,
        completedPurchases: completedStats.count || 0,
        totalPurchaseAmount: purchases.reduce((sum, p) => sum + p.totalPrice, 0),
        totalPaidAmount: purchases.reduce((sum, p) => sum + p.paidAmount, 0),
        totalBalance: purchases.reduce((sum, p) => sum + p.balance, 0)
      },
      pagination: {
        total,
        page: parseInt(page),
        limit: parseInt(limit),
        pages
      }
    }

    res.json({
      success: true,
      data
    })
  } catch (error) {
    console.error('Get Purchases Error:', error)
    res.status(500).json({
      success: false,
      message: 'Error retrieving purchases',
      error: error.message
    })
  }
})

/**
 * @route   GET /api/purchases/:id
 * @desc    Get purchase by ID
 * @access  Private (Company users)
 */
router.get('/:id', validateObjectId('id'), async (req, res) => {
  try {
    const purchase = await Purchase.findOne({
      _id: req.params.id,
      ...req.companyFilter
    })
      .populate('customerId', 'name phone email address')
      .populate('paddyTypeId', 'name description qualityGrade averageYieldPercentage')
      .populate('createdBy', 'name email')

    if (!purchase) {
      return res.status(404).json({
        success: false,
        message: 'Purchase not found'
      })
    }

    res.json({
      success: true,
      data: {
        purchase: purchase.getDetailedInfo()
      }
    })
  } catch (error) {
    console.error('Get Purchase Error:', error)
    res.status(500).json({
      success: false,
      message: 'Error retrieving purchase',
      error: error.message
    })
  }
})

/**
 * @route   GET /api/purchases/statistics/summary
 * @desc    Get purchase statistics
 * @access  Private (Company users)
 */
router.get('/statistics/summary', async (req, res) => {
  try {
    const { startDate, endDate } = req.query

    const summary = await Purchase.getPurchaseSummary(req.companyId, startDate, endDate)

    // Get top customers by purchase amount
    const topCustomers = await Purchase.aggregate([
      {
        $match: {
          ...req.companyFilter,
          ...(startDate || endDate
            ? {
                purchaseDate: {
                  ...(startDate && { $gte: new Date(startDate) }),
                  ...(endDate && { $lte: new Date(endDate) })
                }
              }
            : {})
        }
      },
      {
        $group: {
          _id: '$customerId',
          totalPurchases: { $sum: 1 },
          totalAmount: { $sum: '$totalPrice' },
          totalWeight: { $sum: '$totalWeight' }
        }
      },
      { $sort: { totalAmount: -1 } },
      { $limit: 10 },
      {
        $lookup: {
          from: 'customers',
          localField: '_id',
          foreignField: '_id',
          as: 'customer'
        }
      },
      { $unwind: '$customer' },
      {
        $project: {
          name: '$customer.name',
          phone: '$customer.phone',
          totalPurchases: 1,
          totalAmount: 1,
          totalWeight: 1
        }
      }
    ])

    // Get top paddy types
    const topPaddyTypes = await Purchase.aggregate([
      {
        $match: {
          ...req.companyFilter,
          ...(startDate || endDate
            ? {
                purchaseDate: {
                  ...(startDate && { $gte: new Date(startDate) }),
                  ...(endDate && { $lte: new Date(endDate) })
                }
              }
            : {})
        }
      },
      {
        $group: {
          _id: '$paddyTypeId',
          totalPurchases: { $sum: 1 },
          totalAmount: { $sum: '$totalPrice' },
          totalWeight: { $sum: '$totalWeight' }
        }
      },
      { $sort: { totalAmount: -1 } },
      { $limit: 5 },
      {
        $lookup: {
          from: 'paddytypes',
          localField: '_id',
          foreignField: '_id',
          as: 'paddyType'
        }
      },
      { $unwind: '$paddyType' },
      {
        $project: {
          name: '$paddyType.name',
          qualityGrade: '$paddyType.qualityGrade',
          totalPurchases: 1,
          totalAmount: 1,
          totalWeight: 1
        }
      }
    ])

    const data = {
      summary: {
        totalPurchases: summary.totalPurchases || 0,
        totalWeight: summary.totalWeight || 0,
        totalAmount: summary.totalAmount || 0,
        totalPaid: summary.totalPaid || 0,
        totalBalance: summary.totalBalance || 0
      },
      topCustomers,
      topPaddyTypes,
      period: startDate && endDate ? `${startDate} to ${endDate}` : 'All time'
    }

    res.json({
      success: true,
      data
    })
  } catch (error) {
    console.error('Get Purchase Statistics Error:', error)
    res.status(500).json({
      success: false,
      message: 'Error retrieving purchase statistics',
      error: error.message
    })
  }
})

/**
 * @route   POST /api/purchases
 * @desc    Create new purchase
 * @access  Private (Company users)
 */
router.post('/', createPurchaseValidation, async (req, res) => {
  try {
    const {
      customerId,
      paddyTypeId,
      numberOfBags,
      totalWeight,
      pricePerKg,
      paidAmount = 0,
      paymentMethod = 'cash',
      purchaseDate,
      notes,
      clientId
    } = req.body

    // Verify customer belongs to company
    const Customer = require('../models/Customer')
    const customer = await Customer.findOne({
      _id: customerId,
      ...req.companyFilter
    })

    if (!customer) {
      return res.status(404).json({
        success: false,
        message: 'Customer not found'
      })
    }

    // Verify paddy type belongs to company
    const PaddyType = require('../models/PaddyType')
    const paddyType = await PaddyType.findOne({
      _id: paddyTypeId,
      ...req.companyFilter
    })

    if (!paddyType) {
      return res.status(404).json({
        success: false,
        message: 'Paddy type not found'
      })
    }

    // Create purchase
    const purchase = await Purchase.create({
      customerId,
      paddyTypeId,
      numberOfBags,
      totalWeight,
      pricePerKg,
      paidAmount,
      paymentMethod,
      purchaseDate: new Date(purchaseDate),
      notes,
      companyId: req.companyId,
      createdBy: req.user.id,
      clientId
    })

    res.status(201).json({
      success: true,
      message: 'Purchase created successfully',
      data: {
        purchase: purchase.getDetailedInfo()
      }
    })
  } catch (error) {
    console.error('Create Purchase Error:', error)

    // Handle duplicate key errors
    if (error.code === 11000) {
      return res.status(409).json({
        success: false,
        message: 'Purchase with duplicate data already exists'
      })
    }

    res.status(500).json({
      success: false,
      message: 'Error creating purchase',
      error: error.message
    })
  }
})

/**
 * @route   PUT /api/purchases/:id
 * @desc    Update purchase
 * @access  Private (Company users)
 */
router.put('/:id', validateObjectId('id'), updatePurchaseValidation, async (req, res) => {
  try {
    const updates = {}
    const allowedFields = [
      'numberOfBags', 'totalWeight', 'pricePerKg',
      'paidAmount', 'paymentMethod', 'notes'
    ]

    allowedFields.forEach(field => {
      if (req.body[field] !== undefined) {
        updates[field] = req.body[field]
      }
    })

    const purchase = await Purchase.findOneAndUpdate(
      { _id: req.params.id, ...req.companyFilter },
      updates,
      { new: true, runValidators: true }
    )

    if (!purchase) {
      return res.status(404).json({
        success: false,
        message: 'Purchase not found'
      })
    }

    res.json({
      success: true,
      message: 'Purchase updated successfully',
      data: {
        purchase: purchase.getDetailedInfo()
      }
    })
  } catch (error) {
    console.error('Update Purchase Error:', error)
    res.status(500).json({
      success: false,
      message: 'Error updating purchase',
      error: error.message
    })
  }
})

/**
 * @route   POST /api/purchases/:id/payment
 * @desc    Add payment to purchase
 * @access  Private (Company users)
 */
router.post('/:id/payment', validateObjectId('id'), [
  body('amount')
    .notEmpty().withMessage('Payment amount is required')
    .isFloat({ min: 0.01 }).withMessage('Payment amount must be greater than 0'),
  body('paymentMethod')
    .optional()
    .isIn(['cash', 'bank_transfer', 'cheque', 'credit']).withMessage('Invalid payment method'),
  body('notes')
    .optional()
    .trim()
    .isLength({ max: 200 }).withMessage('Payment notes cannot exceed 200 characters')
], async (req, res) => {
  try {
    const { amount, paymentMethod, notes } = req.body

    const purchase = await Purchase.findOne({
      _id: req.params.id,
      ...req.companyFilter
    })

    if (!purchase) {
      return res.status(404).json({
        success: false,
        message: 'Purchase not found'
      })
    }

    await purchase.addPayment({
      amount,
      paymentMethod: paymentMethod || purchase.paymentMethod,
      notes
    })

    res.json({
      success: true,
      message: 'Payment recorded successfully',
      data: {
        purchase: purchase.getDetailedInfo()
      }
    })
  } catch (error) {
    console.error('Add Payment Error:', error)
    res.status(500).json({
      success: false,
      message: 'Error recording payment',
      error: error.message
    })
  }
})

/**
 * @route   DELETE /api/purchases/:id
 * @desc    Cancel purchase
 * @access  Private (Company users)
 */
router.delete('/:id', validateObjectId('id'), async (req, res) => {
  try {
    const purchase = await Purchase.findOne({
      _id: req.params.id,
      ...req.companyFilter
    })

    if (!purchase) {
      return res.status(404).json({
        success: false,
        message: 'Purchase not found'
      })
    }

    // Only allow cancellation if not completed
    if (purchase.status === 'completed') {
      return res.status(400).json({
        success: false,
        message: 'Cannot cancel a completed purchase'
      })
    }

    await purchase.cancelPurchase()

    res.json({
      success: true,
      message: 'Purchase cancelled successfully'
    })
  } catch (error) {
    console.error('Cancel Purchase Error:', error)
    res.status(500).json({
      success: false,
      message: 'Error cancelling purchase',
      error: error.message
    })
  }
})

module.exports = router
