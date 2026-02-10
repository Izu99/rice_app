const mongoose = require('mongoose')
const Transaction = require('../models/Transaction')
const StockItem = require('../models/StockItem')
const Customer = require('../models/Customer')
const MillingRecord = require('../models/MillingRecord')
const Expense = require('../models/Expense')
const Company = require('../models/Company')
const { errorResponse, successResponse } = require('../utils/responseHandler')

/**
 * @desc    Get dashboard data for company
 * @route   GET /api/reports/dashboard
 * @access  Private (Company users)
 */
exports.getDashboard = async (req, res) => {
  try {
    const rawCompanyId = req.companyId || req.user.companyId
    const companyId = new mongoose.Types.ObjectId(rawCompanyId)
    const companyFilter = { companyId }

    console.log(`🔍 [Dashboard] Loading for Company ID: ${companyId}`)

    // Today's data
    const today = new Date()
    today.setHours(0, 0, 0, 0)
    const tomorrow = new Date(today)
    tomorrow.setDate(tomorrow.getDate() + 1)

    // Today's transactions
    const todayBuy = await Transaction.countDocuments({
      companyId,
      type: 'buy',
      transactionDate: { $gte: today, $lt: tomorrow }
    })

    const todaySell = await Transaction.countDocuments({
      companyId,
      type: 'sell',
      transactionDate: { $gte: today, $lt: tomorrow }
    })

    const todayAmounts = await Transaction.aggregate([
      { 
        $match: { 
          companyId,
          transactionDate: { $gte: today, $lt: tomorrow }
        } 
      },
      {
        $group: {
          _id: '$type',
          totalAmount: { $sum: '$totalAmount' }
        }
      }
    ])

    const todayBuyAmount = todayAmounts.find(s => s._id === 'buy')?.totalAmount || 0
    const todaySellAmount = todayAmounts.find(s => s._id === 'sell')?.totalAmount || 0

    // Today's operating expenses
    const todayExpenseSummary = await Expense.aggregate([
      { 
        $match: { 
          companyId, 
          isActive: true,
          expenseDate: { $gte: today, $lt: tomorrow } 
        } 
      },
      {
        $group: {
          _id: null,
          totalAmount: { $sum: '$amount' }
        }
      }
    ])

    const todayOperatingExpenses = todayExpenseSummary[0]?.totalAmount || 0

    // This month's data
    const monthStart = new Date(today.getFullYear(), today.getMonth(), 1)

    const monthBuy = await Transaction.countDocuments({
      companyId,
      type: 'buy',
      transactionDate: { $gte: monthStart }
    })

    const monthSell = await Transaction.countDocuments({
      companyId,
      type: 'sell',
      transactionDate: { $gte: monthStart }
    })

    const monthAmounts = await Transaction.aggregate([
      { 
        $match: { 
          companyId,
          transactionDate: { $gte: monthStart }
        } 
      },
      {
        $group: {
          _id: '$type',
          totalAmount: { $sum: '$totalAmount' }
        }
      }
    ])

    const monthBuyAmount = monthAmounts.find(s => s._id === 'buy')?.totalAmount || 0
    const monthSellAmount = monthAmounts.find(s => s._id === 'sell')?.totalAmount || 0

    // Operating expenses for this month
    const expenseSummary = await Expense.aggregate([
      { 
        $match: { 
          companyId, 
          isActive: true,
          expenseDate: { $gte: monthStart } 
        } 
      },
      {
        $group: {
          _id: null,
          totalAmount: { $sum: '$amount' }
        }
      }
    ])

    const monthOperatingExpenses = expenseSummary[0]?.totalAmount || 0

    console.log('📊 [Dashboard] Results:', { todayBuy, todaySell, todayExp: todayOperatingExpenses, monthBuy: monthBuyAmount, monthSell: monthSellAmount, monthExp: monthOperatingExpenses })

    // Stock summary
    const stockSummary = await StockItem.getStockSummary(companyId)

    // Low stock count (cannot use virtual isLowStock in query)
    const lowStockCount = await StockItem.countDocuments({
      companyId,
      isActive: true,
      $expr: { $lt: ["$totalWeightKg", "$minimumStock"] }
    })

    // Recent transactions (last 5)
    const recentTransactions = await Transaction.find({ companyId })
      .populate('customerId', 'name')
      .sort({ createdAt: -1 })
      .limit(5)
      .select('transactionNumber type totalAmount paidAmount status transactionDate customerId')

    // Recent expenses (last 5)
    const recentExpenses = await Expense.find({ companyId, isActive: true })
      .sort({ expenseDate: -1 })
      .limit(5)

    // Top customers by transaction volume
    const topCustomers = await Transaction.aggregate([
      { $match: { companyId } },
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

    // Recent transactions & performance
    const performanceMetrics = await Transaction.aggregate([
      { $match: { companyId } },
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

    const data = {
      today: {
        buyTransactions: todayBuy,
        sellTransactions: todaySell,
        buyAmount: todayBuyAmount,
        sellAmount: todaySellAmount,
        operatingExpenses: todayOperatingExpenses,
        netAmount: todaySellAmount - todayBuyAmount - todayOperatingExpenses
      },
      thisMonth: {
        buyTransactions: monthBuy,
        sellTransactions: monthSell,
        buyAmount: monthBuyAmount,
        sellAmount: monthSellAmount,
        operatingExpenses: monthOperatingExpenses,
        profit: monthSellAmount - monthBuyAmount - monthOperatingExpenses
      },
      stock: {
        totalPaddyKg: stockSummary.paddy.totalKg,
        totalRiceKg: stockSummary.rice.totalKg,
        lowStockItems: lowStockCount
      },
      performance: {
        totalPaddyBoughtKg: buyMetrics.totalPaddyWeight,
        totalRiceSoldKg: sellMetrics.totalRiceWeight
      },
      recentTransactions: recentTransactions.map(t => ({
        id: t._id,
        transactionNumber: t.transactionNumber,
        type: t.type,
        customerName: t.customerId?.name || 'N/A',
        totalAmount: t.totalAmount,
        paidAmount: t.paidAmount,
        status: t.status,
        transactionDate: t.transactionDate
      })),
      recentExpenses,
      topCustomers
    }

    return successResponse(res, 'Dashboard data retrieved successfully', data)
  } catch (error) {
    console.error('Dashboard Report Error:', error)
    return errorResponse(res, 'Error retrieving dashboard data', 500, error.message)
  }
}

/**
 * @desc    Get daily transaction and stock report
 * @route   GET /api/reports/daily
 * @access  Private (Company users)
 */
exports.getDailyReport = async (req, res) => {
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
    }).populate('customerId', 'name phone')

    const sellTransactions = await Transaction.find({
      ...dateFilter,
      type: 'sell'
    }).populate('customerId', 'name phone')

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

    // Get milling data for the day
    const millingData = await MillingRecord.find({
      ...req.companyFilter,
      millingDate: { $gte: reportDate, $lt: nextDay }
    }).select('batchNumber inputPaddyKg outputRiceKg millingPercentage actualPercentage')

    // Get stock movements (simplified - would need transaction log)
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
        netCashFlow: (sellStats.cashIn || 0) - (buyStats.cashOut || 0),
        profit: (sellStats.totalAmount || 0) - (buyStats.totalAmount || 0)
      },
      milling: {
        batches: millingData.length,
        totalPaddyProcessed: millingData.reduce((sum, m) => sum + m.inputPaddyKg, 0),
        totalRiceProduced: millingData.reduce((sum, m) => sum + m.outputRiceKg, 0),
        avgEfficiency: millingData.length > 0
          ? millingData.reduce((sum, m) => sum + m.actualPercentage, 0) / millingData.length
          : 0
      },
      stockMovement
    }

    return successResponse(res, 'Daily report retrieved successfully', data)
  } catch (error) {
    console.error('Daily Report Error:', error)
    return errorResponse(res, 'Error retrieving daily report', 500, error.message)
  }
}

