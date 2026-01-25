/**
 * Modern Conflict Resolution System
 *
 * Handles all sync conflict scenarios:
 * 1. Quantity merging (prevents 5+5=15 duplication)
 * 2. Last-write-wins with timestamp tracking
 * 3. Field-level conflict resolution
 * 4. Transaction item merging
 * 5. Soft delete handling
 * 6. Multi-device sync conflicts
 */

const logger = require('../utils/logger')

class ConflictResolver {
  /**
   * CORE: Resolve conflict between server and client data
   *
   * Strategy: Timestamp-based last-write-wins
   * - If server updated AFTER client's lastSyncTime → use server
   * - If client updated AFTER lastSyncTime → use client (new offline changes)
   * - Otherwise → use whichever is newer
   */
  static resolveConflict (serverData, clientData, lastSyncTime, entityType) {
    if (!serverData || !clientData) {
      return serverData || clientData
    }

    const serverUpdatedAt = new Date(serverData.updatedAt || serverData.createdAt)
    const clientUpdatedAt = new Date(clientData.updatedAt || clientData.createdAt)
    const lastSync = new Date(lastSyncTime)

    logger.info(`[CONFLICT] Resolving ${entityType}`, {
      serverUpdatedAt: serverUpdatedAt.toISOString(),
      clientUpdatedAt: clientUpdatedAt.toISOString(),
      lastSyncTime: lastSync.toISOString()
    })

    // Server updated AFTER client's last sync → server is authoritative
    if (serverUpdatedAt > lastSync) {
      logger.info('[CONFLICT] Server newer than lastSync, using server data')
      return { ...serverData, _conflictResolution: 'server_newer' }
    }

    // Client updated AFTER last sync → client has new offline changes
    if (clientUpdatedAt > lastSync) {
      logger.info('[CONFLICT] Client has new offline changes, using client data')
      return { ...clientData, _conflictResolution: 'client_newer' }
    }

    // Both unchanged since sync → use last-write-wins
    if (serverUpdatedAt > clientUpdatedAt) {
      logger.info('[CONFLICT] Both old, server newer, using server')
      return { ...serverData, _conflictResolution: 'last_write_wins_server' }
    }

    logger.info('[CONFLICT] Both old, client newer, using client')
    return { ...clientData, _conflictResolution: 'last_write_wins_client' }
  }

  /**
   * QUANTITY MERGE: Prevents 5 bags + 5 bags = 15 bags
   *
   * Logic:
   * - If server was updated after sync → server has the truth
   * - If client was updated after sync → client added new offline data
   * - Use the newer one, don't add them together
   */
  static mergeQuantityField (serverData, clientData, lastSyncTime, fieldName) {
    if (!serverData || !clientData) {
      return (serverData || clientData)?.[fieldName] || 0
    }

    const serverUpdatedAt = new Date(serverData.updatedAt || serverData.createdAt)
    const clientUpdatedAt = new Date(clientData.updatedAt || clientData.createdAt)
    const lastSync = new Date(lastSyncTime)

    const serverQty = serverData[fieldName] || 0
    const clientQty = clientData[fieldName] || 0

    logger.debug(`[QUANTITY MERGE] ${fieldName}`, {
      serverQty,
      clientQty,
      serverUpdatedAt: serverUpdatedAt.toISOString(),
      clientUpdatedAt: clientUpdatedAt.toISOString()
    })

    // Server updated after sync → server is source of truth
    if (serverUpdatedAt > lastSync) {
      logger.debug(`[QUANTITY] Server updated after sync, using server qty: ${serverQty}`)
      return serverQty
    }

    // Client updated after sync → client has new offline additions
    if (clientUpdatedAt > lastSync) {
      logger.debug(`[QUANTITY] Client updated after sync, using client qty: ${clientQty}`)
      return clientQty
    }

    // Both unchanged → use newer timestamp
    if (serverUpdatedAt > clientUpdatedAt) {
      logger.debug(`[QUANTITY] Both old, server newer: ${serverQty}`)
      return serverQty
    }

    logger.debug(`[QUANTITY] Both old, client newer: ${clientQty}`)
    return clientQty
  }

