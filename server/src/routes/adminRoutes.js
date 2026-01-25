const express = require('express')
const router = express.Router()
const auth = require('../middleware/auth')
const roleGuard = require('../middleware/roleGuard')
const { validationResult } = require('express-validator')
const { errorResponse, successResponse } = require('../utils/responseHandler')

// Import models
const Company = require('../models/Company')
const User = require('../models/User')
const Transaction = require('../models/Transaction')

// Inline validators for now
const { body } = require('express-validator')

const validateCompanyCreation = [
  body('name').trim().notEmpty().withMessage('Company name is required'),
  body('ownerName').trim().notEmpty().withMessage('Owner name is required'),
  body('email').isEmail().normalizeEmail().withMessage('Valid email is required'),
  body('phone').trim().notEmpty().withMessage('Phone number is required'),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters')
]

const validateCompanyUpdate = [
  body('name').optional().trim().notEmpty().withMessage('Company name cannot be empty'),
  body('ownerName').optional().trim().notEmpty().withMessage('Owner name cannot be empty'),
  body('email').optional().isEmail().normalizeEmail().withMessage('Valid email is required'),
  body('phone').optional().trim().notEmpty().withMessage('Phone number cannot be empty')
]

const validateStatusChange = [
  body('status').isIn(['active', 'inactive', 'suspended']).withMessage('Invalid status'),
  body('reason').optional().trim().isLength({ max: 500 }).withMessage('Reason too long')
]

// Apply authentication and admin role check to all routes
router.use(auth)
router.use(roleGuard('admin'))

/**
 * @route   GET /api/admin/dashboard
 * @desc    Get Super Admin dashboard statistics
 * @access  Private (Super Admin only)
 */
router.get('/dashboard', async (req, res) => {
  try {
    // Get company statistics
    const totalCompanies = await Company.countDocuments()
    const activeCompanies = await Company.countDocuments({ status: 'active' })
    const pendingCompanies = await Company.countDocuments({ status: 'pending' })
    const inactiveCompanies = await Company.countDocuments({ status: 'inactive' })

    // Get user statistics
    const totalUsers = await User.countDocuments({ role: { $ne: 'admin' } })

    // Get today's transactions count
    const today = new Date()
    today.setHours(0, 0, 0, 0)
    const tomorrow = new Date(today)
    tomorrow.setDate(tomorrow.getDate() + 1)

    const totalTransactionsToday = await Transaction.countDocuments({
      createdAt: { $gte: today, $lt: tomorrow }
    })

    // Get recent companies (last 5)
    const recentCompanies = await Company.find()
      .sort({ createdAt: -1 })
      .limit(5)
      .select('name status createdAt')

    // Get companies per month (simplified - would need aggregation in production)
    const companiesPerMonth = {} // Placeholder - implement aggregation pipeline

    const data = {
      totalCompanies,
      activeCompanies,
      pendingCompanies,
      inactiveCompanies,
      totalUsers,
      totalTransactionsToday,
      recentCompanies,
      companiesPerMonth
    }

    return successResponse(res, 'Dashboard statistics retrieved successfully', data)
  } catch (error) {
    console.error('Dashboard Error:', error)
    return errorResponse(res, 'Error retrieving dashboard statistics', 500, error.message)
  }
})

/**
 * @route   GET /api/admin/companies
 * @desc    Get all companies with filtering and pagination
 * @access  Private (Super Admin only)
 */
router.get('/companies', async (req, res) => {
  try {
    const {
      status,
      search,
      page = 1,
      limit = 20,
      sortBy = 'createdAt',
      sortOrder = 'desc'
    } = req.query

    // Build query
    const query = {}
    if (status) query.status = status

    if (search) {
      query.$or = [
        { name: { $regex: search, $options: 'i' } },
        { email: { $regex: search, $options: 'i' } },
        { phone: { $regex: search, $options: 'i' } }
      ]
    }

    // Build sort
    const sort = {}
    sort[sortBy] = sortOrder === 'desc' ? -1 : 1

    // Execute query with pagination
    const companies = await Company.find(query)
      .sort(sort)
      .limit(limit * 1)
      .skip((page - 1) * limit)
      .populate('createdBy', 'name email')

    const total = await Company.countDocuments(query)
    const pages = Math.ceil(total / limit)

    const data = {
      companies,
      pagination: {
        total,
        page: parseInt(page),
        limit: parseInt(limit),
        pages
      }
    }

    return successResponse(res, 'Companies retrieved successfully', data)
  } catch (error) {
    console.error('Get Companies Error:', error)
    return errorResponse(res, 'Error retrieving companies', 500, error.message)
  }
})

/**
 * @route   GET /api/admin/companies/:id
 * @desc    Get single company details with statistics
 * @access  Private (Super Admin only)
 */
router.get('/companies/:id', async (req, res) => {
  try {
    const company = await Company.findById(req.params.id)
      .populate('createdBy', 'name email')

    if (!company) {
      return errorResponse(res, 'Company not found', 404)
    }

    // Get company users
    const users = await User.find({ companyId: req.params.id })
      .select('name email role isActive lastLoginAt')

    // Get company statistics (placeholder - implement actual aggregations)
    const statistics = {
      totalTransactions: 0, // Implement aggregation
      totalRevenue: 0, // Implement aggregation
      totalCustomers: 0 // Implement aggregation
    }

    const data = {
      company,
      users,
      statistics
    }

    return successResponse(res, 'Company details retrieved successfully', data)
  } catch (error) {
    console.error('Get Company Error:', error)
    return errorResponse(res, 'Error retrieving company details', 500, error.message)
  }
})

