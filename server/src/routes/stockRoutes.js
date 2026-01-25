const express = require('express')
const router = express.Router()
const auth = require('../middleware/auth')
const companyGuard = require('../middleware/companyGuard')
const { validationResult } = require('express-validator')
const { errorResponse, successResponse } = require('../utils/responseHandler')

// Import models
const StockItem = require('../models/StockItem')
const Transaction = require('../models/Transaction')
const MillingRecord = require('../models/MillingRecord')

// Import validators (to be implemented)
const {
  validateStockCreation,
  validateStockUpdate,
  validateStockAdjustment
} = require('../validators/stockValidator')

// Apply authentication and company isolation to all routes
router.use(auth)
router.use(companyGuard)

// Import controller functions
const {
  getStock,
  getStockById,
  getStockSummary,
  createStockItem,
  updateStockItem,
  adjustStock,
  getItemsForSale,
  getPaddyForMilling,
  syncStock
} = require('../controllers/stockController')

/**
 * @route   POST /api/stock/sync
 * @desc    Sync multiple stock items from client
 * @access  Private (Company users)
 */
router.post('/sync', syncStock)

/**
 * @route   GET /api/stock
 * @desc    Get all stock items with filtering and pagination
 * @access  Private (Company users)
 */
router.get('/', getStock)

/**
 * @route   GET /api/stock/:id
 * @desc    Get single stock item with history
 * @access  Private (Company users)
 */
router.get('/:id', async (req, res) => {
  try {
    const item = await StockItem.findOne({
      _id: req.params.id,
      ...req.companyFilter
    })

    if (!item) {
      return errorResponse(res, 'Stock item not found', 404)
    }

    // Get item history (placeholder - implement actual history tracking)
    const history = [] // TODO: Implement stock history tracking

    const data = {
      item,
      history
    }

    return successResponse(res, 'Stock item retrieved successfully', data)
  } catch (error) {
    console.error('Get Stock Item Error:', error)
    return errorResponse(res, 'Error retrieving stock item', 500, error.message)
  }
})

/**
 * @route   GET /api/stock/summary
 * @desc    Get stock summary for dashboard
 * @access  Private (Company users)
 */
router.get('/summary', async (req, res) => {
  try {
    const summary = await StockItem.aggregate([
      { $match: { ...req.companyFilter } },
      {
        $group: {
          _id: '$itemType',
          totalKg: { $sum: '$totalWeightKg' },
          totalBags: { $sum: '$totalBags' },
          totalValue: { $sum: { $multiply: ['$totalWeightKg', '$pricePerKg'] } },
          varieties: { $sum: 1 }
        }
      }
    ])

    const paddyStats = summary.find(s => s._id === 'paddy') || { totalKg: 0, totalBags: 0, totalValue: 0, varieties: 0 }
    const riceStats = summary.find(s => s._id === 'rice') || { totalKg: 0, totalBags: 0, totalValue: 0, varieties: 0 }

    // Get low stock items
    const lowStockItems = await StockItem.find({
      ...req.companyFilter,
      isLowStock: true
    }).select('name itemType totalWeightKg minimumStock')

    const data = {
      paddy: {
        totalKg: paddyStats.totalKg,
        totalBags: paddyStats.totalBags,
        totalValue: paddyStats.totalValue,
        varieties: paddyStats.varieties
      },
      rice: {
        totalKg: riceStats.totalKg,
        totalBags: riceStats.totalBags,
        totalValue: riceStats.totalValue,
        varieties: riceStats.varieties
      },
      lowStockItems
    }

    return successResponse(res, 'Stock summary retrieved successfully', data)
  } catch (error) {
    console.error('Get Stock Summary Error:', error)
    return errorResponse(res, 'Error retrieving stock summary', 500, error.message)
  }
})

/**
 * @route   POST /api/stock
 * @desc    Create new stock item
 * @access  Private (Company users)
 */
router.post('/', validateStockCreation, async (req, res) => {
  try {
    const errors = validationResult(req)
    if (!errors.isEmpty()) {
      return errorResponse(res, 'Validation failed', 400, errors.array())
    }

    const {
      name,
      itemType,
      totalWeightKg,
      totalBags,
      pricePerKg,
      description,
      clientId
    } = req.body

    // Create stock item
    const stockItem = await StockItem.create({
      name,
      itemType,
      totalWeightKg,
      totalBags,
      pricePerKg,
      description,
      clientId,
      companyId: req.companyId
    })

    return successResponse(res, 'Stock item created successfully', { item: stockItem }, 201)
  } catch (error) {
    console.error('Create Stock Item Error:', error)

    // Handle duplicate name+itemType+companyId
    if (error.code === 11000) {
      return errorResponse(res, 'An item with this name and type already exists', 409)
    }

    return errorResponse(res, 'Error creating stock item', 500, error.message)
  }
})

