const cors = require('cors')

// CORS Configuration
const corsOptions = {
  origin: function (origin, callback) {
    // Allow requests with no origin (mobile apps, curl, etc.)
    if (!origin) return callback(null, true)

    const allowedOrigins = [
      'http://localhost:3000', // React development server
      'http://localhost:3001', // Alternative React port
      'http://localhost:5000', // Backend server
      'http://127.0.0.1:3000', // Alternative localhost
      'http://127.0.0.1:5000', // Alternative backend
      'http://localhost:8080', // Some mobile emulators
      'capacitor://localhost', // Capacitor mobile app
      'ionic://localhost', // Ionic mobile app
      'http://10.0.2.2:3000', // Android emulator localhost
      'http://192.168.1.1:3000' // Common local network IP
      // Add production domains here when deploying
      // 'https://yourdomain.com',
      // 'https://www.yourdomain.com'
    ]

    // In development, allow all origins
    if (process.env.NODE_ENV === 'development') {
      return callback(null, true)
    }

    // In production, check against allowed origins
    if (allowedOrigins.includes(origin)) {
      callback(null, true)
    } else {
      callback(new Error('Not allowed by CORS'))
    }
  },

  credentials: true, // Allow cookies and credentials

  methods: [
    'GET',
    'POST',
    'PUT',
    'PATCH',
    'DELETE',
    'OPTIONS'
  ],

  allowedHeaders: [
    'Origin',
    'X-Requested-With',
    'Content-Type',
    'Accept',
    'Authorization',
    'Cache-Control',
    'X-Access-Token',
    'X-Company-ID',
    'X-API-Key'
  ],

  exposedHeaders: [
    'X-Total-Count',
    'X-Page-Count',
    'X-Current-Page',
    'X-Per-Page'
  ],

  optionsSuccessStatus: 200, // Some legacy browsers choke on 204

  maxAge: 86400 // Cache preflight for 24 hours
}

// For development, allow all origins
if (process.env.NODE_ENV === 'development') {
  corsOptions.origin = true
}

module.exports = cors(corsOptions)