/**
 * @desc    Get monthly transaction and performance report
 * @route   GET /api/reports/monthly
 * @access  Private (Company users)
 */
exports.getMonthlyReport = async (req, res) => {
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

    // Milling data for the month
    const millingStats = await MillingRecord.aggregate([
      {
        $match: {
          ...req.companyFilter,
          millingDate: { $gte: monthStart, $lt: monthEnd }
        }
      },
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

    const millingData = millingStats[0] || {
      totalBatches: 0,
      totalPaddyProcessed: 0,
      totalRiceProduced: 0,
      avgEfficiency: 0
    }

    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ]

    const data = {
      month: `${monthNames[month - 1]} ${year}`,
      dailySummary: dailySummary.map(day => ({
        date: day._id,
        buyAmount: day.buyAmount,
        sellAmount: day.sellAmount,
        buyCount: day.buyCount,
        sellCount: day.sellCount,
        netAmount: day.sellAmount - day.buyAmount
      })),
      totalBuyAmount: buyTotal,
      totalSellAmount: sellTotal,
      totalProfit: sellTotal - buyTotal,
      topItems,
      topCustomers,
      milling: millingData,
      chartData: {
        buyTrend: dailySummary.map(d => ({ date: d._id, amount: d.buyAmount })),
        sellTrend: dailySummary.map(d => ({ date: d._id, amount: d.sellAmount })),
        profitTrend: dailySummary.map(d => ({
          date: d._id,
          amount: d.sellAmount - d.buyAmount
        }))
      }
    }

    return successResponse(res, 'Monthly report retrieved successfully', data)
  } catch (error) {
    console.error('Monthly Report Error:', error)
    return errorResponse(res, 'Error retrieving monthly report', 500, error.message)
  }
}

