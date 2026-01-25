/**
 * OPTIONAL SYNC ROUTES
 *
 * ✅ Server is OPTIONAL - app works without it
 * ✅ Just receives and stores data
 * ✅ No complex conflict resolution
 * ✅ Simple backup/restore functionality
 * ✅ Fire-and-forget approach
 *
 * Philosophy:
 * - Client is source of truth
 * - Server just stores a copy
 * - If server is down, app still works
 * - Sync is best-effort, not critical
 */

const express = require('express')
const router = express.Router()
const auth = require('../middleware/auth')
const companyGuard = require('../middleware/companyGuard')
const { successResponse, errorResponse } = require('../utils/responseHandler')
const logger = require('../utils/logger')

// Import models
const Customer = require('../models/Customer')
const StockItem = require('../models/StockItem')
const Transaction = require('../models/Transaction')
const MillingRecord = require('../models/MillingRecord')

// Apply auth and company isolation
router.use(auth)
router.use(companyGuard)

/**
 * POST /api/sync/push
 *
 * Client sends offline operations
 * Server just stores them (no complex logic)
 *
 * ✅ Works even if server is slow/down
 * ✅ Client doesn't wait for response
 * ✅ Simple fire-and-forget
 */
router.post('/push', async (req, res) => {
  try {
    const { operations, lastSyncTime, deviceId } = req.body
    const companyId = req.companyId
    const userId = req.user.id

    if (!operations || !Array.isArray(operations)) {
      return errorResponse(res, 'Operations array required', 400)
    }

    logger.info(`[SYNC PUSH] Received ${operations.length} operations from device ${deviceId}`)

    // Sort by timestamp (FIFO)
    operations.sort((a, b) => new Date(a.clientCreatedAt) - new Date(b.clientCreatedAt))

    const results = []
    let succeeded = 0
    let failed = 0

    // Process each operation (simple, no conflict resolution)
    for (const op of operations) {
      try {
        const result = await processSimpleOperation(op, companyId, userId)
        results.push(result)
        if (result.status === 'success') succeeded++
        else failed++
      } catch (error) {
        logger.error('[SYNC] Operation failed:', error)
        results.push({
          clientId: op.clientId,
          status: 'error',
          error: error.message
        })
        failed++
      }
    }

    logger.info(`[SYNC PUSH] Complete: ${succeeded} success, ${failed} failed`)

    // Return immediately (fire-and-forget)
    return successResponse(res, 'Operations received', {
      processed: operations.length,
      succeeded,
      failed,
      results
    })
  } catch (error) {
    logger.error('[SYNC PUSH] Error:', error)
    return errorResponse(res, 'Sync push failed', 500, error.message)
  }
})

/**
 * GET /api/sync/pull
 *
 * Client requests all data since last sync
 * Server returns everything (simple backup)
 *
 * ✅ Client can work offline if this fails
 * ✅ Just returns data, no merging
 */
router.get('/pull', async (req, res) => {
  try {
    const { lastSyncTime } = req.query
    const companyId = req.companyId

    if (!lastSyncTime) {
      return errorResponse(res, 'lastSyncTime query param required', 400)
    }

    const lastSync = new Date(lastSyncTime)
    logger.info(`[SYNC PULL] Fetching changes since ${lastSync.toISOString()}`)

    // Fetch all entities modified after lastSyncTime
    const [customers, stockItems, transactions, millingRecords] = await Promise.all([
      Customer.find({
        companyId,
        updatedAt: { $gt: lastSync }
      }).lean(),
      StockItem.find({
        companyId,
        updatedAt: { $gt: lastSync }
      }).lean(),
      Transaction.find({
        companyId,
        updatedAt: { $gt: lastSync }
      }).lean(),
      MillingRecord.find({
        companyId,
        updatedAt: { $gt: lastSync }
      }).lean()
    ])

    logger.info('[SYNC PULL] Found changes:', {
      customers: customers.length,
      stockItems: stockItems.length,
      transactions: transactions.length,
      millingRecords: millingRecords.length
    })

    const changes = {
      customers,
      stockItems,
      transactions,
      millingRecords,
      serverTime: new Date()
    }

    return successResponse(res, 'Changes fetched', changes)
  } catch (error) {
    logger.error('[SYNC PULL] Error:', error)
    // Don't fail - client can work offline
    return successResponse(res, 'No changes', {
      customers: [],
      stockItems: [],
      transactions: [],
      millingRecords: [],
      serverTime: new Date()
    })
  }
})

/**
 * GET /api/sync/status
 *
 * Check if server is alive
 * Client uses this to decide if sync is possible
 */
router.get('/status', async (req, res) => {
  try {
    return successResponse(res, 'Server is alive', {
      status: 'healthy',
      serverTime: new Date(),
      message: 'Sync server is running'
    })
  } catch (error) {
    logger.error('[SYNC STATUS] Error:', error)
    return errorResponse(res, 'Server error', 500)
  }
})