  /**
   * STOCK ITEM MERGE: Handle inventory conflicts
   *
   * Merges: totalBags, totalWeightKg, pricePerKg
   * Prevents duplication of quantities
   */
  static mergeStockItem (serverItem, clientItem, lastSyncTime) {
    if (!serverItem || !clientItem) {
      return serverItem || clientItem
    }

    const resolved = this.resolveConflict(serverItem, clientItem, lastSyncTime, 'StockItem')

    // Merge quantity fields safely
    const mergedItem = {
      ...resolved,
      totalBags: this.mergeQuantityField(serverItem, clientItem, lastSyncTime, 'totalBags'),
      totalWeightKg: this.mergeQuantityField(serverItem, clientItem, lastSyncTime, 'totalWeightKg'),
      pricePerKg: this.mergeQuantityField(serverItem, clientItem, lastSyncTime, 'pricePerKg'),
      updatedAt: new Date()
    }

    logger.info('[STOCK MERGE] Merged stock item', {
      id: mergedItem._id,
      totalBags: mergedItem.totalBags,
      totalWeightKg: mergedItem.totalWeightKg
    })

    return mergedItem
  }

  /**
   * TRANSACTION MERGE: Handle transaction conflicts
   *
   * Merges transaction items array without duplicates
   * Recalculates totals based on merged items
   */
  static mergeTransaction (serverTx, clientTx, lastSyncTime) {
    if (!serverTx || !clientTx) {
      return serverTx || clientTx
    }

    const resolved = this.resolveConflict(serverTx, clientTx, lastSyncTime, 'Transaction')

    // Merge items array
    const mergedItems = this.mergeTransactionItems(
      serverTx.items || [],
      clientTx.items || [],
      lastSyncTime
    )

    // Recalculate totals
    let totalWeightKg = 0
    let totalBags = 0
    let totalAmount = 0

    mergedItems.forEach(item => {
      totalWeightKg += item.weightKg || 0
      totalBags += item.bags || 0
      totalAmount += item.totalPrice || 0
    })

    const mergedTx = {
      ...resolved,
      items: mergedItems,
      totalWeightKg,
      totalBags,
      totalAmount,
      updatedAt: new Date()
    }

    logger.info('[TRANSACTION MERGE] Merged transaction', {
      id: mergedTx._id,
      itemCount: mergedItems.length,
      totalAmount
    })

    return mergedTx
  }

  /**
   * TRANSACTION ITEMS MERGE: Merge line items without duplicates
   *
   * Uses item ID to deduplicate
   * Prefers server if updated after sync, else client
   */
  static mergeTransactionItems (serverItems, clientItems, lastSyncTime) {
    const itemMap = new Map();

    // Add server items
    (serverItems || []).forEach(item => {
      const itemId = item._id?.toString() || item.id
      itemMap.set(itemId, item)
    });

    // Merge client items
    (clientItems || []).forEach(item => {
      const itemId = item._id?.toString() || item.id
      const serverItem = itemMap.get(itemId)

      if (!serverItem) {
        // New item from client
        itemMap.set(itemId, item)
      } else {
        // Item exists in both → resolve conflict
        const resolved = this.resolveConflict(serverItem, item, lastSyncTime, 'TransactionItem')
        itemMap.set(itemId, resolved)
      }
    })

    return Array.from(itemMap.values())
  }