/**
 * @desc    Get comprehensive stock report
 * @route   GET /api/reports/stock
 * @access  Private (Company users)
 */
exports.getStockReport = async (req, res) => {
  try {
    // Current stock
    const currentStock = await StockItem.find({
      ...req.companyFilter,
      isActive: true
    })
      .select('name itemType totalWeightKg totalBags pricePerKg avgPurchasePrice minimumStock isLowStock')
      .sort({ itemType: 1, name: 1 })

    // Stock value calculation
    const stockValue = await StockItem.aggregate([
      { $match: { ...req.companyFilter, isActive: true } },
      {
        $group: {
          _id: null,
          totalValue: { $sum: { $multiply: ['$totalWeightKg', '$pricePerKg'] } },
          totalItems: { $sum: 1 }
        }
      }
    ])

    // Low stock alerts
    const lowStockAlerts = await StockItem.find({
      companyId,
      isActive: true,
      $expr: { $lt: ["$totalWeightKg", "$minimumStock"] }
    })
      .select('name itemType totalWeightKg minimumStock')
      .sort({ totalWeightKg: 1 })

    // Recent milling history (last 30 days)
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
      .limit(10)

    // Stock movement summary (simplified)
    const stockMovement = await Transaction.aggregate([
      {
        $match: {
          ...req.companyFilter,
          createdAt: { $gte: thirtyDaysAgo }
        }
      },
      { $unwind: '$items' },
      {
        $group: {
          _id: {
            itemName: '$items.itemName',
            itemType: '$items.itemType',
            type: '$type'
          },
          totalQuantity: { $sum: '$items.weightKg' },
          transactionCount: { $sum: 1 }
        }
      },
      {
        $project: {
          itemName: '$_id.itemName',
          itemType: '$_id.itemType',
          transactionType: '$_id.type',
          totalQuantity: 1,
          transactionCount: 1
        }
      },
      { $sort: { totalQuantity: -1 } }
    ])

    const data = {
      currentStock,
      stockValue: stockValue[0]?.totalValue || 0,
      stockMovement,
      lowStockAlerts: lowStockAlerts.map(item => ({
        name: item.name,
        itemType: item.itemType,
        currentStock: item.totalWeightKg,
        minimumStock: item.minimumStock,
        shortage: item.minimumStock - item.totalWeightKg
      })),
      millingHistory,
      summary: {
        totalItems: stockValue[0]?.totalItems || 0,
        totalValue: stockValue[0]?.totalValue || 0,
        lowStockCount: lowStockAlerts.length,
        recentMillingBatches: millingHistory.length
      }
    }

    return successResponse(res, 'Stock report retrieved successfully', data)
  } catch (error) {
    console.error('Stock Report Error:', error)
    return errorResponse(res, 'Error retrieving stock report', 500, error.message)
  }
}

