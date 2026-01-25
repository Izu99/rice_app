const express = require('express')
const router = express.Router()
const auth = require('../middleware/auth')
const companyGuard = require('../middleware/companyGuard')
const { validationResult } = require('express-validator')
const { errorResponse, successResponse } = require('../utils/responseHandler')

// Import models
const Company = require('../models/Company')
const User = require('../models/User')
const Transaction = require('../models/Transaction')

// Import validators (to be implemented)
const {
  validateCompanyUpdate,
  validatePasswordChange
} = require('../validators/companyValidator')

// Apply authentication and company isolation to all routes
router.use(auth)
router.use(companyGuard)

/**
 * @route   GET /api/companies/profile
 * @desc    Get current company profile
 * @access  Private (Company users)
 */
router.get('/profile', async (req, res) => {
  try {
    const company = await Company.findById(req.companyId)

    if (!company) {
      return errorResponse(res, 'Company not found', 404)
    }

    const data = {
      company: {
        id: company._id,
        name: company.name,
        email: company.email,
        phone: company.phone,
        address: company.address,
        registrationNumber: company.registrationNumber,
        status: company.status,
        plan: company.plan,
        maxUsers: company.maxUsers,
        currentUsers: company.currentUsers,
        isActive: company.isActive,
        createdAt: company.createdAt
      }
    }

    return successResponse(res, 'Company profile retrieved successfully', data)
  } catch (error) {
    console.error('Get Company Profile Error:', error)
    return errorResponse(res, 'Error retrieving company profile', 500, error.message)
  }
})

/**
 * @route   PUT /api/companies/profile
 * @desc    Update company profile
 * @access  Private (Company admin only)
 */
router.put('/profile', validateCompanyUpdate, async (req, res) => {
  try {
    const errors = validationResult(req)
    if (!errors.isEmpty()) {
      return errorResponse(res, 'Validation failed', 400, errors.array())
    }

    const allowedUpdates = [
      'name', 'phone', 'address', 'registrationNumber'
    ]

    const updates = {}
    allowedUpdates.forEach(field => {
      if (req.body[field] !== undefined) {
        updates[field] = req.body[field]
      }
    })

    const company = await Company.findByIdAndUpdate(
      req.companyId,
      updates,
      { new: true, runValidators: true }
    )

    if (!company) {
      return errorResponse(res, 'Company not found', 404)
    }

    return successResponse(res, 'Company profile updated successfully', { company })
  } catch (error) {
    console.error('Update Company Profile Error:', error)
    return errorResponse(res, 'Error updating company profile', 500, error.message)
  }
})

/**
 * @route   GET /api/companies/users
 * @desc    Get all users in the company
 * @access  Private (Company admin only)
 */
router.get('/users', async (req, res) => {
  try {
    // Check if user is admin
    if (req.user.role !== 'admin') {
      return errorResponse(res, 'Access denied. Admin only.', 403)
    }

    const users = await User.find({
      companyId: req.companyId
    })
      .select('name email role isActive lastLoginAt createdAt')
      .sort({ createdAt: -1 })

    const data = { users }

    return successResponse(res, 'Company users retrieved successfully', data)
  } catch (error) {
    console.error('Get Company Users Error:', error)
    return errorResponse(res, 'Error retrieving company users', 500, error.message)
  }
})

/**
 * @route   GET /api/companies/statistics
 * @desc    Get company statistics
 * @access  Private (Company users)
 */
router.get('/statistics', async (req, res) => {
  try {
    // Get transaction statistics
    const transactionStats = await Transaction.aggregate([
      { $match: { companyId: req.companyId } },
      {
        $group: {
          _id: '$type',
          count: { $sum: 1 },
          totalAmount: { $sum: '$totalAmount' },
          totalPaid: { $sum: '$paidAmount' }
        }
      }
    ])

    const buyStats = transactionStats.find(s => s._id === 'buy') || { count: 0, totalAmount: 0, totalPaid: 0 }
    const sellStats = transactionStats.find(s => s._id === 'sell') || { count: 0, totalAmount: 0, totalPaid: 0 }

    // Get pending payments
    const pendingAmount = await Transaction.aggregate([
      {
        $match: {
          companyId: req.companyId,
          status: { $ne: 'completed' }
        }
      },
      { $group: { _id: null, total: { $sum: '$balance' } } }
    ])

    const data = {
      transactions: {
        totalBuyTransactions: buyStats.count,
        totalSellTransactions: sellStats.count,
        totalBuyAmount: buyStats.totalAmount,
        totalSellAmount: sellStats.totalAmount,
        totalRevenue: sellStats.totalAmount,
        totalExpenses: buyStats.totalAmount,
        pendingPayments: pendingAmount[0]?.total || 0
      }
    }

    return successResponse(res, 'Company statistics retrieved successfully', data)
  } catch (error) {
    console.error('Get Company Statistics Error:', error)
    return errorResponse(res, 'Error retrieving company statistics', 500, error.message)
  }
})

/**
 * @route   PUT /api/companies/change-password
 * @desc    Change company admin password
 * @access  Private (Company admin only)
 */
router.put('/change-password', validatePasswordChange, async (req, res) => {
  try {
    const errors = validationResult(req)
    if (!errors.isEmpty()) {
      return errorResponse(res, 'Validation failed', 400, errors.array())
    }

    // Check if user is admin
    if (req.user.role !== 'admin') {
      return errorResponse(res, 'Access denied. Admin only.', 403)
    }

    const { currentPassword, newPassword } = req.body

    // Verify current password
    const user = await User.findById(req.user.id)
    const isMatch = await user.comparePassword(currentPassword)

    if (!isMatch) {
      return errorResponse(res, 'Current password is incorrect', 400)
    }

    // Update password
    user.password = newPassword
    await user.save()

    return successResponse(res, 'Password changed successfully')
  } catch (error) {
    console.error('Change Password Error:', error)
    return errorResponse(res, 'Error changing password', 500, error.message)
  }
})

module.exports = router
