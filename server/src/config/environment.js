require('dotenv').config()

const environment = {
  // Server Configuration
  PORT: process.env.PORT || 5000,
  NODE_ENV: process.env.NODE_ENV || 'development',

  // Database Configuration
  MONGO_URI: process.env.MONGO_URI || 'mongodb://localhost:27017/ricemill',

  // JWT Configuration
  JWT_SECRET: process.env.JWT_SECRET || 'your-jwt-secret-key-here',
  JWT_EXPIRE: process.env.JWT_EXPIRE || '30d',
  JWT_COOKIE_EXPIRE: process.env.JWT_COOKIE_EXPIRE || 30,

  // Email Configuration (for future use)
  SMTP_HOST: process.env.SMTP_HOST,
  SMTP_PORT: process.env.SMTP_PORT,
  SMTP_EMAIL: process.env.SMTP_EMAIL,
  SMTP_PASSWORD: process.env.SMTP_PASSWORD,
  FROM_EMAIL: process.env.FROM_EMAIL || 'noreply@ricemill.com',

  // File Upload Configuration
  MAX_FILE_SIZE: process.env.MAX_FILE_SIZE || 5 * 1024 * 1024, // 5MB
  FILE_UPLOAD_PATH: process.env.FILE_UPLOAD_PATH || './uploads',

  // Pagination
  DEFAULT_PAGE_SIZE: parseInt(process.env.DEFAULT_PAGE_SIZE) || 20,
  MAX_PAGE_SIZE: parseInt(process.env.MAX_PAGE_SIZE) || 100,

  // Rate Limiting
  RATE_LIMIT_WINDOW: parseInt(process.env.RATE_LIMIT_WINDOW) || 15 * 60 * 1000, // 15 minutes
  RATE_LIMIT_MAX_REQUESTS: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100,

  // CORS Configuration
  CORS_ORIGIN: process.env.CORS_ORIGIN || true, // Allow all in development

  // API Configuration
  API_VERSION: process.env.API_VERSION || 'v1',
  API_BASE_URL: process.env.API_BASE_URL || '/api/v1',

  // Security
  BCRYPT_ROUNDS: parseInt(process.env.BCRYPT_ROUNDS) || 12,

  // Company Settings
  DEFAULT_MAX_USERS: parseInt(process.env.DEFAULT_MAX_USERS) || 5,
  DEFAULT_PLAN: process.env.DEFAULT_PLAN || 'free',

  // Transaction Settings
  DEFAULT_CURRENCY: process.env.DEFAULT_CURRENCY || 'LKR',
  MIN_TRANSACTION_AMOUNT: parseFloat(process.env.MIN_TRANSACTION_AMOUNT) || 0.01,

  // Stock Settings
  DEFAULT_LOW_STOCK_THRESHOLD: parseFloat(process.env.DEFAULT_LOW_STOCK_THRESHOLD) || 10,

  // Sync Settings (for offline functionality)
  SYNC_ENABLED: process.env.SYNC_ENABLED === 'true' || false,
  SYNC_INTERVAL: parseInt(process.env.SYNC_INTERVAL) || 300000, // 5 minutes

  // Logging
  LOG_LEVEL: process.env.LOG_LEVEL || 'info',

  // External APIs (placeholders for future integrations)
  WEATHER_API_KEY: process.env.WEATHER_API_KEY,
  SMS_API_KEY: process.env.SMS_API_KEY,
  PAYMENT_GATEWAY_KEY: process.env.PAYMENT_GATEWAY_KEY
}

// Validation
if (!environment.JWT_SECRET || environment.JWT_SECRET === 'your-jwt-secret-key-here') {
  console.warn('⚠️  WARNING: JWT_SECRET is not set or using default value. Please set a secure secret in production.')
}

if (!environment.MONGO_URI || environment.MONGO_URI.includes('localhost')) {
  console.warn('⚠️  WARNING: Using local MongoDB. Make sure MongoDB is running.')
}

module.exports = environment
