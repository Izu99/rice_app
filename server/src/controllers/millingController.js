const MillingRecord = require('../models/MillingRecord')
const StockItem = require('../models/StockItem')
const { validationResult } = require('express-validator')
const { errorResponse, successResponse } = require('../utils/responseHandler')
const mongoose = require('mongoose')

/**
 * @desc    Get all milling records with filtering and pagination
 * @route   GET /api/milling
 * @access  Private (Company users)
 */
exports.getMillingRecords = async (req, res) => {
  try {
    const {
      startDate,
      endDate,
      status,
      page = 1,
      limit = 20,
      sortBy = 'millingDate',
      sortOrder = 'desc'
    } = req.query

    // Build query with company filter
    const query = { ...req.companyFilter }

    if (status) {
      query.status = status
    }

    if (startDate || endDate) {
      query.millingDate = {}
      if (startDate) query.millingDate.$gte = new Date(startDate)
      if (endDate) query.millingDate.$lte = new Date(endDate)
    }

    // Build sort
    const sort = {}
    sort[sortBy] = sortOrder === 'desc' ? -1 : 1

    // Get milling records
    const records = await MillingRecord.find(query)
      .populate('paddyItemId', 'name')
      .populate('riceItemId', 'name')
      .populate('milledBy', 'name')
      .sort(sort)
      .limit(limit * 1)
      .skip((page - 1) * limit)

    // Calculate summary
    const summaryStats = await MillingRecord.aggregate([
      { $match: query },
      {
        $group: {
          _id: null,
          totalBatches: { $sum: 1 },
          totalPaddyProcessed: { $sum: '$inputPaddyKg' },
          totalRiceProduced: { $sum: '$outputRiceKg' },
          avgEfficiency: { $avg: '$actualPercentage' }
        }
      }
    ])

    const summary = summaryStats[0] || {
      totalBatches: 0,
      totalPaddyProcessed: 0,
      totalRiceProduced: 0,
      avgEfficiency: 0
    }

    const total = await MillingRecord.countDocuments(query)
    const pages = Math.ceil(total / limit)

    const data = {
      records: records.map(record => ({
        ...record.toObject(),
        summary: record.getSummary()
      })),
      summary,
      pagination: {
        total,
        page: parseInt(page),
        limit: parseInt(limit),
        pages
      }
    }

    return successResponse(res, 'Milling records retrieved successfully', data)
  } catch (error) {
    console.error('Get Milling Records Error:', error)
    return errorResponse(res, 'Error retrieving milling records', 500, error.message)
  }
}

/**
 * @desc    Get single milling record
 * @route   GET /api/milling/:id
 * @access  Private (Company users)
 */
exports.getMillingRecordById = async (req, res) => {
  try {
    const record = await MillingRecord.findOne({
      _id: req.params.id,
      ...req.companyFilter
    })
      .populate('paddyItemId', 'name totalWeightKg')
      .populate('riceItemId', 'name totalWeightKg')
      .populate('milledBy', 'name')

    if (!record) {
      return errorResponse(res, 'Milling record not found', 404)
    }

    const data = {
      record,
      summary: record.getSummary(),
      recoveryDetails: record.getRecoveryDetails()
    }

    return successResponse(res, 'Milling record retrieved successfully', data)
  } catch (error) {
    console.error('Get Milling Record Error:', error)
    return errorResponse(res, 'Error retrieving milling record', 500, error.message)
  }
}

/**
 * @desc    Create milling record (process paddy to rice)
 * @route   POST /api/milling
 * @access  Private (Company users)
 */