/**
 * @desc    Get customer-specific transaction report
 * @route   GET /api/reports/customer/:id
 * @access  Private (Company users)
 */
exports.getCustomerReport = async (req, res) => {
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

    // Get transaction items breakdown
    const itemBreakdown = await Transaction.aggregate([
      { $match: transactionFilter },
      { $unwind: '$items' },
      {
        $group: {
          _id: '$items.itemName',
          totalQuantity: { $sum: '$items.weightKg' },
          totalValue: { $sum: '$items.totalPrice' },
          transactionCount: { $sum: 1 }
        }
      },
      { $sort: { totalValue: -1 } }
    ])

    const period = startDate && endDate
      ? `${startDate} to ${endDate}`
      : 'All time'

    const data = {
      customer: customer.getSummary(),
      period,
      transactions,
      summary: {
        totalBuy: buySummary.totalAmount || 0,
        totalSell: sellSummary.totalAmount || 0,
        balance: customer.balance,
        transactionCount: (buySummary.count || 0) + (sellSummary.count || 0),
        netAmount: (sellSummary.totalAmount || 0) - (buySummary.totalAmount || 0)
      },
      itemBreakdown
    }

    return successResponse(res, 'Customer report retrieved successfully', data)
  } catch (error) {
    console.error('Customer Report Error:', error)
    return errorResponse(res, 'Error retrieving customer report', 500, error.message)
  }
}

/**
 * @desc    Get profit and loss report
 * @route   GET /api/reports/profit-loss
 * @access  Private (Company users)
 */
exports.getProfitLossReport = async (req, res) => {
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
      {
        $match: {
          ...req.companyFilter,
          millingDate: dateFilter.transactionDate || {}
        }
      },
      {
        $group: {
          _id: null,
          totalWastage: { $sum: '$wastageKg' }
        }
      }
    ])

    const millingCost = millingCosts[0]?.totalWastage || 0 // Simplified

    // Operating expenses
    const operatingExpenseSummary = await Expense.aggregate([
      { 
        $match: { 
          ...req.companyFilter, 
          isActive: true,
          expenseDate: dateFilter.transactionDate || { $exists: true }
        } 
      },
      {
        $group: {
          _id: null,
          totalAmount: { $sum: '$amount' }
        }
      }
    ])

    const operatingExpenses = operatingExpenseSummary[0]?.totalAmount || 0

    const grossProfit = sales - purchases
    const netProfit = grossProfit - millingCost - operatingExpenses

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
          totalAmount: { $sum: '$items.totalPrice' }
        }
      },
      {
        $project: {
          category: {
            $concat: ['$_id.type', ' - ', '$_id.itemType']
          },
          totalAmount: 1
        }
      },
      { $sort: { totalAmount: -1 } }
    ])

    // Monthly profit/loss trend
    const monthlyTrend = await Transaction.aggregate([
      { $match: filter },
      {
        $group: {
          _id: {
            year: { $year: '$transactionDate' },
            month: { $month: '$transactionDate' }
          },
          purchases: {
            $sum: { $cond: [{ $eq: ['$type', 'buy'] }, '$totalAmount', 0] }
          },
          sales: {
            $sum: { $cond: [{ $eq: ['$type', 'sell'] }, '$totalAmount', 0] }
          }
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
          purchases: 1,
          sales: 1,
          profit: { $subtract: ['$sales', '$purchases'] }
        }
      },
      { $sort: { period: 1 } }
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
      breakdown,
      monthlyTrend,
      ratios: {
        profitMargin: sales > 0 ? (netProfit / sales) * 100 : 0,
        costOfGoodsSold: purchases,
        operatingExpenses: millingCost + operatingExpenses
      }
    }

    return successResponse(res, 'Profit & Loss report retrieved successfully', data)
  } catch (error) {
    console.error('Profit Loss Report Error:', error)
    return errorResponse(res, 'Error retrieving profit & loss report', 500, error.message)
  }
}
