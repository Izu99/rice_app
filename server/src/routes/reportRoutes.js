const express = require('express')
const router = express.Router()
const auth = require('../middleware/auth')
const companyGuard = require('../middleware/companyGuard')
const { errorResponse, successResponse } = require('../utils/responseHandler')

// Import models
const Transaction = require('../models/Transaction')
const Customer = require('../models/Customer')
const StockItem = require('../models/StockItem')
const MillingRecord = require('../models/MillingRecord')

// Apply authentication and company isolation to all routes
router.use(auth)
router.use(companyGuard)

/**
 * @route   GET /api/reports/dashboard
 * @desc    Main dashboard data for company overview
 * @access  Private (Company users)
 */
router.get('/dashboard', async (req, res) => {
  try {
    const companyFilter = req.companyFilter

    // Today's data
    const today = new Date()
    today.setHours(0, 0, 0, 0)
    const tomorrow = new Date(today)
    tomorrow.setDate(tomorrow.getDate() + 1)

    const todayFilter = {
      ...companyFilter,
      transactionDate: { $gte: today, $lt: tomorrow }
    }

    // Today's transactions
    const todayBuy = await Transaction.find({
      ...todayFilter,
      type: 'buy'
    }).countDocuments()

    const todaySell = await Transaction.find({
      ...todayFilter,
      type: 'sell'
    }).countDocuments()

    const todayBuyAmount = await Transaction.aggregate([
      { $match: { ...todayFilter, type: 'buy' } },
      { $group: { _id: null, total: { $sum: '$totalAmount' } } }
    ])

    const todaySellAmount = await Transaction.aggregate([
      { $match: { ...todayFilter, type: 'sell' } },
      { $group: { _id: null, total: { $sum: '$totalAmount' } } }
    ])

    // This month's data
    const monthStart = new Date(today.getFullYear(), today.getMonth(), 1)
    const monthFilter = {
      ...companyFilter,
      transactionDate: { $gte: monthStart }
    }

    const monthBuy = await Transaction.find({
      ...monthFilter,
      type: 'buy'
    }).countDocuments()

    const monthSell = await Transaction.find({
      ...monthFilter,
      type: 'sell'
    }).countDocuments()

    const monthBuyAmount = await Transaction.aggregate([
      { $match: { ...monthFilter, type: 'buy' } },
      { $group: { _id: null, total: { $sum: '$totalAmount' } } }
    ])

    const monthSellAmount = await Transaction.aggregate([
      { $match: { ...monthFilter, type: 'sell' } },
      { $group: { _id: null, total: { $sum: '$totalAmount' } } }
    ])

    // Stock summary
    const stockSummary = await StockItem.aggregate([
      { $match: companyFilter },
      {
        $group: {
          _id: '$itemType',
          totalKg: { $sum: '$totalWeightKg' }
        }
      }
    ])

    const paddyStock = stockSummary.find(s => s._id === 'paddy')?.totalKg || 0
    const riceStock = stockSummary.find(s => s._id === 'rice')?.totalKg || 0
    const lowStockCount = await StockItem.countDocuments({
      ...companyFilter,
      isLowStock: true
    })

    // Performance metrics calculation
    const performanceMetrics = await Transaction.aggregate([
      { $match: companyFilter },
      { $unwind: "$items" },
      {
        $group: {
          _id: "$type",
          totalPaddyWeight: { 
            $sum: { $cond: [{ $eq: ["$items.itemType", "paddy"] }, "$items.weightKg", 0] } 
          },
          totalRiceWeight: { 
            $sum: { $cond: [{ $eq: ["$items.itemType", "rice"] }, "$items.weightKg", 0] } 
          }
        }
      }
    ])

    const buyMetrics = performanceMetrics.find(m => m._id === 'buy') || { totalPaddyWeight: 0 }
    const sellMetrics = performanceMetrics.find(m => m._id === 'sell') || { totalRiceWeight: 0 }

    // Recent transactions (last 5)
    const recentTransactions = await Transaction.find(companyFilter)
      .populate('customerId', 'name')
      .sort({ createdAt: -1 })
      .limit(5)
      .select('transactionNumber type totalAmount paidAmount status transactionDate')

    // Last 7 days trend
    const sevenDaysAgo = new Date(today)
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 6) // Go back 6 days to include today (7 days total)
    
    const trendFilter = {
      ...companyFilter,
      transactionDate: { $gte: sevenDaysAgo, $lt: tomorrow }
    }

    const weeklyTrend = await Transaction.aggregate([
      { $match: trendFilter },
      {
        $group: {
          _id: { $dateToString: { format: "%Y-%m-%d", date: "$transactionDate" } },
          buy: { $sum: { $cond: [{ $eq: ["$type", "buy"] }, "$totalAmount", 0] } },
          sell: { $sum: { $cond: [{ $eq: ["$type", "sell"] }, "$totalAmount", 0] } }
        }
      },
      { $sort: { _id: 1 } }
    ])

    // Fill in missing days
    const filledTrend = []
    for (let i = 0; i < 7; i++) {
      const d = new Date(sevenDaysAgo)
      d.setDate(d.getDate() + i)
      const dateStr = d.toISOString().split('T')[0]
      
      const found = weeklyTrend.find(item => item._id === dateStr)
      if (found) {
        filledTrend.push(found)
      } else {
        filledTrend.push({ _id: dateStr, buy: 0, sell: 0 })
      }
    }

    // Top customers by transaction volume
    const topCustomers = await Transaction.aggregate([
      { $match: companyFilter },
      {
        $group: {
          _id: '$customerId',
          transactionCount: { $sum: 1 },
          totalAmount: { $sum: '$totalAmount' }
        }
      },
      { $sort: { totalAmount: -1 } },
      { $limit: 5 },
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
          transactionCount: 1,
          totalAmount: 1
        }
      }
    ])

    const totalCustomers = await Customer.countDocuments(companyFilter)

    const data = {
      today: {
        buyTransactions: todayBuy,
        sellTransactions: todaySell,
        buyAmount: todayBuyAmount[0]?.total || 0,
        sellAmount: todaySellAmount[0]?.total || 0,
        profit: (todaySellAmount[0]?.total || 0) - (todayBuyAmount[0]?.total || 0)
      },
      thisMonth: {
        buyTransactions: monthBuy,
        sellTransactions: monthSell,
        buyAmount: monthBuyAmount[0]?.total || 0,
        sellAmount: monthSellAmount[0]?.total || 0,
        profit: (monthSellAmount[0]?.total || 0) - (monthBuyAmount[0]?.total || 0)
      },
      stock: {
        totalPaddyKg: paddyStock,
        totalRiceKg: riceStock,
        lowStockItems: lowStockCount
      },
      performance: {
        totalPaddyBoughtKg: buyMetrics.totalPaddyWeight,
        totalRiceSoldKg: sellMetrics.totalRiceWeight
      },
      weeklyTrend: filledTrend,
      recentTransactions,
      topCustomers,
      totalCustomers
    }

    return successResponse(res, 'Dashboard data retrieved successfully', data)
  } catch (error) {
    console.error('Dashboard Report Error:', error)
    return errorResponse(res, 'Error retrieving dashboard data', 500, error.message)
  }
})

