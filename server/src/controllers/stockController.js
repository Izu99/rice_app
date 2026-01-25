const StockItem = require('../models/StockItem')
const Transaction = require('../models/Transaction')
const MillingRecord = require('../models/MillingRecord')
const { validationResult } = require('express-validator')
const { errorResponse, successResponse } = require('../utils/responseHandler')

/**
 * @desc    Get all stock items with filtering and pagination
 * @route   GET /api/stock
 * @access  Private (Company users)
 */
exports.getStock = async (req, res) => {
  try {
    const {
      itemType,
      search,
      lowStock,
      page = 1,
      limit = 50,
      sortBy = 'createdAt',
      sortOrder = 'desc'
    } = req.query

    // Build query with company filter
    const query = {
      ...req.companyFilter,
      isActive: true
    }

    if (itemType) query.itemType = itemType
    if (lowStock === 'true') query.isLowStock = true

    if (search) {
      query.name = { $regex: search, $options: 'i' }
    }

    // Build sort
    const sort = {}
    sort[sortBy] = sortOrder === 'desc' ? -1 : 1

    // Get stock items
    const items = await StockItem.find(query)
      .sort(sort)
      .limit(limit * 1)
      .skip((page - 1) * limit)

    // Get summary statistics
    const summary = await StockItem.getStockSummary(req.companyId)

    const total = await StockItem.countDocuments(query)
    const pages = Math.ceil(total / limit)

    const data = {
      items: items.map(item => item.getDetails()),
      summary,
      pagination: {
        total,
        page: parseInt(page),
        limit: parseInt(limit),
        pages
      }
    }

    return successResponse(res, 'Stock items retrieved successfully', data)
  } catch (error) {
    console.error('Get Stock Error:', error)
    return errorResponse(res, 'Error retrieving stock items', 500, error.message)
  }
}

/**
 * @desc    Get single stock item with history
 * @route   GET /api/stock/:id
 * @access  Private (Company users)
 */
exports.getStockById = async (req, res) => {
  try {
    const item = await StockItem.findOne({
      _id: req.params.id,
      ...req.companyFilter
    })

    if (!item) {
      return errorResponse(res, 'Stock item not found', 404)
    }

    // Get transaction history (simplified - would need transaction log)
    const history = []

    // Get buy transactions that added this item
    const buyTransactions = await Transaction.find({
      'items.stockItemId': req.params.id,
      type: 'buy',
      ...req.companyFilter
    })
      .sort({ transactionDate: -1 })
      .limit(10)
      .select('transactionNumber transactionDate items.$ customerName')

    // Get sell transactions that reduced this item
    const sellTransactions = await Transaction.find({
      'items.stockItemId': req.params.id,
      type: 'sell',
      ...req.companyFilter
    })
      .sort({ transactionDate: -1 })
      .limit(10)
      .select('transactionNumber transactionDate items.$ customerName')

    // Get milling records that used this item
    const millingRecords = await MillingRecord.find({
      paddyItemId: req.params.id,
      ...req.companyFilter
    })
      .sort({ millingDate: -1 })
      .limit(5)
      .select('batchNumber millingDate inputPaddyKg outputRiceKg')

    // Combine and sort history
    const allHistory = [
      ...buyTransactions.map(t => ({
        type: 'purchase',
        date: t.transactionDate,
        quantity: t.items.find(i => i.stockItemId.toString() === req.params.id)?.weightKg || 0,
        reference: t.transactionNumber,
        customer: t.customerName,
        operation: 'add'
      })),
      ...sellTransactions.map(t => ({
        type: 'sale',
        date: t.transactionDate,
        quantity: t.items.find(i => i.stockItemId.toString() === req.params.id)?.weightKg || 0,
        reference: t.transactionNumber,
        customer: t.customerName,
        operation: 'subtract'
      })),
      ...millingRecords.map(m => ({
        type: 'milling',
        date: m.millingDate,
        quantity: m.inputPaddyKg,
        reference: m.batchNumber,
        operation: 'subtract'
      }))
    ].sort((a, b) => new Date(b.date) - new Date(a.date)).slice(0, 20)

    const data = {
      item: item.getDetails(),
      history: allHistory
    }

    return successResponse(res, 'Stock item retrieved successfully', data)
  } catch (error) {
    console.error('Get Stock Item Error:', error)
    return errorResponse(res, 'Error retrieving stock item', 500, error.message)
  }
}

/**
 * @desc    Get stock summary for dashboard
 * @route   GET /api/stock/summary
 * @access  Private (Company users)
 */
exports.getStockSummary = async (req, res) => {
  try {
    const summary = await StockItem.getStockSummary(req.companyId)

    // Get low stock items
    const lowStockItems = await StockItem.find({
      ...req.companyFilter,
      isLowStock: true,
      isActive: true
    })
      .select('name itemType totalWeightKg minimumStock')
      .sort({ totalWeightKg: 1 })
      .limit(10)

    const data = {
      ...summary,
      lowStockItems: lowStockItems.map(item => ({
        id: item._id,
        name: item.name,
        itemType: item.itemType,
        currentStock: item.totalWeightKg,
        minimumStock: item.minimumStock,
        shortage: item.minimumStock - item.totalWeightKg
      }))
    }

    return successResponse(res, 'Stock summary retrieved successfully', data)
  } catch (error) {
    console.error('Get Stock Summary Error:', error)
    return errorResponse(res, 'Error retrieving stock summary', 500, error.message)
  }
}

