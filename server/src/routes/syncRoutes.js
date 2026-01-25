const express = require('express')
const router = express.Router()
const auth = require('../middleware/auth')
const companyGuard = require('../middleware/companyGuard')
const { validationResult } = require('express-validator')
const { errorResponse, successResponse } = require('../utils/responseHandler')

// Import models
const SyncQueue = require('../models/SyncQueue')
const Customer = require('../models/Customer')
const StockItem = require('../models/StockItem')
const Transaction = require('../models/Transaction')
const MillingRecord = require('../models/MillingRecord')

// Import validators (to be implemented)
const {
  validateSyncOperations
} = require('../validators/syncValidator')

// Apply authentication and company isolation to all routes
router.use(auth)
router.use(companyGuard)

/**
 * @route   POST /api/sync/push
 * @desc    Receive batch of offline operations from mobile app
 * @access  Private (Company users)
 */
router.post('/push', validateSyncOperations, async (req, res) => {
  try {
    const errors = validationResult(req)
    if (!errors.isEmpty()) {
      return errorResponse(res, 'Validation failed', 400, errors.array())
    }

    const { operations } = req.body

    // Sort operations by clientCreatedAt (FIFO)
    operations.sort((a, b) => new Date(a.clientCreatedAt) - new Date(b.clientCreatedAt))

    const results = []
    let processed = 0
    let succeeded = 0
    let failed = 0

    // Process each operation
    for (const operation of operations) {
      processed++
      const result = await processSyncOperation(operation, req.companyId, req.user.id)
      results.push(result)

      if (result.status === 'success') {
        succeeded++
      } else {
        failed++
      }
    }

    const data = {
      processed,
      succeeded,
      failed,
      results
    }

    return successResponse(res, 'Sync completed', data)
  } catch (error) {
    console.error('Sync Push Error:', error)
    return errorResponse(res, 'Error processing sync operations', 500, error.message)
  }
})

/**
 * @route   GET /api/sync/pull
 * @desc    Get all data modified since last sync
 * @access  Private (Company users)
 */
router.get('/pull', async (req, res) => {
  try {
    const { lastSyncTime, entities = 'customers,stock,transactions' } = req.query
    const entityList = entities.split(',')

    const syncTime = new Date().toISOString()
    const lastSync = lastSyncTime ? new Date(lastSyncTime) : new Date(0)
    const changes = {}

    // Get changes for each entity type
    if (entityList.includes('customers')) {
      changes.customers = await getEntityChanges('customers', Customer, lastSync, req.companyFilter)
    }

    if (entityList.includes('stock')) {
      changes.stock = await getEntityChanges('stock', StockItem, lastSync, req.companyFilter)
    }

    if (entityList.includes('transactions')) {
      changes.transactions = await getEntityChanges('transactions', Transaction, lastSync, req.companyFilter)
    }

    if (entityList.includes('milling')) {
      changes.milling = await getEntityChanges('milling', MillingRecord, lastSync, req.companyFilter)
    }

    const data = {
      syncTime,
      changes
    }

    return successResponse(res, 'Sync data retrieved successfully', data)
  } catch (error) {
    console.error('Sync Pull Error:', error)
    return errorResponse(res, 'Error retrieving sync data', 500, error.message)
  }
})

/**
 * @route   GET /api/sync/status
 * @desc    Check sync status and pending items
 * @access  Private (Company users)
 */
router.get('/status', async (req, res) => {
  try {
    // Get sync statistics for company
    const pendingOperations = await SyncQueue.countDocuments({
      companyId: req.companyId,
      status: 'pending'
    })

    const failedOperations = await SyncQueue.countDocuments({
      companyId: req.companyId,
      status: 'failed'
    })

    // Get last successful sync time (placeholder - would need sync log)
    const lastSyncRecord = await SyncQueue.findOne({
      companyId: req.companyId,
      status: 'completed'
    }).sort({ updatedAt: -1 })

    const data = {
      lastSyncTime: lastSyncRecord?.updatedAt?.toISOString() || null,
      pendingOperations,
      failedOperations,
      serverTime: new Date().toISOString()
    }

    return successResponse(res, 'Sync status retrieved successfully', data)
  } catch (error) {
    console.error('Sync Status Error:', error)
    return errorResponse(res, 'Error retrieving sync status', 500, error.message)
  }
})

/**
 * @route   POST /api/sync/resolve-conflict
 * @desc    Resolve sync conflict
 * @access  Private (Company users)
 */