/**
 * @route   GET /api/reports/daily-summary
 * @desc    Get transaction summary for a specific date
 * @access  Private (Company users)
 */
router.get('/daily-summary', async (req, res) => {
  try {
    const { date = new Date().toISOString().split('T')[0] } = req.query
    const reportDate = new Date(date)
    reportDate.setHours(0, 0, 0, 0)
    const nextDay = new Date(reportDate)
    nextDay.setDate(nextDay.getDate() + 1)

    const filter = {
      ...req.companyFilter,
      transactionDate: { $gte: reportDate, $lt: nextDay }
    }

    const summary = await Transaction.aggregate([
      { $match: filter },
      {
        $group: {
          _id: '$type',
          totalAmount: { $sum: '$totalAmount' },
          count: { $sum: 1 }
        }
      }
    ])

    const buyStats = summary.find(s => s._id === 'buy') || { totalAmount: 0, count: 0 }
    const sellStats = summary.find(s => s._id === 'sell') || { totalAmount: 0, count: 0 }

    const data = {
      totalBuy: buyStats.totalAmount,
      buyCount: buyStats.count,
      totalSell: sellStats.totalAmount,
      sellCount: sellStats.count,
      profit: sellStats.totalAmount - buyStats.totalAmount
    }

    return successResponse(res, 'Daily summary retrieved successfully', data)
  } catch (error) {
    console.error('Daily Summary Error:', error)
    return errorResponse(res, 'Error retrieving daily summary', 500, error.message)
  }
})

/**
 * @route   GET /api/reports/daily
 * @desc    Daily transaction and stock report
 * @access  Private (Company users)
 */