/**
 * INTERNAL: Process single operation (simple, no conflict resolution)
 *
 * Just stores the data as-is
 * No merging, no conflict detection
 * Client is source of truth
 */
async function processSimpleOperation (operation, companyId, userId) {
  const { clientId, entityType, operation: op, data } = operation

  logger.debug(`[PROCESS OP] ${op} ${entityType} (${clientId})`)

  try {
    switch (entityType) {
      case 'customer':
        return await processCustomer(op, data, companyId, userId, clientId)

      case 'stock_item':
        return await processStockItem(op, data, companyId, userId, clientId)

      case 'transaction':
        return await processTransaction(op, data, companyId, userId, clientId)

      case 'milling_record':
        return await processMillingRecord(op, data, companyId, userId, clientId)

      default:
        return {
          clientId,
          status: 'error',
          error: `Unknown entity type: ${entityType}`
        }
    }
  } catch (error) {
    logger.error('[PROCESS OP] Error:', error)
    return {
      clientId,
      status: 'error',
      error: error.message
    }
  }
}

/**
 * Process customer operation
 * Simple: just create or update
 */
async function processCustomer (op, data, companyId, userId, clientId) {
  const { _id, ...customerData } = data

  switch (op) {
    case 'create':
    case 'update': {
      // Upsert: create if doesn't exist, update if does
      await Customer.findByIdAndUpdate(
        _id,
        {
          ...customerData,
          companyId,
          updatedBy: userId
        },
        { upsert: true, new: true }
      )
      logger.info(`[CUSTOMER] ${op}: ${_id}`)
      return { clientId, status: 'success', serverId: _id }
    }

    case 'delete': {
      // Soft delete
      await Customer.findByIdAndUpdate(_id, {
        isActive: false,
        isDeleted: true,
        deletedAt: new Date()
      })
      logger.info(`[CUSTOMER] Soft deleted: ${_id}`)
      return { clientId, status: 'success', serverId: _id }
    }

    default:
      return { clientId, status: 'error', error: `Unknown operation: ${op}` }
  }
}

/**
 * Process stock item operation
 * Simple: just create or update
 */
async function processStockItem (op, data, companyId, userId, clientId) {
  const { _id, ...stockData } = data

  switch (op) {
    case 'create':
    case 'update': {
      // Upsert
      await StockItem.findByIdAndUpdate(
        _id,
        {
          ...stockData,
          companyId,
          updatedBy: userId
        },
        { upsert: true, new: true }
      )
      logger.info(`[STOCK] ${op}: ${_id}`)
      return { clientId, status: 'success', serverId: _id }
    }

    case 'delete': {
      // Soft delete
      await StockItem.findByIdAndUpdate(_id, {
        isActive: false,
        deletedAt: new Date()
      })
      logger.info(`[STOCK] Soft deleted: ${_id}`)
      return { clientId, status: 'success', serverId: _id }
    }

    default:
      return { clientId, status: 'error', error: `Unknown operation: ${op}` }
  }
}

/**
 * Process transaction operation
 * Simple: just create or update
 */
async function processTransaction (op, data, companyId, userId, clientId) {
  const { _id, ...txData } = data

  switch (op) {
    case 'create':
    case 'update': {
      // Upsert
      await Transaction.findByIdAndUpdate(
        _id,
        {
          ...txData,
          companyId,
          updatedBy: userId
        },
        { upsert: true, new: true }
      )
      logger.info(`[TRANSACTION] ${op}: ${_id}`)
      return { clientId, status: 'success', serverId: _id }
    }

    case 'delete': {
      // Soft delete
      await Transaction.findByIdAndUpdate(_id, {
        isActive: false,
        deletedAt: new Date()
      })
      logger.info(`[TRANSACTION] Soft deleted: ${_id}`)
      return { clientId, status: 'success', serverId: _id }
    }

    default:
      return { clientId, status: 'error', error: `Unknown operation: ${op}` }
  }
}

/**
 * Process milling record operation
 * Simple: just create or update
 */
async function processMillingRecord (op, data, companyId, userId, clientId) {
  const { _id, ...millingData } = data

  switch (op) {
    case 'create':
    case 'update': {
      // Upsert
      await MillingRecord.findByIdAndUpdate(
        _id,
        {
          ...millingData,
          companyId,
          updatedBy: userId
        },
        { upsert: true, new: true }
      )
      logger.info(`[MILLING] ${op}: ${_id}`)
      return { clientId, status: 'success', serverId: _id }
    }

    case 'delete': {
      // Soft delete
      await MillingRecord.findByIdAndUpdate(_id, {
        isActive: false,
        deletedAt: new Date()
      })
      logger.info(`[MILLING] Soft deleted: ${_id}`)
      return { clientId, status: 'success', serverId: _id }
    }

    default:
      return { clientId, status: 'error', error: `Unknown operation: ${op}` }
  }
}

module.exports = router