/**
 * @desc    Create new stock item
 * @route   POST /api/stock
 * @access  Private (Company users)
 */
exports.createStockItem = async (req, res) => {
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
      minimumStock,
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
      minimumStock: minimumStock || 10,
      companyId: req.companyId,
      clientId
    })

    return successResponse(res, 'Stock item created successfully', {
      item: stockItem.getDetails()
    }, 201)
  } catch (error) {
    console.error('Create Stock Item Error:', error)

    // Handle duplicate name+itemType+companyId
    if (error.code === 11000) {
      return errorResponse(res, 'An item with this name and type already exists', 409)
    }

    return errorResponse(res, 'Error creating stock item', 500, error.message)
  }
}

/**
 * @desc    Update stock item details
 * @route   PUT /api/stock/:id
 * @access  Private (Company users)
 */
exports.updateStockItem = async (req, res) => {
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

    return successResponse(res, 'Stock item updated successfully', {
      item: item.getDetails()
    })
  } catch (error) {
    console.error('Update Stock Item Error:', error)
    return errorResponse(res, 'Error updating stock item', 500, error.message)
  }
}

/**
 * @desc    Manual stock adjustment
 * @route   POST /api/stock/:id/adjust
 * @access  Private (Company users)
 */
exports.adjustStock = async (req, res) => {
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
    await item.updateStock(weightKg || 0, bags || 0, adjustmentType === 'subtract' ? 'subtract' : 'add')

    const data = {
      itemId: item._id,
      itemName: item.name,
      previousQuantity: previousWeight,
      adjustmentQuantity: weightKg || 0,
      newQuantity: item.totalWeightKg,
      previousBags,
      adjustmentBags: bags || 0,
      newBags: item.totalBags,
      adjustmentType,
      reason,
      notes
    }

    return successResponse(res, 'Stock adjusted successfully', data)
  } catch (error) {
    console.error('Stock Adjustment Error:', error)
    return errorResponse(res, 'Error adjusting stock', 500, error.message)
  }
}

/**
 * @desc    Get items available for sale
 * @route   GET /api/stock/for-sale
 * @access  Private (Company users)
 */
exports.getItemsForSale = async (req, res) => {
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
}

/**
 * @desc    Get paddy items for milling
 * @route   GET /api/stock/paddy-for-milling
 * @access  Private (Company users)
 */
exports.getPaddyForMilling = async (req, res) => {
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
}
/**
 * @desc    Sync multiple stock items from client
 * @route   POST /api/stock/sync
 * @access  Private (Company users)
 */
exports.syncStock = async (req, res) => {
  try {
    const { items } = req.body
    if (!items || !Array.isArray(items)) {
      return errorResponse(res, 'Items array is required', 400)
    }

    const synced = []
    const errors = []

    for (const itemData of items) {
      try {
        const name = itemData.variety || itemData.name || itemData.itemName || 'Unknown'
        const itemType = itemData.type || itemData.itemType || itemData.item_type || 'paddy'

        // Try to find existing item by variety and type for this company
        // Aggregation logic: Combine stock if variety/type matches
        let item = await StockItem.findOne({
          name,
          itemType,
          companyId: req.companyId
        })

        if (item) {
          // Update existing item - combine quantities
          item.totalWeightKg = (item.totalWeightKg || 0) + (itemData.current_quantity || 0)
          item.totalBags = (item.totalBags || 0) + (itemData.current_bags || 0)

          // Update average price if provided
          if (itemData.average_price_per_kg) {
            await item.updateAvgPurchasePrice(
              itemData.average_price_per_kg,
              itemData.current_quantity || 0
            )
          } else {
            await item.save()
          }
        } else {
          // Create new item
          item = await StockItem.create({
            name: itemData.variety || itemData.name,
            itemType: itemData.type || itemData.itemType,
            totalWeightKg: itemData.current_quantity || 0,
            totalBags: itemData.current_bags || 0,
            pricePerKg: itemData.average_price_per_kg || itemData.price_per_kg || 0,
            avgPurchasePrice: itemData.average_price_per_kg || itemData.price_per_kg || 0,
            description: itemData.description,
            companyId: req.companyId,
            clientId: itemData.local_id || itemData.id
          })
        }
        synced.push(item)
      } catch (err) {
        console.error(`Error syncing stock item ${itemData.variety}:`, err)
        errors.push({ variety: itemData.variety, error: err.message })
      }
    }

    return successResponse(res, 'Stock sync completed', { synced, errors })
  } catch (error) {
    console.error('Stock Sync Error:', error)
    return errorResponse(res, 'Error syncing stock', 500, error.message)
  }
}