router.get('/daily', async (req, res) => {
  try {
    const { date = new Date().toISOString().split('T')[0] } = req.query
    const reportDate = new Date(date)
    const nextDay = new Date(reportDate)
    nextDay.setDate(nextDay.getDate() + 1)

    const dateFilter = {
      ...req.companyFilter,
      transactionDate: { $gte: reportDate, $lt: nextDay }
    }

    // Get transactions
    const buyTransactions = await Transaction.find({
      ...dateFilter,
      type: 'buy'
    }).populate('customerId', 'name')

    const sellTransactions = await Transaction.find({
      ...dateFilter,
      type: 'sell'
    }).populate('customerId', 'name')

    // Calculate summary
    const summary = await Transaction.aggregate([
      { $match: dateFilter },
      {
        $group: {
          _id: '$type',
          totalAmount: { $sum: '$totalAmount' },
          totalWeight: { $sum: '$totalWeightKg' },
          cashIn: {
            $sum: {
              $cond: [
                { $eq: ['$paymentMethod', 'cash'] },
                '$paidAmount',
                0
              ]
            }
          },
          cashOut: {
            $sum: {
              $cond: [
                {
                  $and: [
                    { $eq: ['$type', 'buy'] },
                    { $eq: ['$paymentMethod', 'cash'] }
                  ]
                },
                '$paidAmount',
                0
              ]
            }
          }
        }
      }
    ])

    const buyStats = summary.find(s => s._id === 'buy') || {}
    const sellStats = summary.find(s => s._id === 'sell') || {}

    // Stock movements (placeholder - would need stock transaction log)
    const stockMovement = []

    const data = {
      date,
      transactions: {
        buy: buyTransactions,
        sell: sellTransactions
      },
      summary: {
        totalBuyAmount: buyStats.totalAmount || 0,
        totalSellAmount: sellStats.totalAmount || 0,
        totalBuyWeight: buyStats.totalWeight || 0,
        totalSellWeight: sellStats.totalWeight || 0,
        cashIn: sellStats.cashIn || 0,
        cashOut: buyStats.cashOut || 0,
        netCashFlow: (sellStats.cashIn || 0) - (buyStats.cashOut || 0)
      },
      stockMovement
    }

    return successResponse(res, 'Daily report retrieved successfully', data)
  } catch (error) {
    console.error('Daily Report Error:', error)
    return errorResponse(res, 'Error retrieving daily report', 500, error.message)
  }
})

/**
 * @route   GET /api/reports/monthly-summary
 * @desc    Get transaction summary for a specific month
 * @access  Private (Company users)
 */
router.get('/monthly-summary', async (req, res) => {
  try {
    const { month = new Date().getMonth() + 1, year = new Date().getFullYear() } = req.query
    const monthStart = new Date(year, month - 1, 1)
    const monthEnd = new Date(year, month, 1)

    const filter = {
      ...req.companyFilter,
      transactionDate: { $gte: monthStart, $lt: monthEnd }
    }

    const summary = await Transaction.aggregate([
      { $match: filter },
      {
        $group: {
          _id: '$type',
          totalAmount: { $sum: '$totalAmount' },
          count: { $sum: 1 }
        }
      }
    ])

    const buyStats = summary.find(s => s._id === 'buy') || { totalAmount: 0, count: 0 }
    const sellStats = summary.find(s => s._id === 'sell') || { totalAmount: 0, count: 0 }

    const data = {
      totalBuy: buyStats.totalAmount,
      buyCount: buyStats.count,
      totalSell: sellStats.totalAmount,
      sellCount: sellStats.count,
      profit: sellStats.totalAmount - buyStats.totalAmount
    }

    return successResponse(res, 'Monthly summary retrieved successfully', data)
  } catch (error) {
    console.error('Monthly Summary Error:', error)
    return errorResponse(res, 'Error retrieving monthly summary', 500, error.message)
  }
})

/**
 * @route   GET /api/reports/monthly
 * @desc    Monthly transaction and performance report
 * @access  Private (Company users)
 */
