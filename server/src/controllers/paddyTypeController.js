const PaddyType = require('../models/PaddyType')
const { validationResult } = require('express-validator')
const { errorResponse, successResponse } = require('../utils/responseHandler')

/**
 * @desc    Create a new paddy type
 * @route   POST /api/paddy-types
 * @access  Private
 */
exports.createPaddyType = async (req, res) => {
  try {
    const errors = validationResult(req)
    if (!errors.isEmpty()) {
      return errorResponse(res, 'Validation failed', 400, errors.array())
    }

    const { name, description } = req.body

    // Check if paddy type with same name already exists for this user
    const existingPaddyType = await PaddyType.findOne({
      userId: req.user.id,
      name: name.trim()
    })

    if (existingPaddyType) {
      return errorResponse(res, 'Paddy type with this name already exists', 409)
    }

    // Create paddy type
    const paddyType = await PaddyType.create({
      name,
      description,
      userId: req.user.id
    })

    return successResponse(res, 'Paddy type created successfully', {
      paddyType: paddyType.getPublicProfile()
    }, 201)
  } catch (error) {
    console.error('Create Paddy Type Error:', error)
    return errorResponse(res, 'Error creating paddy type', 500, error.message)
  }
}

/**
 * @desc    Get all paddy types
 * @route   GET /api/paddy-types
 * @access  Private
 */
exports.getPaddyTypes = async (req, res) => {
  try {
    const { search, isActive } = req.query

    // Build query
    const query = { userId: req.user.id }

    if (search) {
      query.name = { $regex: search, $options: 'i' }
    }

    if (isActive !== undefined) {
      query.isActive = isActive === 'true'
    }

    const paddyTypes = await PaddyType.find(query).sort({ name: 1 })

    return successResponse(res, 'Paddy types retrieved successfully', {
      paddyTypes: paddyTypes.map(pt => pt.getPublicProfile()),
      count: paddyTypes.length
    })
  } catch (error) {
    console.error('Get Paddy Types Error:', error)
    return errorResponse(res, 'Error retrieving paddy types', 500, error.message)
  }
}

/**
 * @desc    Get paddy type by ID
 * @route   GET /api/paddy-types/:id
 * @access  Private
 */
exports.getPaddyTypeById = async (req, res) => {
  try {
    const paddyType = await PaddyType.findOne({
      _id: req.params.id,
      userId: req.user.id
    })

    if (!paddyType) {
      return errorResponse(res, 'Paddy type not found', 404)
    }

    return successResponse(res, 'Paddy type retrieved successfully', {
      paddyType: paddyType.getPublicProfile()
    })
  } catch (error) {
    console.error('Get Paddy Type Error:', error)
    return errorResponse(res, 'Error retrieving paddy type', 500, error.message)
  }
}

/**
 * @desc    Update paddy type
 * @route   PUT /api/paddy-types/:id
 * @access  Private
 */
exports.updatePaddyType = async (req, res) => {
  try {
    const errors = validationResult(req)
    if (!errors.isEmpty()) {
      return errorResponse(res, 'Validation failed', 400, errors.array())
    }

    const allowedUpdates = ['name', 'description', 'isActive']
    const updates = {}

    allowedUpdates.forEach(field => {
      if (req.body[field] !== undefined) {
        updates[field] = req.body[field]
      }
    })

    const paddyType = await PaddyType.findOneAndUpdate(
      { _id: req.params.id, userId: req.user.id },
      updates,
      { new: true, runValidators: true }
    )

    if (!paddyType) {
      return errorResponse(res, 'Paddy type not found', 404)
    }

    return successResponse(res, 'Paddy type updated successfully', {
      paddyType: paddyType.getPublicProfile()
    })
  } catch (error) {
    console.error('Update Paddy Type Error:', error)
    return errorResponse(res, 'Error updating paddy type', 500, error.message)
  }
}

/**
 * @desc    Delete paddy type
 * @route   DELETE /api/paddy-types/:id
 * @access  Private
 */
exports.deletePaddyType = async (req, res) => {
  try {
    const paddyType = await PaddyType.findOneAndDelete({
      _id: req.params.id,
      userId: req.user.id
    })

    if (!paddyType) {
      return errorResponse(res, 'Paddy type not found', 404)
    }

    return successResponse(res, 'Paddy type deleted successfully')
  } catch (error) {
    console.error('Delete Paddy Type Error:', error)
    return errorResponse(res, 'Error deleting paddy type', 500, error.message)
  }
}
