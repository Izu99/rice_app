require('dotenv').config()

// Import required modules
const app = require('./app')
const { connectDB } = require('./config/database')

// Environment variables validation
const requiredEnvVars = [
  'NODE_ENV',
  'PORT',
  'MONGODB_URI',
  'JWT_SECRET',
  'JWT_EXPIRE'
]

const missingVars = requiredEnvVars.filter(varName => !process.env[varName])
if (missingVars.length > 0) {
  console.error('❌ Missing required environment variables:')
  missingVars.forEach(varName => console.error(`   - ${varName}`))
  console.error('💡 Please check your .env file or environment configuration')
  process.exit(1)
}

// Validate critical security settings
if (process.env.JWT_SECRET.length < 32) {
  console.warn('⚠️  WARNING: JWT_SECRET should be at least 32 characters long for security')
}

// Server configuration
const PORT = process.env.PORT || 5000
const NODE_ENV = process.env.NODE_ENV || 'development'

// Start server function
const startServer = async () => {
  try {
    // Connect to database
    console.log('🔄 Connecting to database...')
    await connectDB()

    // Database seeding is now handled manually via setup endpoints or script

    // Start HTTP server
    const server = app.listen(PORT, () => {
      console.log('🚀 ============================================')
      console.log(`🚀 Server running in ${NODE_ENV} mode`)
      console.log(`🚀 Port: ${PORT}`)
      console.log(`🚀 API: http://localhost:${PORT}/api`)
      console.log(`🚀 Health Check: http://localhost:${PORT}/api/health`)
      console.log(`🚀 Version Info: http://localhost:${PORT}/api/version`)
      console.log('🚀 ============================================')

      // Additional startup information
      if (NODE_ENV === 'development') {
        console.log('📝 Development mode features:')
        console.log('   - Request logging enabled')
        console.log('   - CORS allows all origins')
        console.log('   - Detailed error messages')
        console.log('   - Admin auto-seeding enabled via seeder script')
      }
    })

    // Handle server errors
    server.on('error', (error) => {
      console.error('❌ Server startup error:', error)
      process.exit(1)
    })

    // Graceful shutdown handling
    const gracefulShutdown = async (signal) => {
      console.log(`📊 Received ${signal}, initiating graceful shutdown...`)

      server.close(async () => {
        console.log('✅ HTTP server closed')

        // Close database connection
        try {
          const mongoose = require('mongoose')
          await mongoose.connection.close()
          console.log('✅ Database connection closed')
        } catch (error) {
          console.error('❌ Error closing database connection:', error)
        }

        console.log('👋 Graceful shutdown completed')
        process.exit(0)
      })

      // Force shutdown after 30 seconds
      setTimeout(() => {
        console.error('💥 Forced shutdown after timeout')
        process.exit(1)
      }, 30000)
    }

    // Register shutdown handlers
    process.on('SIGTERM', () => gracefulShutdown('SIGTERM'))
    process.on('SIGINT', () => gracefulShutdown('SIGINT'))

    // Handle unhandled promise rejections
    process.on('unhandledRejection', (reason, promise) => {
      console.error('❌ Unhandled Rejection at:', promise, 'reason:', reason)
      // Don't exit in production, just log
      if (NODE_ENV === 'production') {
        console.error('💥 Critical error in production - continuing operation')
      } else {
        process.exit(1)
      }
    })

    // Handle uncaught exceptions
    process.on('uncaughtException', (error) => {
      console.error('❌ Uncaught Exception:', error)
      process.exit(1)
    })

    return server
  } catch (error) {
    console.error('❌ Failed to start server:', error)
    process.exit(1)
  }
}

// Handle startup in different environments
if (require.main === module) {
  // Direct execution (npm start)
  startServer()
} else {
  // Imported as module (for testing)
  module.exports = { startServer }
}