/**
 * @route   POST /api/admin/companies
 * @desc    Create new company and admin user
 * @access  Private (Super Admin only)
 */
router.post('/companies', validateCompanyCreation, async (req, res) => {
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

    // Check if email already exists
    const existingCompany = await Company.findOne({ email })
    if (existingCompany) {
      return errorResponse(res, 'Company with this email already exists', 409)
    }

    // Check if phone already exists
    const existingPhone = await Company.findOne({ phone })
    if (existingPhone) {
      return errorResponse(res, 'Company with this phone number already exists', 409)
    }

    // Create company
    const company = await Company.create({
      name,
      ownerName,
      email,
      phone,
      address,
      registrationNumber,
      createdBy: req.user.id
    })

    // Create admin user for the company
    const adminUser = await User.create({
      email,
      password, // Will be hashed by pre-save middleware
      name: ownerName,
      role: 'company',
      companyId: company._id,
      isActive: true,
      isEmailVerified: true
    })

    // Update company user count
    company.currentUsers = 1
    await company.save()

    const data = {
      company,
      adminUser: {
        email: adminUser.email,
        name: adminUser.name,
        role: adminUser.role
      }
    }

    return successResponse(res, 'Company created successfully', data, 201)
  } catch (error) {
    console.error('Create Company Error:', error)
    return errorResponse(res, 'Error creating company', 500, error.message)
  }
})

/**
 * @route   PUT /api/admin/companies/:id
 * @desc    Update company details
 * @access  Private (Super Admin only)
 */
router.put('/companies/:id', validateCompanyUpdate, async (req, res) => {
  try {
    const errors = validationResult(req)
    if (!errors.isEmpty()) {
      return errorResponse(res, 'Validation failed', 400, errors.array())
    }

    const allowedUpdates = [
      'name', 'ownerName', 'email', 'phone', 'address',
      'registrationNumber', 'status', 'maxUsers', 'settings'
    ]

    const updates = {}
    allowedUpdates.forEach(field => {
      if (req.body[field] !== undefined) {
        updates[field] = req.body[field]
      }
    })

    const company = await Company.findByIdAndUpdate(
      req.params.id,
      updates,
      { new: true, runValidators: true }
    )

    if (!company) {
      return errorResponse(res, 'Company not found', 404)
    }

    return successResponse(res, 'Company updated successfully', { company })
  } catch (error) {
    console.error('Update Company Error:', error)
    return errorResponse(res, 'Error updating company', 500, error.message)
  }
})

/**
 * @route   PATCH /api/admin/companies/:id/status
 * @desc    Change company status
 * @access  Private (Super Admin only)
 */
router.patch('/companies/:id/status', validateStatusChange, async (req, res) => {
  try {
    const errors = validationResult(req)
    if (!errors.isEmpty()) {
      return errorResponse(res, 'Validation failed', 400, errors.array())
    }

    const { status, reason } = req.body

    const company = await Company.findById(req.params.id)
    if (!company) {
      return errorResponse(res, 'Company not found', 404)
    }

    company.status = status
    await company.save()

    // TODO: Implement user logout for suspended companies
    // TODO: Send notification emails

    return successResponse(res, `Company status updated to ${status}`)
  } catch (error) {
    console.error('Change Status Error:', error)
    return errorResponse(res, 'Error updating company status', 500, error.message)
  }
})

/**
 * @route   DELETE /api/admin/companies/:id
 * @desc    Delete company (soft delete)
 * @access  Private (Super Admin only)
 */
router.delete('/companies/:id', async (req, res) => {
  try {
    const company = await Company.findById(req.params.id)
    if (!company) {
      return errorResponse(res, 'Company not found', 404)
    }

    // TODO: Check for active transactions
    // TODO: Implement soft delete instead of hard delete

    // For now, just deactivate the company
    company.status = 'inactive'
    await company.save()

    // Deactivate all company users
    await User.updateMany(
      { companyId: req.params.id },
      { isActive: false }
    )

    return successResponse(res, 'Company deactivated successfully')
  } catch (error) {
    console.error('Delete Company Error:', error)
    return errorResponse(res, 'Error deleting company', 500, error.message)
  }
})

/**
 * @route   POST /api/admin/companies/:id/reset-password
 * @desc    Reset company admin password
 * @access  Private (Super Admin only)
 */
router.post('/companies/:id/reset-password', async (req, res) => {
  try {
    const { newPassword } = req.body

    if (!newPassword) {
      return errorResponse(res, 'New password is required', 400)
    }

    // Find admin user for the company
    const adminUser = await User.findOne({
      companyId: req.params.id,
      role: 'company'
    })

    if (!adminUser) {
      return errorResponse(res, 'Company admin user not found', 404)
    }

    // Update password
    adminUser.password = newPassword
    await adminUser.save()

    return successResponse(res, 'Password reset successfully')
  } catch (error) {
    console.error('Reset Password Error:', error)
    return errorResponse(res, 'Error resetting password', 500, error.message)
  }
})

module.exports = router
