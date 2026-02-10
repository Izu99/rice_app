const mongoose = require('mongoose')
const Expense = require('../models/Expense')
const { validationResult } = require('express-validator')
const { errorResponse, successResponse } = require('../utils/responseHandler')

/**
 * @desc    Get all expenses with filtering and pagination
 * @route   GET /api/expenses
 * @access  Private
 */
exports.getExpenses = async (req, res) => {
  try {
    const {
      category,
      startDate,
      endDate,
      page = 1,
      limit = 20,
      sortBy = 'expenseDate',
      sortOrder = 'desc'
    } = req.query

    const query = { ...req.companyFilter, isActive: true }

    if (category) query.category = category
    if (startDate || endDate) {
      query.expenseDate = {}
      if (startDate) query.expenseDate.$gte = new Date(startDate)
      if (endDate) query.expenseDate.$lte = new Date(endDate)
    }

    const sort = {}
    sort[sortBy] = sortOrder === 'desc' ? -1 : 1

    const expenses = await Expense.find(query)
      .sort(sort)
      .limit(limit * 1)
      .skip((page - 1) * limit)
      .populate('createdBy', 'name')

    const total = await Expense.countDocuments(query)

    return successResponse(res, 'Expenses retrieved successfully', {
      expenses,
      pagination: {
        total,
        page: parseInt(page),
        limit: parseInt(limit),
        pages: Math.ceil(total / limit)
      }
    })
  } catch (error) {
    console.error('Get Expenses Error:', error)
    return errorResponse(res, 'Error retrieving expenses', 500, error.message)
  }
}

/**
 * @desc    Create new expense
 * @route   POST /api/expenses
 * @access  Private
 */
exports.createExpense = async (req, res) => {
  try {
    const { title, category, amount, expenseDate, notes } = req.body

    const expense = await Expense.create({
      title,
      category,
      amount,
      expenseDate: expenseDate || new Date(),
      notes,
      companyId: req.companyId,
      createdBy: req.user.id
    })

    return successResponse(res, 'Expense created successfully', { expense }, 201)
  } catch (error) {
    console.error('Create Expense Error:', error)
    return errorResponse(res, 'Error creating expense', 500, error.message)
  }
}

/**
 * @desc    Get expense summary
 * @route   GET /api/expenses/summary
 * @access  Private
 */
exports.getExpenseSummary = async (req, res) => {
  try {
    const { startDate, endDate } = req.query
    
    // Ensure companyId is an ObjectId for aggregations
    const companyId = new mongoose.Types.ObjectId(req.companyId)
    const query = { 
      companyId, 
      isActive: true 
    }

    if (startDate || endDate) {
      query.expenseDate = {}
      if (startDate) query.expenseDate.$gte = new Date(startDate)
      if (endDate) query.expenseDate.$lte = new Date(endDate)
    }

    const summary = await Expense.aggregate([
      { $match: query },
      {
        $group: {
          _id: '$category',
          totalAmount: { $sum: '$amount' },
          count: { $sum: 1 }
        }
      }
    ])

    const totalExpenses = summary.reduce((sum, item) => sum + item.totalAmount, 0)

    return successResponse(res, 'Expense summary retrieved', {
      totalExpenses,
      categoryBreakdown: summary
    })
  } catch (error) {
    return errorResponse(res, 'Error calculating summary', 500, error.message)
  }
}

/**
 * @desc    Update expense
 * @route   PUT /api/expenses/:id
 * @access  Private
 */
exports.updateExpense = async (req, res) => {
  try {
    const expense = await Expense.findOneAndUpdate(
      { _id: req.params.id, ...req.companyFilter },
      req.body,
      { new: true, runValidators: true }
    )

    if (!expense) return errorResponse(res, 'Expense not found', 404)

    return successResponse(res, 'Expense updated successfully', { expense })
  } catch (error) {
    return errorResponse(res, 'Error updating expense', 500, error.message)
  }
}

/**
 * @desc    Delete expense (soft delete)
 * @route   DELETE /api/expenses/:id
 * @access  Private
 */
exports.deleteExpense = async (req, res) => {
  try {
    const expense = await Expense.findOneAndUpdate(
      { _id: req.params.id, ...req.companyFilter },
      { isActive: false },
      { new: true }
    )

    if (!expense) return errorResponse(res, 'Expense not found', 404)

    return successResponse(res, 'Expense deleted successfully')
  } catch (error) {
    return errorResponse(res, 'Error deleting expense', 500, error.message)
  }
}