router.get('/monthly', async (req, res) => {
  try {
    const { month = new Date().getMonth() + 1, year = new Date().getFullYear() } = req.query

    const monthStart = new Date(year, month - 1, 1)
    const monthEnd = new Date(year, month, 1)

    const monthFilter = {
      ...req.companyFilter,
      transactionDate: { $gte: monthStart, $lt: monthEnd }
    }

    // Daily summary
    const dailySummary = await Transaction.aggregate([
      { $match: monthFilter },
      {
        $group: {
          _id: {
            $dateToString: { format: '%Y-%m-%d', date: '$transactionDate' }
          },
          buyAmount: {
            $sum: { $cond: [{ $eq: ['$type', 'buy'] }, '$totalAmount', 0] }
          },
          sellAmount: {
            $sum: { $cond: [{ $eq: ['$type', 'sell'] }, '$totalAmount', 0] }
          },
          buyCount: {
            $sum: { $cond: [{ $eq: ['$type', 'buy'] }, 1, 0] }
          },
          sellCount: {
            $sum: { $cond: [{ $eq: ['$type', 'sell'] }, 1, 0] }
          }
        }
      },
      { $sort: { _id: 1 } }
    ])

    // Monthly totals
    const monthlyTotals = await Transaction.aggregate([
      { $match: monthFilter },
      {
        $group: {
          _id: '$type',
          totalAmount: { $sum: '$totalAmount' },
          count: { $sum: 1 }
        }
      }
    ])

    const buyTotal = monthlyTotals.find(t => t._id === 'buy')?.totalAmount || 0
    const sellTotal = monthlyTotals.find(t => t._id === 'sell')?.totalAmount || 0

    // Top items (by transaction volume)
    const topItems = await Transaction.aggregate([
      { $match: monthFilter },
      { $unwind: '$items' },
      {
        $group: {
          _id: '$items.itemName',
          totalQuantity: { $sum: '$items.weightKg' },
          totalValue: { $sum: '$items.totalPrice' },
          transactionCount: { $sum: 1 }
        }
      },
      { $sort: { totalValue: -1 } },
      { $limit: 10 }
    ])

    // Top customers
    const topCustomers = await Transaction.aggregate([
      { $match: monthFilter },
      {
        $group: {
          _id: '$customerId',
          totalAmount: { $sum: '$totalAmount' },
          transactionCount: { $sum: 1 }
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
          totalAmount: 1,
          transactionCount: 1
        }
      }
    ])

    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ]

    const data = {
      month: `${monthNames[month - 1]} ${year}`,
      dailySummary,
      totalBuyAmount: buyTotal,
      totalSellAmount: sellTotal,
      totalProfit: sellTotal - buyTotal,
      topItems,
      topCustomers,
      chartData: {
        buyTrend: dailySummary.map(d => ({ date: d._id, amount: d.buyAmount })),
        sellTrend: dailySummary.map(d => ({ date: d._id, amount: d.sellAmount }))
      }
    }

    return successResponse(res, 'Monthly report retrieved successfully', data)
  } catch (error) {
    console.error('Monthly Report Error:', error)
    return errorResponse(res, 'Error retrieving monthly report', 500, error.message)
  }
})

/**
 * @route   GET /api/reports/stock
 * @desc    Comprehensive stock report
 * @access  Private (Company users)
 */
router.get('/stock', async (req, res) => {
  try {
    // Current stock
    const currentStock = await StockItem.find(req.companyFilter)
      .select('name itemType totalWeightKg totalBags pricePerKg avgPurchasePrice minimumStock isLowStock')

    // Stock value
    const stockValue = await StockItem.aggregate([
      { $match: req.companyFilter },
      {
        $group: {
          _id: null,
          totalValue: { $sum: { $multiply: ['$totalWeightKg', '$pricePerKg'] } }
        }
      }
    ])

    // Low stock alerts
    const lowStockAlerts = await StockItem.find({
      ...req.companyFilter,
      isLowStock: true
    }).select('name itemType totalWeightKg minimumStock')

    // Milling history (last 30 days)
    const thirtyDaysAgo = new Date()
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30)

    const millingHistory = await MillingRecord.find({
      ...req.companyFilter,
      millingDate: { $gte: thirtyDaysAgo }
    })
      .populate('paddyItemId', 'name')
      .populate('riceItemId', 'name')
      .select('batchNumber inputPaddyKg outputRiceKg millingPercentage actualPercentage millingDate')
      .sort({ millingDate: -1 })

    // Stock movement placeholder (would need stock transaction log)
    const stockMovement = []

    const data = {
      currentStock,
      stockValue: stockValue[0]?.totalValue || 0,
      stockMovement,
      lowStockAlerts,
      millingHistory
    }

    return successResponse(res, 'Stock report retrieved successfully', data)
  } catch (error) {
    console.error('Stock Report Error:', error)
    return errorResponse(res, 'Error retrieving stock report', 500, error.message)
  }
})

/**
 * @route   GET /api/reports/customer/:id
 * @desc    Customer-specific transaction report
 * @access  Private (Company users)
 */
