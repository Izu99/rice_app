const Purchase = require('../models/Purchase')
const Customer = require('../models/Customer')
const PaddyType = require('../models/PaddyType')
const { validationResult } = require('express-validator')
const { errorResponse, successResponse } = require('../utils/responseHandler')

/**
 * @desc    Create a new purchase
 * @route   POST /api/purchases
 * @access  Private
 */
exports.createPurchase = async (req, res) => {
  try {
    const errors = validationResult(req)
    if (!errors.isEmpty()) {
      return errorResponse(res, 'Validation failed', 400, errors.array())
    }

    const { customerId, paddyTypeId, numberOfBags, totalWeight, pricePerKg, notes } = req.body

    // Verify customer belongs to user
    const customer = await Customer.findOne({
      _id: customerId,
      userId: req.user.id
    })

    if (!customer) {
      return errorResponse(res, 'Customer not found', 404)
    }

    // Verify paddy type belongs to user
    const paddyType = await PaddyType.findOne({
      _id: paddyTypeId,
      userId: req.user.id,
      isActive: true
    })

    if (!paddyType) {
      return errorResponse(res, 'Paddy type not found or inactive', 404)
    }

    // Create purchase with price from request
    const purchase = await Purchase.create({
      customerId,
      paddyTypeId,
      numberOfBags,
      totalWeight,
      pricePerKg,
      notes,
      userId: req.user.id
    })

    // Populate customer and paddy type details
    await purchase.populate('customerId', 'name phoneNumber')
    await purchase.populate('paddyTypeId', 'name pricePerKg')

    return successResponse(res, 'Purchase created successfully', {
      purchase: purchase.getDetailedInfo()
    }, 201)
  } catch (error) {
    console.error('Create Purchase Error:', error)
    return errorResponse(res, 'Error creating purchase', 500, error.message)
  }
}

/**
 * @desc    Get all purchases
 * @route   GET /api/purchases
 * @access  Private
 */
exports.getPurchases = async (req, res) => {
  try {
    const { customerId, paddyTypeId, startDate, endDate, page = 1, limit = 50 } = req.query

    // Build query
    const query = { userId: req.user.id }

    if (customerId) {
      query.customerId = customerId
    }

    if (paddyTypeId) {
      query.paddyTypeId = paddyTypeId
    }

    if (startDate || endDate) {
      query.purchaseDate = {}
      if (startDate) query.purchaseDate.$gte = new Date(startDate)
      if (endDate) query.purchaseDate.$lte = new Date(endDate)
    }

    const skip = (page - 1) * limit

    const purchases = await Purchase.find(query)
      .populate('customerId', 'name phoneNumber')
      .populate('paddyTypeId', 'name pricePerKg')
      .sort({ purchaseDate: -1 })
      .skip(skip)
      .limit(parseInt(limit))

    const total = await Purchase.countDocuments(query)

    return successResponse(res, 'Purchases retrieved successfully', {
      purchases: purchases.map(p => p.getDetailedInfo()),
      pagination: {
        total,
        page: parseInt(page),
        limit: parseInt(limit),
        pages: Math.ceil(total / limit)
      }
    })
  } catch (error) {
    console.error('Get Purchases Error:', error)
    return errorResponse(res, 'Error retrieving purchases', 500, error.message)
  }
}

/**
 * @desc    Get purchase by ID
 * @route   GET /api/purchases/:id
 * @access  Private
 */
exports.getPurchaseById = async (req, res) => {
  try {
    const purchase = await Purchase.findOne({
      _id: req.params.id,
      userId: req.user.id
    })
      .populate('customerId', 'name phoneNumber address')
      .populate('paddyTypeId', 'name description pricePerKg')

    if (!purchase) {
      return errorResponse(res, 'Purchase not found', 404)
    }

    return successResponse(res, 'Purchase retrieved successfully', {
      purchase: purchase.getDetailedInfo()
    })
  } catch (error) {
    console.error('Get Purchase Error:', error)
    return errorResponse(res, 'Error retrieving purchase', 500, error.message)
  }
}

