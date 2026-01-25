const Company = require('../models/Company')
const User = require('../models/User')
const Transaction = require('../models/Transaction')
const Customer = require('../models/Customer')
const { validationResult } = require('express-validator')
const { errorResponse, successResponse } = require('../utils/responseHandler')

/**
 * @desc    Get current company profile
 * @route   GET /api/companies/profile
 * @access  Private (Company users)
 */
exports.getProfile = async (req, res) => {
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
        createdAt: company.createdAt,
        settings: company.settings
      }
    }

    return successResponse(res, 'Company profile retrieved successfully', data)
  } catch (error) {
    console.error('Get Company Profile Error:', error)
    return errorResponse(res, 'Error retrieving company profile', 500, error.message)
  }
}

/**
 * @desc    Update company profile
 * @route   PUT /api/companies/profile
 * @access  Private (Company admin only)
 */
exports.updateProfile = async (req, res) => {
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
}

/**
 * @desc    Get all users in the company
 * @route   GET /api/companies/users
 * @access  Private (Company admin only)
 */
exports.getUsers = async (req, res) => {
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
}

/**
 * @desc    Get company statistics
 * @route   GET /api/companies/statistics
 * @access  Private (Company users)
 */
exports.getStatistics = async (req, res) => {
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

    // Get customer count
    const customerCount = await Customer.countDocuments({ companyId: req.companyId })

    // Get active stock count
    const stockCount = await require('../models/StockItem').countDocuments({
      companyId: req.companyId,
      isActive: true
    })

    const data = {
      transactions: {
        totalBuyTransactions: buyStats.count,
        totalSellTransactions: sellStats.count,
        totalBuyAmount: buyStats.totalAmount,
        totalSellAmount: sellStats.totalAmount,
        totalRevenue: sellStats.totalAmount,
        totalExpenses: buyStats.totalAmount,
        pendingPayments: pendingAmount[0]?.total || 0,
        netProfit: sellStats.totalAmount - buyStats.totalAmount
      },
      summary: {
        totalCustomers: customerCount,
        totalStockItems: stockCount,
        totalUsers: await User.countDocuments({ companyId: req.companyId })
      }
    }

    return successResponse(res, 'Company statistics retrieved successfully', data)
  } catch (error) {
    console.error('Get Company Statistics Error:', error)
    return errorResponse(res, 'Error retrieving company statistics', 500, error.message)
  }
}

/**
 * @desc    Change company admin password
 * @route   PUT /api/companies/change-password
 * @access  Private (Company admin only)
 */
exports.changePassword = async (req, res) => {
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
