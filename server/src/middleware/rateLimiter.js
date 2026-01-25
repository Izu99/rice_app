const rateLimit = require('express-rate-limit') 
const { RATE_LIMITS } = require('../config/constants')

/**
 * General API rate limiter
 * Applied to most API endpoints
 */
const generalLimiter = rateLimit({
  windowMs: RATE_LIMITS.GENERAL.windowMs, // 15 minutes
  max: RATE_LIMITS.GENERAL.max, // limit each IP to X requests per windowMs
  message: {
    success: false,
    message: 'Too many requests from this IP, please try again later.',
    retryAfter: Math.ceil(RATE_LIMITS.GENERAL.windowMs / 1000)
  },
  standardHeaders: true, // Return rate limit info in the `RateLimit-*` headers
  legacyHeaders: false, // Disable the `X-RateLimit-*` headers
  // Skip rate limiting for super admin users
  skip: (req, res) => {
    return req.user && req.user.role === 'super_admin'
  },
  handler: (req, res) => {
    res.status(429).json({
      success: false,
      message: 'Too many requests from this IP, please try again later.',
      retryAfter: Math.ceil(RATE_LIMITS.GENERAL.windowMs / 1000)
    })
  }
})

/**
 * Authentication rate limiter
 * Stricter limits for auth endpoints to prevent brute force attacks
 */
const authLimiter = rateLimit({
  windowMs: RATE_LIMITS.AUTH.windowMs, // 15 minutes
  max: RATE_LIMITS.AUTH.max, // limit each IP to fewer requests per windowMs
  message: {
    success: false,
    message: 'Too many authentication attempts, please try again later.',
    retryAfter: Math.ceil(RATE_LIMITS.AUTH.windowMs / 1000)
  },
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => {
    res.status(429).json({
      success: false,
      message: 'Too many authentication attempts, please try again later.',
      retryAfter: Math.ceil(RATE_LIMITS.AUTH.windowMs / 1000)
    })
  }
})

/**
 * File upload rate limiter
 * Limits file uploads to prevent abuse
 */
const uploadLimiter = rateLimit({
  windowMs: RATE_LIMITS.UPLOAD.windowMs, // 1 hour
  max: RATE_LIMITS.UPLOAD.max, // limit each IP to fewer uploads per windowMs
  message: {
    success: false,
    message: 'Too many file uploads, please try again later.',
    retryAfter: Math.ceil(RATE_LIMITS.UPLOAD.windowMs / 1000)
  },
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => {
    res.status(429).json({
      success: false,
      message: 'Too many file uploads, please try again later.',
      retryAfter: Math.ceil(RATE_LIMITS.UPLOAD.windowMs / 1000)
    })
  }
})

/**
 * Strict rate limiter for critical operations
 * Very low limits for sensitive operations
 */
const strictLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 3, // Only 3 requests per 15 minutes
  message: {
    success: false,
    message: 'Too many sensitive operations, please try again later.',
    retryAfter: 15 * 60
  },
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => {
    res.status(429).json({
      success: false,
      message: 'Too many sensitive operations, please try again later.',
      retryAfter: 15 * 60
    })
  }
})

/**
 * Create custom rate limiter with specific settings
 * @param {Object} options - Rate limit options
 * @returns {Function} Rate limiter middleware
 */
const createCustomLimiter = (options) => {
  const defaultOptions = {
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100, // limit each IP to 100 requests per windowMs
    message: {
      success: false,
      message: 'Too many requests, please try again later.',
      retryAfter: Math.ceil((options.windowMs || 15 * 60 * 1000) / 1000)
    },
    standardHeaders: true,
    legacyHeaders: false,
    skip: (req, res) => {
      return req.user && req.user.role === 'super_admin'
    }
  }

  return rateLimit({ ...defaultOptions, ...options })
}

module.exports = {
  generalLimiter,
  authLimiter,
  uploadLimiter,
  strictLimiter,
  createCustomLimiter
}