  /**
   * CUSTOMER MERGE: Handle customer data conflicts
   *
   * Merges: balance, totalPurchased, totalSold
   * Prevents balance duplication
   */
  static mergeCustomer (serverCustomer, clientCustomer, lastSyncTime) {
    if (!serverCustomer || !clientCustomer) {
      return serverCustomer || clientCustomer
    }

    const resolved = this.resolveConflict(serverCustomer, clientCustomer, lastSyncTime, 'Customer')

    // Merge numeric fields
    const mergedCustomer = {
      ...resolved,
      balance: this.mergeQuantityField(serverCustomer, clientCustomer, lastSyncTime, 'balance'),
      totalPurchased: this.mergeQuantityField(serverCustomer, clientCustomer, lastSyncTime, 'totalPurchased'),
      totalSold: this.mergeQuantityField(serverCustomer, clientCustomer, lastSyncTime, 'totalSold'),
      updatedAt: new Date()
    }

    logger.info('[CUSTOMER MERGE] Merged customer', {
      id: mergedCustomer._id,
      balance: mergedCustomer.balance
    })

    return mergedCustomer
  }

  /**
   * SOFT DELETE HANDLING: Handle deleted records
   *
   * If either side is deleted → mark as deleted
   * Preserve deletion timestamp
   */
  static mergeSoftDelete (serverData, clientData, lastSyncTime) {
    if (!serverData || !clientData) {
      return serverData || clientData
    }

    const serverDeleted = serverData.isActive === false || serverData.isDeleted === true
    const clientDeleted = clientData.isActive === false || clientData.isDeleted === true

    // If either is deleted, mark as deleted
    if (serverDeleted || clientDeleted) {
      logger.info('[SOFT DELETE] Record marked as deleted')
      return {
        ...serverData,
        isActive: false,
        isDeleted: true,
        deletedAt: new Date()
      }
    }

    return this.resolveConflict(serverData, clientData, lastSyncTime, 'Entity')
  }

  /**
   * DETECT CONFLICT: Check if conflict exists
   *
   * Conflict exists if:
   * - Both modified after lastSyncTime
   * - Different values for same field
   */
  static detectConflict (serverData, clientData, lastSyncTime) {
    if (!serverData || !clientData) {
      return false
    }

    const serverUpdatedAt = new Date(serverData.updatedAt || serverData.createdAt)
    const clientUpdatedAt = new Date(clientData.updatedAt || clientData.createdAt)
    const lastSync = new Date(lastSyncTime)

    // Both modified after sync
    const bothModifiedAfterSync = serverUpdatedAt > lastSync && clientUpdatedAt > lastSync

    if (!bothModifiedAfterSync) {
      return false
    }

    // Check if values differ
    const serverStr = JSON.stringify(serverData)
    const clientStr = JSON.stringify(clientData)

    return serverStr !== clientStr
  }

  /**
   * VALIDATE MERGE: Sanity check merged result
   *
   * Ensures quantities don't exceed reasonable bounds
   */
  static validateMerge (original, merged, quantityFields = []) {
    const issues = []

    quantityFields.forEach(field => {
      const originalQty = original[field] || 0
      const mergedQty = merged[field] || 0

      // Merged should never be significantly more than original
      if (mergedQty > originalQty * 1.5) {
        issues.push(`${field}: merged (${mergedQty}) > original (${originalQty}) * 1.5`)
      }

      // Merged should never be negative
      if (mergedQty < 0) {
        issues.push(`${field}: merged quantity is negative (${mergedQty})`)
      }
    })

    if (issues.length > 0) {
      logger.warn('[VALIDATION] Merge validation issues:', issues)
      return false
    }

    return true
  }

  /**
   * RESOLVE BY ENTITY TYPE: Main entry point
   *
   * Routes to appropriate merge function based on entity type
   */
  static resolveByType (entityType, serverData, clientData, lastSyncTime) {
    logger.info(`[RESOLVE] Resolving ${entityType} conflict`)

    switch (entityType) {
      case 'stock_item':
      case 'StockItem':
        return this.mergeStockItem(serverData, clientData, lastSyncTime)

      case 'transaction':
      case 'Transaction':
        return this.mergeTransaction(serverData, clientData, lastSyncTime)

      case 'customer':
      case 'Customer':
        return this.mergeCustomer(serverData, clientData, lastSyncTime)

      default:
        return this.resolveConflict(serverData, clientData, lastSyncTime, entityType)
    }
  }
}

module.exports = ConflictResolver