/**
 * @route   PUT /api/stock/:id
 * @desc    Update stock item details
 * @access  Private (Company users)
 */
router.put('/:id', validateStockUpdate, async (req, res) => {
  try {
    const errors = validationResult(req)
    if (!errors.isEmpty()) {
      return errorResponse(res, 'Validation failed', 400, errors.array())
    }

    const allowedUpdates = [
      'name', 'pricePerKg', 'minimumStock', 'description', 'isActive'
    ]

    const updates = {}
    allowedUpdates.forEach(field => {
      if (req.body[field] !== undefined) {
        updates[field] = req.body[field]
      }
    })

    const item = await StockItem.findOneAndUpdate(
      { _id: req.params.id, ...req.companyFilter },
      updates,
      { new: true, runValidators: true }
    )

    if (!item) {
      return errorResponse(res, 'Stock item not found', 404)
    }

    return successResponse(res, 'Stock item updated successfully', { item })
  } catch (error) {
    console.error('Update Stock Item Error:', error)
    return errorResponse(res, 'Error updating stock item', 500, error.message)
  }
})

/**
 * @route   POST /api/stock/:id/adjust
 * @desc    Manual stock adjustment
 * @access  Private (Company users)
 */
router.post('/:id/adjust', validateStockAdjustment, async (req, res) => {
  try {
    const errors = validationResult(req)
    if (!errors.isEmpty()) {
      return errorResponse(res, 'Validation failed', 400, errors.array())
    }

    const { adjustmentType, weightKg, bags, reason, notes } = req.body

    const item = await StockItem.findOne({
      _id: req.params.id,
      ...req.companyFilter
    })

    if (!item) {
      return errorResponse(res, 'Stock item not found', 404)
    }

    const previousWeight = item.totalWeightKg
    const previousBags = item.totalBags

    // Perform adjustment
    await item.updateStock(
      weightKg || 0,
      bags || 0,
      adjustmentType === 'subtract' ? 'subtract' : 'add'
    )

    // TODO: Log adjustment in stock history

    const data = {
      previousQuantity: previousWeight,
      adjustmentQuantity: weightKg || 0,
      newQuantity: item.totalWeightKg,
      previousBags,
      adjustmentBags: bags || 0,
      newBags: item.totalBags
    }

    return successResponse(res, 'Stock adjusted successfully', data)
  } catch (error) {
    console.error('Stock Adjustment Error:', error)
    return errorResponse(res, 'Error adjusting stock', 500, error.message)
  }
})

/**
 * @route   GET /api/stock/for-sale
 * @desc    Get items with available stock for selling
 * @access  Private (Company users)
 */
router.get('/for-sale', async (req, res) => {
  try {
    const { itemType } = req.query

    const query = {
      ...req.companyFilter,
      isActive: true,
      totalWeightKg: { $gt: 0 }
    }

    if (itemType) query.itemType = itemType

    const items = await StockItem.find(query)
      .select('name itemType totalWeightKg totalBags pricePerKg')
      .sort({ name: 1 })

    const data = items.map(item => ({
      id: item._id,
      name: item.name,
      itemType: item.itemType,
      availableKg: item.totalWeightKg,
      availableBags: item.totalBags,
      pricePerKg: item.pricePerKg
    }))

    return successResponse(res, 'Available items for sale retrieved successfully', data)
  } catch (error) {
    console.error('Get For Sale Items Error:', error)
    return errorResponse(res, 'Error retrieving items for sale', 500, error.message)
  }
})

/**
 * @route   GET /api/stock/paddy-for-milling
 * @desc    Get paddy items for milling process
 * @access  Private (Company users)
 */
router.get('/paddy-for-milling', async (req, res) => {
  try {
    const items = await StockItem.find({
      ...req.companyFilter,
      itemType: 'paddy',
      isActive: true,
      totalWeightKg: { $gt: 0 }
    })
      .select('name totalWeightKg totalBags')
      .sort({ name: 1 })

    const data = items.map(item => ({
      id: item._id,
      name: item.name,
      availableKg: item.totalWeightKg,
      availableBags: item.totalBags
    }))

    return successResponse(res, 'Paddy items for milling retrieved successfully', data)
  } catch (error) {
    console.error('Get Paddy For Milling Error:', error)
    return errorResponse(res, 'Error retrieving paddy items for milling', 500, error.message)
  }
})

// Since I switched to controller functions for some routes, I should update the existing ones to be consistent or keep them as is if they work.
// Actually, the file was using inline functions for everything. I'll stick to the inline function pattern if that's what's already there,
// OR I'll update all of them to use the controller.
// Looking at the file, lines 29, 113, 145, 198, 246, 287, 339, 377 all use inline functions.
// I will rewrite the sync route to be inline to match the existing style, or just keep the controller import and use it for sync.
// To avoid complex refactoring, I'll just put the sync logic inline or call the controller function.

module.exports = router