exports.createMillingRecord = async (req, res) => {
  const session = await mongoose.startSession()
  session.startTransaction()

  try {
    const errors = validationResult(req)
    if (!errors.isEmpty()) {
      return errorResponse(res, 'Validation failed', 400, errors.array())
    }

    const {
      paddyItemId,
      inputPaddyKg,
      inputPaddyBags,
      outputRiceKg,
      outputRiceBags,
      brokenRiceKg = 0,
      huskKg = 0,
      millingPercentage,
      outputRiceName,
      notes,
      millingDate,
      clientId,
      status = 'completed' // Default to completed for backward compatibility
    } = req.body

    // Verify paddy item exists and has sufficient stock
    const paddyItem = await StockItem.findOne({
      _id: paddyItemId,
      itemType: 'paddy',
      ...req.companyFilter
    }).session(session)

    if (!paddyItem) {
      return errorResponse(res, 'Paddy item not found', 404)
    }

    if (paddyItem.totalWeightKg < inputPaddyKg) {
      return errorResponse(res, 'Insufficient paddy stock', 400, {
        requested: inputPaddyKg,
        available: paddyItem.totalWeightKg
      })
    }

    // Generate batch number
    const batchNumber = MillingRecord.generateBatchNumber(new Date(millingDate))

    // Deduct paddy from stock (Happens immediately regardless of status)
    const paddyDeducted = paddyItem.totalWeightKg
    await paddyItem.updateStock(inputPaddyKg, inputPaddyBags || 0, 'subtract')

    let riceItem = null
    let wastageKg = 0

    // Only process output if status is completed
    if (status === 'completed') {
      if (outputRiceKg === undefined || outputRiceBags === undefined) {
        throw new Error('Output rice details are required for completed milling')
      }

      // Calculate wastage
      const totalOutput = outputRiceKg + brokenRiceKg + huskKg
      wastageKg = inputPaddyKg - totalOutput

      // Create or update rice stock item
      riceItem = await StockItem.findOne({
        name: outputRiceName,
        itemType: 'rice',
        ...req.companyFilter
      }).session(session)

      if (riceItem) {
        // Update existing rice item
        await riceItem.updateStock(outputRiceKg, outputRiceBags || 0, 'add')
      } else {
        // Create new rice item
        riceItem = await StockItem.create([{
          name: outputRiceName,
          itemType: 'rice',
          totalWeightKg: outputRiceKg,
          totalBags: outputRiceBags || 0,
          pricePerKg: 0, // Will be set when selling
          companyId: req.companyId
        }], { session })
        riceItem = riceItem[0]
      }
    }

    // Create milling record
    const millingRecord = await MillingRecord.create([{
      batchNumber,
      paddyItemId,
      paddyItemName: paddyItem.name,
      inputPaddyKg,
      inputPaddyBags: inputPaddyBags || 0,
      outputRiceKg: status === 'completed' ? outputRiceKg : undefined,
      outputRiceBags: status === 'completed' ? (outputRiceBags || 0) : undefined,
      brokenRiceKg: status === 'completed' ? brokenRiceKg : 0,
      huskKg: status === 'completed' ? huskKg : 0,
      wastageKg: status === 'completed' ? wastageKg : 0,
      millingPercentage: status === 'completed' ? millingPercentage : undefined,
      riceItemId: riceItem ? riceItem._id : undefined,
      companyId: req.companyId,
      milledBy: req.user.id,
      notes,
      millingDate: new Date(millingDate),
      clientId,
      status
    }], { session })

    await session.commitTransaction()

    const data = {
      millingRecord: millingRecord[0],
      paddyDeducted: {
        itemId: paddyItem._id,
        itemName: paddyItem.name,
        previousKg: paddyDeducted,
        deductedKg: inputPaddyKg,
        newKg: paddyItem.totalWeightKg
      },
      riceAdded: riceItem ? {
        itemId: riceItem._id,
        itemName: outputRiceName,
        addedKg: outputRiceKg,
        totalKg: riceItem.totalWeightKg
      } : null,
      summary: millingRecord[0].getSummary()
    }

    return successResponse(res, 'Milling process initiated successfully', data, 201)
  } catch (error) {
    await session.abortTransaction()
    console.error('Create Milling Record Error:', error)
    return errorResponse(res, 'Error processing milling', 500, error.message)
  } finally {
    session.endSession()
  }
}

/**
 * @desc    Complete milling process (add rice stock)
 * @route   PUT /api/milling/:id/complete
 * @access  Private (Company users)
 */
exports.completeMillingRecord = async (req, res) => {
  const session = await mongoose.startSession()
  session.startTransaction()

  try {
    const { id } = req.params
    const {
      outputRiceKg,
      outputRiceBags,
      brokenRiceKg = 0,
      huskKg = 0,
      outputRiceName,
      millingPercentage
    } = req.body

    const millingRecord = await MillingRecord.findOne({
      _id: id,
      ...req.companyFilter
    }).session(session)

    if (!millingRecord) {
      return errorResponse(res, 'Milling record not found', 404)
    }

    if (millingRecord.status === 'completed') {
      return errorResponse(res, 'Milling record is already completed', 400)
    }

    // Calculate wastage
    const totalOutput = outputRiceKg + brokenRiceKg + huskKg
    const wastageKg = millingRecord.inputPaddyKg - totalOutput

    // Create or update rice stock item
    let riceItem = await StockItem.findOne({
      name: outputRiceName,
      itemType: 'rice',
      ...req.companyFilter
    }).session(session)

    if (riceItem) {
      // Update existing rice item
      await riceItem.updateStock(outputRiceKg, outputRiceBags || 0, 'add')
    } else {
      // Create new rice item
      riceItem = await StockItem.create([{
        name: outputRiceName,
        itemType: 'rice',
        totalWeightKg: outputRiceKg,
        totalBags: outputRiceBags || 0,
        pricePerKg: 0,
        companyId: req.companyId
      }], { session })
      riceItem = riceItem[0]
    }

    // Update milling record
    millingRecord.outputRiceKg = outputRiceKg
    millingRecord.outputRiceBags = outputRiceBags
    millingRecord.brokenRiceKg = brokenRiceKg
    millingRecord.huskKg = huskKg
    millingRecord.wastageKg = wastageKg
    millingRecord.millingPercentage = millingPercentage
    millingRecord.riceItemId = riceItem._id
    millingRecord.status = 'completed'
    // Recalculate actual percentage
    if (millingRecord.inputPaddyKg > 0) {
      millingRecord.actualPercentage = (outputRiceKg / millingRecord.inputPaddyKg) * 100
    }

    await millingRecord.save({ session })
    await session.commitTransaction()

    return successResponse(res, 'Milling process completed successfully', {
      millingRecord,
      riceAdded: {
        itemId: riceItem._id,
        itemName: riceItem.name,
        addedKg: outputRiceKg,
        totalKg: riceItem.totalWeightKg
      }
    })

  } catch (error) {
    await session.abortTransaction()
    console.error('Complete Milling Error:', error)
    return errorResponse(res, 'Error completing milling', 500, error.message)
  } finally {
    session.endSession()
  }
}