router.post('/resolve-conflict', async (req, res) => {
  try {
    const { clientId, resolution, mergedData } = req.body

    // Find the conflict in sync queue
    const syncItem = await SyncQueue.findOne({
      clientId,
      status: 'conflict',
      companyId: req.companyId
    })

    if (!syncItem) {
      return errorResponse(res, 'Conflict not found', 404)
    }

    let result
    switch (resolution) {
      case 'keep_server':
        // Mark as resolved, keep server data
        result = await syncItem.markAsCompleted()
        break

      case 'keep_client':
        // Apply client data
        const clientResult = await processSyncOperation({
          ...syncItem.toObject(),
          data: syncItem.data
        }, req.companyId, req.user.id)
        result = clientResult.status === 'success' ? await syncItem.markAsCompleted() : await syncItem.markAsFailed(clientResult.error)
        break

      case 'merge':
        // Apply merged data
        if (!mergedData) {
          return errorResponse(res, 'Merged data is required for merge resolution', 400)
        }
        const mergeResult = await processSyncOperation({
          ...syncItem.toObject(),
          data: mergedData
        }, req.companyId, req.user.id)
        result = mergeResult.status === 'success' ? await syncItem.markAsCompleted() : await syncItem.markAsFailed(mergeResult.error)
        break

      default:
        return errorResponse(res, 'Invalid resolution type', 400)
    }

    return successResponse(res, 'Conflict resolved successfully', { syncItem: result })
  } catch (error) {
    console.error('Resolve Conflict Error:', error)
    return errorResponse(res, 'Error resolving conflict', 500, error.message)
  }
})

// Helper function to process a single sync operation
async function processSyncOperation (operation, companyId, userId) {
  const { clientId, entityType, operation: op, data, clientCreatedAt } = operation

  try {
    // Check if already processed (idempotency)
    const existingSync = await SyncQueue.findOne({ clientId })
    if (existingSync && existingSync.status === 'completed') {
      return {
        clientId,
        status: 'success',
        message: 'Already processed',
        serverId: existingSync._id
      }
    }

    // Create sync queue entry
    const syncItem = await SyncQueue.create({
      clientId,
      entityType,
      operation: op,
      data,
      companyId,
      userId,
      clientCreatedAt: new Date(clientCreatedAt)
    })

    // Process the operation based on entity type
    let result
    switch (entityType) {
      case 'customer':
        result = await processCustomerOperation(op, data, companyId)
        break
      case 'stock_item':
        result = await processStockOperation(op, data, companyId)
        break
      case 'transaction':
        result = await processTransactionOperation(op, data, companyId, userId)
        break
      case 'milling_record':
        result = await processMillingOperation(op, data, companyId, userId)
        break
      default:
        throw new Error(`Unknown entity type: ${entityType}`)
    }

    // Mark sync as completed
    await syncItem.markAsCompleted()

    return {
      clientId,
      status: 'success',
      serverId: result._id,
      serverData: result
    }
  } catch (error) {
    console.error(`Sync operation failed for ${clientId}:`, error)

    // Mark sync as failed
    const syncItem = await SyncQueue.findOne({ clientId })
    if (syncItem) {
      await syncItem.markAsFailed(error.message)
    }

    return {
      clientId,
      status: 'failed',
      error: error.message
    }
  }
}

// Helper functions for processing different entity types
async function processCustomerOperation (operation, data, companyId) {
  switch (operation) {
    case 'create':
      return await Customer.create({
        ...data,
        companyId
      })
    case 'update':
      return await Customer.findOneAndUpdate(
        { _id: data._id, companyId },
        data,
        { new: true }
      )
    case 'delete':
      await Customer.findOneAndUpdate(
        { _id: data._id, companyId },
        { isActive: false }
      )
      return { _id: data._id, deleted: true }
    default:
      throw new Error(`Unsupported operation: ${operation}`)
  }
}

async function processStockOperation (operation, data, companyId) {
  switch (operation) {
    case 'create':
      return await StockItem.create({
        ...data,
        companyId
      })
    case 'update':
      return await StockItem.findOneAndUpdate(
        { _id: data._id, companyId },
        data,
        { new: true }
      )
    case 'delete':
      await StockItem.findOneAndUpdate(
        { _id: data._id, companyId },
        { isActive: false }
      )
      return { _id: data._id, deleted: true }
    default:
      throw new Error(`Unsupported operation: ${operation}`)
  }
}

async function processTransactionOperation (operation, data, companyId, userId) {
  switch (operation) {
    case 'create':
      return await Transaction.create({
        ...data,
        companyId,
        createdBy: userId
      })
    case 'update':
      return await Transaction.findOneAndUpdate(
        { _id: data._id, companyId },
        data,
        { new: true }
      )
    default:
      throw new Error(`Unsupported operation: ${operation}`)
  }
}

async function processMillingOperation (operation, data, companyId, userId) {
  switch (operation) {
    case 'create':
      return await MillingRecord.create({
        ...data,
        companyId,
        milledBy: userId
      })
    default:
      throw new Error(`Unsupported operation: ${operation}`)
  }
}

// Helper function to get entity changes since last sync
async function getEntityChanges (entityName, Model, lastSync, companyFilter) {
  const changes = {
    created: [],
    updated: [],
    deleted: []
  }

  // Get created/updated records
  const modifiedRecords = await Model.find({
    ...companyFilter,
    updatedAt: { $gte: lastSync }
  }).select('_id name updatedAt')

  // Get deleted records (soft delete - isActive: false)
  if (Model.schema.paths.isActive) {
    const deletedRecords = await Model.find({
      ...companyFilter,
      isActive: false,
      updatedAt: { $gte: lastSync }
    }).select('_id')

    changes.deleted = deletedRecords.map(r => r._id)
  }

  // Separate created vs updated
  for (const record of modifiedRecords) {
    if (record.createdAt >= lastSync) {
      changes.created.push(record)
    } else {
      changes.updated.push(record)
    }
  }

  return changes
}

module.exports = router