router.get('/customer/:id', async (req, res) => {
  try {
    const { startDate, endDate } = req.query

    // Verify customer belongs to company
    const customer = await Customer.findOne({
      _id: req.params.id,
      ...req.companyFilter
    })

    if (!customer) {
      return errorResponse(res, 'Customer not found', 404)
    }

    // Build date filter
    const dateFilter = {}
    if (startDate || endDate) {
      dateFilter.transactionDate = {}
      if (startDate) dateFilter.transactionDate.$gte = new Date(startDate)
      if (endDate) dateFilter.transactionDate.$lte = new Date(endDate)
    }

    const transactionFilter = {
      customerId: req.params.id,
      ...req.companyFilter,
      ...dateFilter
    }

    // Get transactions
    const transactions = await Transaction.find(transactionFilter)
      .sort({ transactionDate: -1 })
      .select('transactionNumber type totalAmount paidAmount balance status transactionDate')

    // Calculate summary
    const summary = await Transaction.aggregate([
      { $match: transactionFilter },
      {
        $group: {
          _id: '$type',
          totalAmount: { $sum: '$totalAmount' },
          count: { $sum: 1 }
        }
      }
    ])

    const buySummary = summary.find(s => s._id === 'buy') || {}
    const sellSummary = summary.find(s => s._id === 'sell') || {}

    const data = {
      customer: {
        id: customer._id,
        name: customer.name,
        phone: customer.phone,
        customerType: customer.customerType
      },
      transactions,
      summary: {
        totalBuy: buySummary.totalAmount || 0,
        totalSell: sellSummary.totalAmount || 0,
        balance: customer.balance,
        transactionCount: (buySummary.count || 0) + (sellSummary.count || 0)
      }
    }

    return successResponse(res, 'Customer report retrieved successfully', data)
  } catch (error) {
    console.error('Customer Report Error:', error)
    return errorResponse(res, 'Error retrieving customer report', 500, error.message)
  }
})

/**
 * @route   GET /api/reports/profit-loss
 * @desc    Profit and loss report
 * @access  Private (Company users)
 */
router.get('/profit-loss', async (req, res) => {
  try {
    const { startDate, endDate } = req.query

    // Build date filter
    const dateFilter = {}
    if (startDate || endDate) {
      dateFilter.transactionDate = {}
      if (startDate) dateFilter.transactionDate.$gte = new Date(startDate)
      if (endDate) dateFilter.transactionDate.$lte = new Date(endDate)
    }

    const filter = {
      ...req.companyFilter,
      ...dateFilter
    }

    // Calculate revenues and costs
    const transactionSummary = await Transaction.aggregate([
      { $match: filter },
      {
        $group: {
          _id: '$type',
          totalAmount: { $sum: '$totalAmount' }
        }
      }
    ])

    const purchases = transactionSummary.find(t => t._id === 'buy')?.totalAmount || 0
    const sales = transactionSummary.find(t => t._id === 'sell')?.totalAmount || 0

    // Milling costs (placeholder - would need actual cost tracking)
    const millingCosts = await MillingRecord.aggregate([
      { $match: { ...req.companyFilter, ...dateFilter.millingDate } },
      {
        $group: {
          _id: null,
          totalWastage: { $sum: '$wastageKg' }
        }
      }
    ])

    const millingCost = millingCosts[0]?.totalWastage || 0 // Simplified

    const grossProfit = sales - purchases
    const netProfit = grossProfit - millingCost

    // Breakdown by categories
    const breakdown = await Transaction.aggregate([
      { $match: filter },
      { $unwind: '$items' },
      {
        $group: {
          _id: {
            type: '$type',
            itemType: '$items.itemType'
          },
          totalAmount: { $sum: '$items.totalPrice' },
          totalWeight: { $sum: '$items.weightKg' }
        }
      },
      {
        $project: {
          category: {
            $concat: ['$_id.type', ' - ', '$_id.itemType']
          },
          totalAmount: 1,
          totalWeight: 1
        }
      }
    ])

    const period = startDate && endDate
      ? `${startDate} to ${endDate}`
      : 'All time'

    const data = {
      period,
      totalPurchases: purchases,
      totalSales: sales,
      grossProfit,
      millingCost,
      netProfit,
      breakdown
    }

    return successResponse(res, 'Profit & Loss report retrieved successfully', data)
  } catch (error) {
    console.error('Profit Loss Report Error:', error)
    return errorResponse(res, 'Error retrieving profit & loss report', 500, error.message)
  }
})

module.exports = router
