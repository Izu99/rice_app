/**
 * Request logging middleware
 * Logs HTTP requests with relevant details for monitoring and debugging
 */
const logger = (req, res, next) => {
  const start = Date.now()

  // Log request
  const timestamp = new Date().toISOString()
  console.log(`[${timestamp}] ${req.method} ${req.originalUrl} - IP: ${req.ip}`)

  // Log request body for non-GET requests (excluding sensitive data)
  if (req.method !== 'GET' && req.body && Object.keys(req.body).length > 0) {
    const sanitizedBody = { ...req.body }

    // Remove sensitive fields from logs
    const sensitiveFields = ['password', 'currentPassword', 'newPassword', 'confirmPassword']
    sensitiveFields.forEach(field => {
      if (sanitizedBody[field]) {
        sanitizedBody[field] = '[REDACTED]'
      }
    })

    console.log(`[${timestamp}] Request Body:`, JSON.stringify(sanitizedBody, null, 2))
  }

  // Override res.json to log response
  const originalJson = res.json
  res.json = function (data) {
    const duration = Date.now() - start
    const statusCode = res.statusCode

    console.log(`[${new Date().toISOString()}] ${req.method} ${req.originalUrl} - ${statusCode} - ${duration}ms`)

    // Log response errors
    if (data && data.success === false) {
      console.error(`[${new Date().toISOString()}] Error Response:`, data.message || data.error)
    }

    return originalJson.call(this, data)
  }

  next()
}

module.exports = logger
