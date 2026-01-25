const jwt = require('jsonwebtoken')
const User = require('../models/User')
const { errorResponse } = require('../utils/responseHandler')

/**
 * JWT Authentication Middleware
 * Extracts token from Authorization header, verifies it, and attaches user to request
 */
const auth = async (req, res, next) => {
  try {
    // Extract token from Authorization header
    const authHeader = req.headers.authorization

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return errorResponse(res, 'Access denied. No token provided.', 401)
    }

    const token = authHeader.split(' ')[1]

    if (!token) {
      return errorResponse(res, 'Access denied. No token provided.', 401)
    }

    try {
      // Verify token using JWT secret
      const decoded = jwt.verify(token, process.env.JWT_SECRET)

      // Find user by ID from token payload
      const user = await User.findById(decoded.id).populate('companyId', 'status')

      if (!user) {
        return errorResponse(res, 'User no longer exists.', 401)
      }

      // Check if user is active
      if (!user.isActive) {
        return errorResponse(res, 'Your account has been deactivated. Please contact support.', 403)
      }

      // If company user, check company status
      if (user.role !== 'admin' && user.companyId && user.companyId.status !== 'active') {
        return errorResponse(res, 'Your company account is not active. Please contact support.', 403)
      }

      // Attach user to request object
      req.user = {
        id: user._id,
        email: user.email,
        name: user.name,
        role: user.role,
        companyId: user.companyId?._id || null
      }

      next()
    } catch (error) {
      if (error.name === 'TokenExpiredError') {
        return errorResponse(res, 'Token has expired. Please login again.', 401)
      }
      if (error.name === 'JsonWebTokenError') {
        return errorResponse(res, 'Invalid token.', 401)
      }
      throw error
    }
  } catch (error) {
    console.error('Auth Middleware Error:', error)
    return errorResponse(res, 'Authentication failed.', 500, error.message)
  }
}

module.exports = auth
