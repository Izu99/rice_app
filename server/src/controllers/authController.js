const User = require('../models/User')
const Company = require('../models/Company')
const { validationResult } = require('express-validator')
const { errorResponse, successResponse } = require('../utils/responseHandler')
const crypto = require('crypto')
const mongoose = require('mongoose')

/**
 * @desc    Login user
 * @route   POST /api/auth/login
 * @access  Public
 */
exports.login = async (req, res) => {
  try {
    // Check for validation errors
    const errors = validationResult(req)
    if (!errors.isEmpty()) {
      return errorResponse(res, 'Validation failed', 400, errors.array())
    }

    const { email, phone, password } = req.body

    // Validate that either email or phone is provided
    if (!email && !phone) {
      return errorResponse(res, 'Either email or phone number is required', 400)
    }

    // Find user by email or phone and include password
    const query = email ? { email } : { phone }
    const user = await User.findOne(query).select('+password').populate('companyId', 'name status')

    if (!user) {
      return errorResponse(res, 'Invalid credentials', 401)
    }

    // Check if account is active
    if (!user.isActive) {
      return errorResponse(res, 'Your account has been deactivated. Please contact support.', 403)
    }

    // For company users, check if company is active
    if (user.role !== 'admin' && user.companyId && user.companyId.status !== 'active') {
      return errorResponse(res, 'Your company account is not active. Please contact support.', 403)
    }

    // Verify password
    const isPasswordValid = await user.comparePassword(password)

    if (!isPasswordValid) {
      return errorResponse(res, 'Invalid credentials', 401)
    }

    // Update last login time
    user.lastLoginAt = new Date()
    await user.save({ validateBeforeSave: false })

    // Generate JWT token
    const token = user.generateAuthToken()

    // Prepare user data (exclude sensitive fields)
    const userData = {
      id: user._id,
      email: user.email,
      name: user.name,
      role: user.role,
      companyId: user.companyId?._id || null,
      company: user.companyId
        ? {
            id: user.companyId._id,
            name: user.companyId.name,
            status: user.companyId.status
          }
        : null
    }

    return successResponse(res, 'Login successful', {
      user: userData,
      token,
      expiresIn: process.env.JWT_EXPIRE || 86400
    })
  } catch (error) {
    console.error('Login Error:', error)
    return errorResponse(res, 'Error logging in', 500, error.message)
  }
}

/**
 * @desc    Refresh JWT token
 * @route   POST /api/auth/refresh-token
 * @access  Private
 */
exports.refreshToken = async (req, res) => {
  try {
    // User is already attached to req by auth middleware
    const user = await User.findById(req.user.id)

    if (!user) {
      return errorResponse(res, 'User not found', 404)
    }

    // Check if account is still active
    if (!user.isActive) {
      return errorResponse(res, 'Account is deactivated', 403)
    }

    // Generate new token
    const token = user.generateAuthToken()

    return successResponse(res, 'Token refreshed successfully', {
      token,
      expiresIn: process.env.JWT_EXPIRE || 86400
    })
  } catch (error) {
    console.error('Refresh Token Error:', error)
    return errorResponse(res, 'Error refreshing token', 500, error.message)
  }
}

/**
 * @desc    Logout user
 * @route   POST /api/auth/logout
 * @access  Private
 */
exports.logout = async (req, res) => {
  try {
    // In a stateless JWT system, logout is handled client-side
    // If using token blacklist, would add token to blacklist here

    return successResponse(res, 'Logged out successfully')
  } catch (error) {
    console.error('Logout Error:', error)
    return errorResponse(res, 'Error logging out', 500, error.message)
  }
}

/**
 * @desc    Get current user profile
 * @route   GET /api/auth/me
 * @access  Private
 */
exports.getMe = async (req, res) => {
  try {
    const user = await User.findById(req.user.id).populate('companyId', 'name status')

    if (!user) {
      return errorResponse(res, 'User not found', 404)
    }

    const userData = {
      id: user._id,
      email: user.email,
      phone: user.phone,
      name: user.name,
      role: user.role,
      companyId: user.companyId?._id || null,
      company: user.companyId
        ? {
            id: user.companyId._id,
            name: user.companyId.name,
            status: user.companyId.status
          }
        : null
    }

    return successResponse(res, 'User profile retrieved successfully', { user: userData })
  } catch (error) {
    console.error('Get Me Error:', error)
    return errorResponse(res, 'Error retrieving user profile', 500, error.message)
  }
}

