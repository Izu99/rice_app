const { validationResult } = require('express-validator')

/**
 * Validation middleware that checks for validation errors
 * and returns formatted error response if any exist
 */
const validate = (req, res, next) => {
  const errors = validationResult(req)

  if (!errors.isEmpty()) {
    // Format errors for better API response
    const formattedErrors = errors.array().map(error => ({
      field: error.path || error.param,
      message: error.msg,
      value: error.value
    }))

    return res.status(400).json({
      success: false,
      message: 'Validation failed',
      errors: formattedErrors,
      timestamp: new Date().toISOString()
    })
  }

  next()
}

/**
 * Middleware to validate MongoDB ObjectId format
 * Used for route parameters that should be ObjectIds
 */
const validateObjectId = (paramName) => {
  return (req, res, next) => {
    const paramValue = req.params[paramName]

    if (!paramValue) {
      return res.status(400).json({
        success: false,
        message: `${paramName} parameter is required`,
        timestamp: new Date().toISOString()
      })
    }

    // Basic MongoDB ObjectId validation (24 hex characters)
    const objectIdRegex = /^[0-9a-fA-F]{24}$/
    if (!objectIdRegex.test(paramValue)) {
      return res.status(400).json({
        success: false,
        message: `Invalid ${paramName} format`,
        timestamp: new Date().toISOString()
      })
    }

    next()
  }
}

/**
 * Middleware to validate date format (YYYY-MM-DD)
 */
const validateDateFormat = (paramName) => {
  return (req, res, next) => {
    const paramValue = req.params[paramName] || req.query[paramName] || req.body[paramName]

    if (paramValue) {
      const dateRegex = /^\d{4}-\d{2}-\d{2}$/
      if (!dateRegex.test(paramValue)) {
        return res.status(400).json({
          success: false,
          message: `Invalid ${paramName} format. Use YYYY-MM-DD`,
          timestamp: new Date().toISOString()
        })
      }

      // Additional validation for valid date
      const date = new Date(paramValue)
      if (isNaN(date.getTime())) {
        return res.status(400).json({
          success: false,
          message: `Invalid date: ${paramName}`,
          timestamp: new Date().toISOString()
        })
      }
    }

    next()
  }
}

/**
 * Middleware to validate numeric parameters
 */
const validateNumeric = (paramName, options = {}) => {
  return (req, res, next) => {
    const { min, max, integer = false } = options
    const paramValue = req.params[paramName] || req.query[paramName] || req.body[paramName]

    if (paramValue !== undefined && paramValue !== null) {
      const num = Number(paramValue)

      if (isNaN(num)) {
        return res.status(400).json({
          success: false,
          message: `${paramName} must be a valid number`,
          timestamp: new Date().toISOString()
        })
      }

      if (integer && !Number.isInteger(num)) {
        return res.status(400).json({
          success: false,
          message: `${paramName} must be an integer`,
          timestamp: new Date().toISOString()
        })
      }

      if (min !== undefined && num < min) {
        return res.status(400).json({
          success: false,
          message: `${paramName} must be at least ${min}`,
          timestamp: new Date().toISOString()
        })
      }

      if (max !== undefined && num > max) {
        return res.status(400).json({
          success: false,
          message: `${paramName} must be at most ${max}`,
          timestamp: new Date().toISOString()
        })
      }
    }

    next()
  }
}

/**
 * Middleware to validate enum values
 */
const validateEnum = (paramName, validValues) => {
  return (req, res, next) => {
    const paramValue = req.params[paramName] || req.query[paramName] || req.body[paramName]

    if (paramValue && !validValues.includes(paramValue)) {
      return res.status(400).json({
        success: false,
        message: `Invalid ${paramName}. Must be one of: ${validValues.join(', ')}`,
        timestamp: new Date().toISOString()
      })
    }

    next()
  }
}

/**
 * Middleware to validate string length
 */
const validateStringLength = (paramName, options = {}) => {
  return (req, res, next) => {
    const { min, max, trim = true } = options
    let paramValue = req.params[paramName] || req.query[paramName] || req.body[paramName]

    if (paramValue && trim) {
      paramValue = paramValue.trim()
    }

    if (paramValue) {
      if (min !== undefined && paramValue.length < min) {
        return res.status(400).json({
          success: false,
          message: `${paramName} must be at least ${min} characters long`,
          timestamp: new Date().toISOString()
        })
      }

      if (max !== undefined && paramValue.length > max) {
        return res.status(400).json({
          success: false,
          message: `${paramName} must be at most ${max} characters long`,
          timestamp: new Date().toISOString()
        })
      }
    }

    next()
  }
}

/**
 * Middleware to sanitize input data
 * Removes potentially dangerous characters and normalizes input
 */
const sanitizeInput = (req, res, next) => {
  // Function to recursively sanitize object properties
  const sanitizeValue = (value) => {
    if (typeof value === 'string') {
      // Trim whitespace
      value = value.trim()

      // Remove null bytes and other dangerous characters
      // Using hex literals to avoid no-control-regex warning
      value = value.replace(/[\x00-\x1F\x7F-\x9F]/g, '')

      // Limit length to prevent buffer overflow attempts
      if (value.length > 10000) {
        value = value.substring(0, 10000) + '...'
      }

      return value
    } else if (Array.isArray(value)) {
      return value.map(sanitizeValue)
    } else if (typeof value === 'object' && value !== null) {
      const sanitized = {}
      for (const [key, val] of Object.entries(value)) {
        // Skip sensitive fields
        if (!['password', 'token', 'secret'].some(field => key.toLowerCase().includes(field))) {
          sanitized[key] = sanitizeValue(val)
        }
      }
      return sanitized
    }
    return value
  }

  // Sanitize request body, query, and params
  if (req.body) req.body = sanitizeValue(req.body)
  if (req.query) req.query = sanitizeValue(req.query)
  if (req.params) req.params = sanitizeValue(req.params)

  next()
}

/**
 * Middleware to validate file uploads
 */
const validateFileUpload = (allowedTypes = [], maxSize = 5 * 1024 * 1024) => {
  return (req, res, next) => {
    if (!req.file && !req.files) {
      return next() // No file uploaded, continue
    }

    const files = req.files || [req.file]

    for (const file of files) {
      // Check file size
      if (file.size > maxSize) {
        return res.status(400).json({
          success: false,
          message: `File ${file.originalname} is too large. Maximum size: ${maxSize / (1024 * 1024)}MB`,
          timestamp: new Date().toISOString()
        })
      }

      // Check file type
      if (allowedTypes.length > 0 && !allowedTypes.includes(file.mimetype)) {
        return res.status(400).json({
          success: false,
          message: `File ${file.originalname} has invalid type. Allowed types: ${allowedTypes.join(', ')}`,
          timestamp: new Date().toISOString()
        })
      }

      // Check for malicious file extensions
      const dangerousExtensions = ['.exe', '.bat', '.cmd', '.scr', '.pif', '.com']
      const fileExtension = file.originalname.toLowerCase().substring(file.originalname.lastIndexOf('.'))

      if (dangerousExtensions.includes(fileExtension)) {
        return res.status(400).json({
          success: false,
          message: `File type ${fileExtension} is not allowed`,
          timestamp: new Date().toISOString()
        })
      }
    }

    next()
  }
}

module.exports = {
  validate,
  validateObjectId,
  validateDateFormat,
  validateNumeric,
  validateEnum,
  validateStringLength,
  sanitizeInput,
  validateFileUpload
}
