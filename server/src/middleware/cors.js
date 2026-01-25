const cors = require('cors')

// Simple CORS middleware wrapper
const corsOptions = {
  origin: true,
  credentials: true,
  allowedHeaders: ['Content-Type', 'Authorization'],
  methods: ['GET', 'HEAD', 'PUT', 'PATCH', 'POST', 'DELETE']
}

module.exports = cors(corsOptions)