/**
 * @desc    Request password reset
 * @route   POST /api/auth/forgot-password
 * @access  Public
 */
exports.forgotPassword = async (req, res) => {
  try {
    const errors = validationResult(req)
    if (!errors.isEmpty()) {
      return errorResponse(res, 'Validation failed', 400, errors.array())
    }

    const { email } = req.body

    const user = await User.findOne({ email })

    if (!user) {
      // Don't reveal if email exists or not for security
      return successResponse(res, 'If an account with that email exists, a password reset link has been sent.')
    }

    // Generate reset token
    const resetToken = crypto.randomBytes(32).toString('hex')

    // Hash token before saving
    const hashedToken = crypto.createHash('sha256').update(resetToken).digest('hex')

    // Set token and expiry (1 hour)
    user.passwordResetToken = hashedToken
    user.passwordResetExpires = Date.now() + 60 * 60 * 1000 // 1 hour

    await user.save({ validateBeforeSave: false })

    // TODO: Send email with reset link
    // For now, just return success (in production, send email)
    console.log(`Password reset token for ${email}: ${resetToken}`)

    return successResponse(res, 'If an account with that email exists, a password reset link has been sent.')
  } catch (error) {
    console.error('Forgot Password Error:', error)
    return errorResponse(res, 'Error processing password reset request', 500, error.message)
  }
}

/**
 * @desc    Reset password with token
 * @route   POST /api/auth/reset-password
 * @access  Public
 */
exports.resetPassword = async (req, res) => {
  try {
    const errors = validationResult(req)
    if (!errors.isEmpty()) {
      return errorResponse(res, 'Validation failed', 400, errors.array())
    }

    const { token, newPassword } = req.body

    // Hash the token to compare with stored hash
    const hashedToken = crypto.createHash('sha256').update(token).digest('hex')

    // Find user with valid reset token
    const user = await User.findOne({
      passwordResetToken: hashedToken,
      passwordResetExpires: { $gt: Date.now() }
    })

    if (!user) {
      return errorResponse(res, 'Invalid or expired reset token', 400)
    }

    // Update password
    user.password = newPassword
    user.passwordResetToken = undefined
    user.passwordResetExpires = undefined

    await user.save()

    return successResponse(res, 'Password reset successful')
  } catch (error) {
    console.error('Reset Password Error:', error)
    return errorResponse(res, 'Error resetting password', 500, error.message)
  }
}

/**
 * @desc    Register new company and admin user (Public registration)
 * @route   POST /api/auth/register
 * @access  Public
 */
exports.register = async (req, res) => {
  const session = await mongoose.startSession()
  session.startTransaction()

  try {
    const errors = validationResult(req)
    if (!errors.isEmpty()) {
      return errorResponse(res, 'Validation failed', 400, errors.array())
    }

    const {
      name,
      ownerName,
      email,
      phone,
      address,
      registrationNumber,
      password
    } = req.body

    // For Sri Lankan systems, use phone as primary login method
    // Email is optional, phone is required for login

    // Check if email already exists
    if (email) {
      const existingCompany = await Company.findOne({ email }).session(session)
      if (existingCompany) {
        return errorResponse(res, 'Company with this email already exists', 409)
      }
    }

    // Check if phone already exists
    const existingPhone = await Company.findOne({ phone }).session(session)
    if (existingPhone) {
      return errorResponse(res, 'Company with this phone number already exists', 409)
    }

    // Create company
    const company = await Company.create([{
      name,
      ownerName,
      email,
      phone,
      address,
      registrationNumber,
      status: 'active' // Auto-approve for self-registration
    }], { session })

    // Create admin user for the company (using phone as primary login)
    const adminUser = await User.create([{
      email: email || `${phone}@temp.com`, // Optional email, use temp if not provided
      phone, // Phone is the primary login method
      password, // Will be hashed by pre-save middleware
      name: ownerName,
      role: 'admin', // Company admin, not super admin
      companyId: company[0]._id,
      isActive: true,
      isEmailVerified: true
    }], { session })

    await session.commitTransaction()

    // Generate JWT token for immediate login
    const token = adminUser[0].generateAuthToken()

    // Prepare user data (exclude sensitive fields)
    const userData = {
      id: adminUser[0]._id,
      email: adminUser[0].email,
      name: adminUser[0].name,
      role: adminUser[0].role,
      companyId: company[0]._id,
      company: {
        id: company[0]._id,
        name: company[0].name,
        status: company[0].status
      }
    }

    return successResponse(res, 'Company registered successfully', {
      user: userData,
      token,
      expiresIn: process.env.JWT_EXPIRE || 86400
    }, 201)
  } catch (error) {
    await session.abortTransaction()
    console.error('Register Company Error:', error)

    // Handle duplicate key errors
    if (error.code === 11000) {
      const field = Object.keys(error.keyPattern)[0]
      return errorResponse(res, `Company with this ${field} already exists`, 409)
    }

    return errorResponse(res, 'Error registering company', 500, error.message)
  } finally {
    session.endSession()
  }
}