/**
 * @desc    Update purchase
 * @route   PUT /api/purchases/:id
 * @access  Private
 */
exports.updatePurchase = async (req, res) => {
  try {
    const errors = validationResult(req)
    if (!errors.isEmpty()) {
      return errorResponse(res, 'Validation failed', 400, errors.array())
    }

    const allowedUpdates = ['numberOfBags', 'totalWeight', 'notes']
    const updates = {}

    allowedUpdates.forEach(field => {
      if (req.body[field] !== undefined) {
        updates[field] = req.body[field]
      }
    })

    const purchase = await Purchase.findOneAndUpdate(
      { _id: req.params.id, userId: req.user.id },
      updates,
      { new: true, runValidators: true }
    )
      .populate('customerId', 'name phoneNumber')
      .populate('paddyTypeId', 'name pricePerKg')

    if (!purchase) {
      return errorResponse(res, 'Purchase not found', 404)
    }

    return successResponse(res, 'Purchase updated successfully', {
      purchase: purchase.getDetailedInfo()
    })
  } catch (error) {
    console.error('Update Purchase Error:', error)
    return errorResponse(res, 'Error updating purchase', 500, error.message)
  }
}

/**
 * @desc    Delete purchase
 * @route   DELETE /api/purchases/:id
 * @access  Private
 */
exports.deletePurchase = async (req, res) => {
  try {
    const purchase = await Purchase.findOneAndDelete({
      _id: req.params.id,
      userId: req.user.id
    })

    if (!purchase) {
      return errorResponse(res, 'Purchase not found', 404)
    }

    return successResponse(res, 'Purchase deleted successfully')
  } catch (error) {
    console.error('Delete Purchase Error:', error)
    return errorResponse(res, 'Error deleting purchase', 500, error.message)
  }
}

/**
 * @desc    Get purchase summary/statistics
 * @route   GET /api/purchases/summary
 * @access  Private
 */
exports.getPurchaseSummary = async (req, res) => {
  try {
    const { startDate, endDate } = req.query

    // Build match query
    const matchQuery = { userId: req.user.id }

    if (startDate || endDate) {
      matchQuery.purchaseDate = {}
      if (startDate) matchQuery.purchaseDate.$gte = new Date(startDate)
      if (endDate) matchQuery.purchaseDate.$lte = new Date(endDate)
    }

    // Aggregate by paddy type
    const summaryByPaddyType = await Purchase.aggregate([
      { $match: matchQuery },
      {
        $group: {
          _id: '$paddyTypeId',
          totalWeight: { $sum: '$totalWeight' },
          totalPrice: { $sum: '$totalPrice' },
          totalBags: { $sum: '$numberOfBags' },
          purchaseCount: { $sum: 1 }
        }
      },
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
          paddyTypeName: '$paddyType.name',
          totalWeight: 1,
          totalPrice: 1,
          totalBags: 1,
          purchaseCount: 1
        }
      }
    ])

    // Overall summary
    const overallSummary = await Purchase.aggregate([
      { $match: matchQuery },
      {
        $group: {
          _id: null,
          totalPurchases: { $sum: 1 },
          totalWeight: { $sum: '$totalWeight' },
          totalAmount: { $sum: '$totalPrice' },
          totalBags: { $sum: '$numberOfBags' }
        }
      }
    ])

    return successResponse(res, 'Purchase summary retrieved successfully', {
      overall: overallSummary[0] || {
        totalPurchases: 0,
        totalWeight: 0,
        totalAmount: 0,
        totalBags: 0
      },
      byPaddyType: summaryByPaddyType
    })
  } catch (error) {
    console.error('Get Purchase Summary Error:', error)
    return errorResponse(res, 'Error retrieving purchase summary', 500, error.message)
  }
}
