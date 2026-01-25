const express = require('express')
const cors = require('cors')
const helmet = require('helmet')
const compression = require('compression')
const mongoSanitize = require('express-mongo-sanitize')
const hpp = require('hpp')

// Import routes
const routes = require('./routes')

// Import middleware
const errorHandler = require('./middleware/errorHandler')

// Create Express app
const app = express()

// Security middleware (Modern)
app.use(helmet()) // Set security HTTP headers
app.use(mongoSanitize()) // Prevent NoSQL injection
app.use(hpp()) // Prevent HTTP parameter pollution
app.disable('x-powered-by') // Hide Express version

// Performance middleware
app.use(compression()) // Compress all responses

// Body parsing middleware
app.use(express.json({ limit: '10mb' }))
app.use(express.urlencoded({ extended: true, limit: '10mb' }))

// CORS configuration
app.use(cors({
  origin: process.env.NODE_ENV === 'production'
    ? process.env.FRONTEND_URL || false
    : true, // Allow all origins in development
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
}))

// Trust proxy for accurate IP logging
app.set('trust proxy', 1)

// API Routes (all routes are now handled by the index router)
app.use('/api', routes)

// Global error handler (must be last)
app.use(errorHandler)

module.exports = app
