const express = require('express')
const router = express.Router()

// Import all route modules
const authRoutes = require('./auth')
const adminRoutes = require('./adminRoutes')
const companyRoutes = require('./companyRoutes')
const customerRoutes = require('./customerRoutes')
const stockRoutes = require('./stockRoutes')
const transactionRoutes = require('./transactionRoutes')
const millingRoutes = require('./millingRoutes')
const reportRoutes = require('./reportRoutes')
const syncRoutes = require('./syncRoutes')
const paddyTypeRoutes = require('./paddyType')
const purchaseRoutes = require('./purchase')
const setupRoutes = require('./setupRoutes')

// Import middleware
const { generalLimiter, authLimiter } = require('../middleware/rateLimiter')
const logger = require('../middleware/logger')
const cors = require('../middleware/cors')

// Apply global middleware
router.use(logger)
router.use(cors)
router.use(generalLimiter)

// Health check endpoint
router.get('/health', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Rice Mill ERP API is running',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development'
  })
})

// API version info
router.get('/version', (req, res) => {
  res.status(200).json({
    success: true,
    version: '1.0.0',
    name: 'Rice Mill ERP API',
    description: 'Multi-tenant rice mill management system'
  })
})

// Authentication routes (higher rate limits allowed)
router.use('/auth', authLimiter, authRoutes)

// Admin routes (restricted to admins)
router.use('/admin', adminRoutes)

// Company management routes
router.use('/companies', companyRoutes)

// Business operation routes (require authentication and company isolation)
router.use('/customers', customerRoutes)
router.use('/stock', stockRoutes)
router.use('/transactions', transactionRoutes)
router.use('/milling', millingRoutes)
router.use('/reports', reportRoutes)
router.use('/sync', syncRoutes)
router.use('/paddy-types', paddyTypeRoutes)
router.use('/purchases', purchaseRoutes)
router.use('/setup', setupRoutes)

// 404 handler for undefined routes
router.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    message: `Route ${req.originalUrl} not found`,
    timestamp: new Date().toISOString()
  })
})

module.exports = router
