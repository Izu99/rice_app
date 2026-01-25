const mongoose = require('mongoose')

// Handle uncaught exceptions
process.on('uncaughtException', (err) => {
  console.error('❌ UNCAUGHT EXCEPTION! Shutting down...')
  console.error(err.name, err.message)
  process.exit(1)
})

// Handle unhandled promise rejections
process.on('unhandledRejection', (err) => {
  console.error('❌ UNHANDLED REJECTION! Shutting down...')
  console.error(err)
  process.exit(1)
})

// Database connection function with retry/backoff
const connectDB = async ({
  maxRetries = 5,
  initialDelayMs = 2000
} = {}) => {
  const uri = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/ricemill'
  const options = {
    useNewUrlParser: true,
    useUnifiedTopology: true,
    maxPoolSize: 10,
    minPoolSize: 5,
    maxIdleTimeMS: 30000,
    serverSelectionTimeoutMS: 5000,
    socketTimeoutMS: 45000,
    retryWrites: true,
    retryReads: true
  }

  let attempt = 0
  while (attempt < maxRetries) {
    try {
      attempt++
      const conn = await mongoose.connect(uri, options)
      console.log(`✅ MongoDB Connected: ${conn.connection.host}`)

      // Handle connection events
      mongoose.connection.on('connected', () => console.log('📊 Mongoose connected to MongoDB'))
      mongoose.connection.on('error', (err) => console.error('❌ MongoDB connection error:', err))
      mongoose.connection.on('disconnected', () => console.log('📊 Mongoose disconnected from MongoDB'))

      // Graceful shutdown handlers
      process.on('SIGINT', async () => {
        console.log('📊 Received SIGINT, closing MongoDB connection...')
        await mongoose.connection.close()
        process.exit(0)
      })

      process.on('SIGTERM', async () => {
        console.log('📊 Received SIGTERM, closing MongoDB connection...')
        await mongoose.connection.close()
        process.exit(0)
      })

      return conn
    } catch (error) {
      console.error(`❌ Database connection attempt ${attempt} failed:`, error.message)
      if (attempt >= maxRetries) {
        console.error('💡 Make sure MongoDB is running and MONGODB_URI is set correctly')
        throw error
      }

      const delay = initialDelayMs * Math.pow(2, attempt - 1)
      console.log(`🔄 Retrying database connection in ${delay}ms... (attempt ${attempt + 1}/${maxRetries})`)
      await new Promise(resolve => setTimeout(resolve, delay))
    }
  }
}

// Health check function
const checkDBHealth = async () => {
  try {
    const db = mongoose.connection.db
    await db.admin().ping()
    return { status: 'healthy', message: 'Database is responding' }
  } catch (error) {
    return { status: 'unhealthy', message: error.message }
  }
}

module.exports = { connectDB, checkDBHealth }
