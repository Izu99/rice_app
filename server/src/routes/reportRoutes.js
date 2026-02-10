const express = require('express')
const router = express.Router()
const reportController = require('../controllers/reportController')
const auth = require('../middleware/auth')
const companyGuard = require('../middleware/companyGuard')

// Apply authentication and company isolation to all routes
router.use(auth)
router.use(companyGuard)

/**
 * @route   GET /api/reports/dashboard
 * @desc    Main dashboard data for company overview
 */
router.get('/dashboard', reportController.getDashboard)

/**
 * @route   GET /api/reports/daily
 * @desc    Daily transaction and stock report
 */
router.get('/daily', reportController.getDailyReport)

/**
 * @route   GET /api/reports/monthly
 * @desc    Monthly transaction and performance report
 */
router.get('/monthly', reportController.getMonthlyReport)

/**
 * @route   GET /api/reports/stock
 * @desc    Comprehensive stock report
 */
router.get('/stock', reportController.getStockReport)

/**
 * @route   GET /api/reports/customer/:id
 * @desc    Customer-specific transaction report
 */
router.get('/customer/:id', reportController.getCustomerReport)

/**
 * @route   GET /api/reports/profit-loss
 * @desc    Profit and loss report
 */
router.get('/profit-loss', reportController.getProfitLossReport)

// Legacy / Helper routes (mapping to existing controller methods or placeholders)
router.get('/daily-summary', reportController.getDailyReport)
router.get('/monthly-summary', reportController.getMonthlyReport)

module.exports = router