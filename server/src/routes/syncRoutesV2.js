/**
 * Modern Sync Routes - Handles offline-first sync with conflict resolution
 *
 * Flow:
 * 1. Client sends: operations (CREATE/UPDATE/DELETE) with timestamps
 * 2. Server processes each operation
 * 3. If conflict detected → resolve using ConflictResolver
 * 4. Server sends back: all changes since lastSyncTime
 * 5. Client merges changes into SQLite
 */

const express = require('express')
const router = express.Router()
const auth = require('../middleware/auth')
const companyGuard = require('../middleware/companyGuard')
const { validationResult } = require('express-validator')
const { errorResponse, successResponse } = require('../utils/responseHandler')
const ConflictResolver = require('../utils/syncMergeHelper')
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
 * Client sends batch of offline operations
 * Server processes and returns results
 */
router.post('/push', async (req, res) => {
  try {
    const { operations, lastSyncTime, deviceId } = req.body
    const companyId = req.companyId
    const userId = req.user.id

    if (!operations || !Array.isArray(operations)) {
      return errorResponse(res, 'Operations array required', 400)
    }

    if (!lastSyncTime) {
      return errorResponse(res, 'lastSyncTime required', 400)
    }

    logger.info(`[SYNC PUSH] Processing ${operations.length} operations from device ${deviceId}`)

    // Sort by timestamp (FIFO)
    operations.sort((a, b) => new Date(a.clientCreatedAt) - new Date(b.clientCreatedAt))

    const results = []
    let succeeded = 0
    let failed = 0
    let conflicts = 0

    // Process each operation
    for (const op of operations) {
      try {
        const result = await processSyncOperation(op, companyId, userId, lastSyncTime)
        results.push(result)

        if (result.status === 'success') succeeded++
        else if (result.status === 'conflict') conflicts++
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

    logger.info(`[SYNC PUSH] Complete: ${succeeded} success, ${conflicts} conflicts, ${failed} failed`)

    return successResponse(res, 'Sync push completed', {
      processed: operations.length,
      succeeded,
      conflicts,
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
 * Client requests all changes since lastSyncTime
 * Server returns created/updated/deleted records
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
    return errorResponse(res, 'Sync pull failed', 500, error.message)
  }
})

/**
 * GET /api/sync/status
 *
 * Get sync statistics
 */
router.get('/status', async (req, res) => {
  try {
    const companyId = req.companyId

    const stats = {
      lastSyncTime: new Date(),
      serverTime: new Date(),
      status: 'healthy'
    }

    return successResponse(res, 'Sync status', stats)
  } catch (error) {
    logger.error('[SYNC STATUS] Error:', error)
    return errorResponse(res, 'Status check failed', 500, error.message)
  }
})

/**
 * INTERNAL: Process single sync operation
 *
 * Handles: CREATE, UPDATE, DELETE
 * Detects and resolves conflicts
 */
async function processSyncOperation (operation, companyId, userId, lastSyncTime) {
  const { clientId, entityType, operation: op, data, clientCreatedAt } = operation

  logger.debug(`[PROCESS OP] ${op} ${entityType} (${clientId})`)

  try {
    switch (entityType) {
      case 'customer':
        return await processCustomerOperation(op, data, companyId, userId, clientId, lastSyncTime)

      case 'stock_item':
        return await processStockOperation(op, data, companyId, userId, clientId, lastSyncTime)

      case 'transaction':
        return await processTransactionOperation(op, data, companyId, userId, clientId, lastSyncTime)

      case 'milling_record':
        return await processMillingOperation(op, data, companyId, userId, clientId, lastSyncTime)

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
 * Process customer operation with conflict resolution
 */
async function processCustomerOperation (op, data, companyId, userId, clientId, lastSyncTime) {
  const { _id, ...customerData } = data

  switch (op) {
    case 'create':
      const newCustomer = await Customer.create({
        _id,
        ...customerData,
        companyId,
        createdBy: userId
      })
      logger.info(`[CUSTOMER] Created: ${_id}`)
      return { clientId, status: 'success', serverId: newCustomer._id }

    case 'update': {
      const existing = await Customer.findById(_id)

      if (!existing) {
        // Record doesn't exist on server → create it
        const created = await Customer.create({
          _id,
          ...customerData,
          companyId,
          createdBy: userId
        })
        logger.info(`[CUSTOMER] Created (didn't exist): ${_id}`)
        return { clientId, status: 'success', serverId: created._id }
      }

      // Check for conflict
      const hasConflict = ConflictResolver.detectConflict(existing, customerData, lastSyncTime)

      if (hasConflict) {
        logger.warn(`[CUSTOMER] Conflict detected: ${_id}`)
        const resolved = ConflictResolver.mergeCustomer(existing, customerData, lastSyncTime)
        await Customer.findByIdAndUpdate(_id, resolved)
        return { clientId, status: 'conflict', serverId: _id, resolution: 'merged' }
      }

      // No conflict → use client data (newer)
      await Customer.findByIdAndUpdate(_id, customerData)
      logger.info(`[CUSTOMER] Updated: ${_id}`)
      return { clientId, status: 'success', serverId: _id }
    }

    case 'delete': {
      await Customer.findByIdAndUpdate(_id, { isActive: false, isDeleted: true })
      logger.info(`[CUSTOMER] Soft deleted: ${_id}`)
      return { clientId, status: 'success', serverId: _id }
    }

    default:
      return { clientId, status: 'error', error: `Unknown operation: ${op}` }
  }
}

/**
 * Process stock item operation with conflict resolution
 */
async function processStockOperation (op, data, companyId, userId, clientId, lastSyncTime) {
  const { _id, ...stockData } = data

  switch (op) {
    case 'create':
      const newStock = await StockItem.create({
        _id,
        ...stockData,
        companyId,
        createdBy: userId
      })
      logger.info(`[STOCK] Created: ${_id}`)
      return { clientId, status: 'success', serverId: newStock._id }

    case 'update': {
      const existing = await StockItem.findById(_id)

      if (!existing) {
        const created = await StockItem.create({
          _id,
          ...stockData,
          companyId,
          createdBy: userId
        })
        logger.info(`[STOCK] Created (didn't exist): ${_id}`)
        return { clientId, status: 'success', serverId: created._id }
      }

      // Check for conflict
      const hasConflict = ConflictResolver.detectConflict(existing, stockData, lastSyncTime)

      if (hasConflict) {
        logger.warn(`[STOCK] Conflict detected: ${_id}`)
        const resolved = ConflictResolver.mergeStockItem(existing, stockData, lastSyncTime)
        await StockItem.findByIdAndUpdate(_id, resolved)
        return { clientId, status: 'conflict', serverId: _id, resolution: 'merged' }
      }

      await StockItem.findByIdAndUpdate(_id, stockData)
      logger.info(`[STOCK] Updated: ${_id}`)
      return { clientId, status: 'success', serverId: _id }
    }

    case 'delete': {
      await StockItem.findByIdAndUpdate(_id, { isActive: false })
      logger.info(`[STOCK] Soft deleted: ${_id}`)
      return { clientId, status: 'success', serverId: _id }
    }

    default:
      return { clientId, status: 'error', error: `Unknown operation: ${op}` }
  }
}

/**
 * Process transaction operation with conflict resolution
 */
async function processTransactionOperation (op, data, companyId, userId, clientId, lastSyncTime) {
  const { _id, ...txData } = data

  switch (op) {
    case 'create':
      const newTx = await Transaction.create({
        _id,
        ...txData,
        companyId,
        createdBy: userId
      })
      logger.info(`[TRANSACTION] Created: ${_id}`)
      return { clientId, status: 'success', serverId: newTx._id }

    case 'update': {
      const existing = await Transaction.findById(_id)

      if (!existing) {
        const created = await Transaction.create({
          _id,
          ...txData,
          companyId,
          createdBy: userId
        })
        logger.info(`[TRANSACTION] Created (didn't exist): ${_id}`)
        return { clientId, status: 'success', serverId: created._id }
      }

      // Check for conflict
      const hasConflict = ConflictResolver.detectConflict(existing, txData, lastSyncTime)

      if (hasConflict) {
        logger.warn(`[TRANSACTION] Conflict detected: ${_id}`)
        const resolved = ConflictResolver.mergeTransaction(existing, txData, lastSyncTime)
        await Transaction.findByIdAndUpdate(_id, resolved)
        return { clientId, status: 'conflict', serverId: _id, resolution: 'merged' }
      }

      await Transaction.findByIdAndUpdate(_id, txData)
      logger.info(`[TRANSACTION] Updated: ${_id}`)
      return { clientId, status: 'success', serverId: _id }
    }

    case 'delete': {
      await Transaction.findByIdAndUpdate(_id, { isActive: false })
      logger.info(`[TRANSACTION] Soft deleted: ${_id}`)
      return { clientId, status: 'success', serverId: _id }
    }

    default:
      return { clientId, status: 'error', error: `Unknown operation: ${op}` }
  }
}

/**
 * Process milling record operation
 */
async function processMillingOperation (op, data, companyId, userId, clientId, lastSyncTime) {
  const { _id, ...millingData } = data

  switch (op) {
    case 'create':
      const newMilling = await MillingRecord.create({
        _id,
        ...millingData,
        companyId,
        createdBy: userId
      })
      logger.info(`[MILLING] Created: ${_id}`)
      return { clientId, status: 'success', serverId: newMilling._id }

    case 'update': {
      const existing = await MillingRecord.findById(_id)

      if (!existing) {
        const created = await MillingRecord.create({
          _id,
          ...millingData,
          companyId,
          createdBy: userId
        })
        logger.info(`[MILLING] Created (didn't exist): ${_id}`)
        return { clientId, status: 'success', serverId: created._id }
      }

      const hasConflict = ConflictResolver.detectConflict(existing, millingData, lastSyncTime)

      if (hasConflict) {
        logger.warn(`[MILLING] Conflict detected: ${_id}`)
        const resolved = ConflictResolver.resolveConflict(existing, millingData, lastSyncTime, 'MillingRecord')
        await MillingRecord.findByIdAndUpdate(_id, resolved)
        return { clientId, status: 'conflict', serverId: _id, resolution: 'merged' }
      }

      await MillingRecord.findByIdAndUpdate(_id, millingData)
      logger.info(`[MILLING] Updated: ${_id}`)
      return { clientId, status: 'success', serverId: _id }
    }

    case 'delete': {
      await MillingRecord.findByIdAndUpdate(_id, { isActive: false })
      logger.info(`[MILLING] Soft deleted: ${_id}`)
      return { clientId, status: 'success', serverId: _id }
    }

    default:
      return { clientId, status: 'error', error: `Unknown operation: ${op}` }
  }
}

module.exports = router