/**
 * @desc    Create admin user for existing company
 * @route   POST /api/auth/create-admin
 * @access  Public (temporary - for setup)
 */
exports.createAdminForCompany = async (req, res) => {
  try {
    const errors = validationResult(req)
    if (!errors.isEmpty()) {
      return errorResponse(res, 'Validation failed', 400, errors.array())
    }

    const {
      companyId,
      name,
      phone,
      email,
      password
    } = req.body

    // Check if company exists
    const company = await Company.findById(companyId)
    if (!company) {
      return errorResponse(res, 'Company not found', 404)
    }

    // Check if admin user already exists for this company
    const existingAdmin = await User.findOne({
      companyId,
      role: 'admin'
    })

    if (existingAdmin) {
      return errorResponse(res, 'Admin user already exists for this company', 409)
    }

    // Check if phone or email already exists
    const existingUser = await User.findOne({
      $or: [
        { phone },
        { email }
      ]
    })

    if (existingUser) {
      return errorResponse(res, 'User with this phone or email already exists', 409)
    }

    // Create admin user
    const adminUser = await User.create({
      email: email || `${phone}@temp.com`,
      phone,
      password,
      name,
      role: 'admin',
      companyId,
      isActive: true,
      isEmailVerified: true
    })

    // Update company user count
    company.currentUsers = (company.currentUsers || 0) + 1
    await company.save()

    // Generate JWT token
    const token = adminUser.generateAuthToken()

    const userData = {
      id: adminUser._id,
      email: adminUser.email,
      name: adminUser.name,
      role: adminUser.role,
      companyId: adminUser.companyId,
      company: {
        id: company._id,
        name: company.name,
        status: company.status
      }
    }

    return successResponse(res, 'Admin user created successfully', {
      user: userData,
      token,
      expiresIn: process.env.JWT_EXPIRE || 86400
    }, 201)
  } catch (error) {
    console.error('Create Admin Error:', error)

    if (error.code === 11000) {
      return errorResponse(res, 'User with this phone or email already exists', 409)
    }

    return errorResponse(res, 'Error creating admin user', 500, error.message)
  }
}

/**
 * @desc    Change password for authenticated user
 * @route   POST /api/auth/change-password
 * @access  Private
 */
exports.changePassword = async (req, res) => {
  try {
    const errors = validationResult(req)
    if (!errors.isEmpty()) {
      return errorResponse(res, 'Validation failed', 400, errors.array())
    }

    const { currentPassword, newPassword } = req.body

    // Get user with password
    const user = await User.findById(req.user.id).select('+password')

    if (!user) {
      return errorResponse(res, 'User not found', 404)
    }

    // Verify current password
    const isPasswordValid = await user.comparePassword(currentPassword)

    if (!isPasswordValid) {
      return errorResponse(res, 'Current password is incorrect', 401)
    }

    // Update password
    user.password = newPassword
    await user.save()

    return successResponse(res, 'Password changed successfully')
  } catch (error) {
    console.error('Change Password Error:', error)
    return errorResponse(res, 'Error changing password', 500, error.message)
  }
}