/**
 * @desc    Get milling statistics
 * @route   GET /api/milling/statistics
 * @access  Private (Company users)
 */
exports.getMillingStatistics = async (req, res) => {
  try {
    const { startDate, endDate } = req.query

    // Build date filter
    const dateFilter = { ...req.companyFilter }
    if (startDate || endDate) {
      dateFilter.millingDate = {}
      if (startDate) dateFilter.millingDate.$gte = new Date(startDate)
      if (endDate) dateFilter.millingDate.$lte = new Date(endDate)
    }

    // Get overall statistics
    const overallStats = await MillingRecord.aggregate([
      { $match: dateFilter },
      {
        $group: {
          _id: null,
          totalBatches: { $sum: 1 },
          totalPaddyKg: { $sum: '$inputPaddyKg' },
          totalRiceKg: { $sum: '$outputRiceKg' },
          totalBrokenRiceKg: { $sum: '$brokenRiceKg' },
          totalHuskKg: { $sum: '$huskKg' },
          totalWastageKg: { $sum: '$wastageKg' },
          avgEfficiency: { $avg: '$actualPercentage' },
          avgExpectedEfficiency: { $avg: '$millingPercentage' }
        }
      }
    ])

    // Get monthly breakdown
    const monthlyData = await MillingRecord.aggregate([
      { $match: dateFilter },
      {
        $group: {
          _id: {
            year: { $year: '$millingDate' },
            month: { $month: '$millingDate' }
          },
          batches: { $sum: 1 },
          paddyKg: { $sum: '$inputPaddyKg' },
          riceKg: { $sum: '$outputRiceKg' },
          efficiency: { $avg: '$actualPercentage' }
        }
      },
      {
        $project: {
          period: {
            $concat: [
              { $toString: '$_id.year' },
              '-',
              {
                $cond: {
                  if: { $lt: ['$_id.month', 10] },
                  then: { $concat: ['0', { $toString: '$_id.month' }] },
                  else: { $toString: '$_id.month' }
                }
              }
            ]
          },
          batches: 1,
          paddyKg: 1,
          riceKg: 1,
          efficiency: 1
        }
      },
      { $sort: { period: 1 } }
    ])

    // Get top performing batches
    const topBatches = await MillingRecord.find(dateFilter)
      .sort({ actualPercentage: -1 })
      .limit(5)
      .select('batchNumber actualPercentage inputPaddyKg outputRiceKg millingDate')

    const stats = overallStats[0] || {
      totalBatches: 0,
      totalPaddyKg: 0,
      totalRiceKg: 0,
      totalBrokenRiceKg: 0,
      totalHuskKg: 0,
      totalWastageKg: 0,
      avgEfficiency: 0,
      avgExpectedEfficiency: 0
    }

    // Calculate additional metrics
    const totalOutputKg = stats.totalRiceKg + stats.totalBrokenRiceKg + stats.totalHuskKg + stats.totalWastageKg
    const overallRecovery = stats.totalPaddyKg > 0 ? (totalOutputKg / stats.totalPaddyKg) * 100 : 0

    const data = {
      overview: {
        totalBatches: stats.totalBatches,
        totalPaddyProcessed: stats.totalPaddyKg,
        totalRiceProduced: stats.totalRiceKg,
        totalBrokenRice: stats.totalBrokenRiceKg,
        totalHusk: stats.totalHuskKg,
        totalWastage: stats.totalWastageKg,
        overallRecovery,
        averageEfficiency: stats.avgEfficiency,
        expectedEfficiency: stats.avgExpectedEfficiency
      },
      monthlyData,
      topBatches,
      performance: {
        efficiencyVariance: stats.avgEfficiency - stats.avgExpectedEfficiency,
        recoveryRate: overallRecovery,
        productivity: stats.totalPaddyKg > 0 ? stats.totalRiceKg / stats.totalBatches : 0
      }
    }

    return successResponse(res, 'Milling statistics retrieved successfully', data)
  } catch (error) {
    console.error('Get Milling Statistics Error:', error)
    return errorResponse(res, 'Error retrieving milling statistics', 500, error.message)
  }
}
