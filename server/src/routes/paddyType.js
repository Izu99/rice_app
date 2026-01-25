const express = require('express')
const router = express.Router()
const { body, param, query } = require('express-validator')
const PaddyType = require('../models/PaddyType')

// Import middleware
const auth = require('../middleware/auth')
const companyGuard = require('../middleware/companyGuard')
const { validateObjectId } = require('../middleware/validator')

// Validation rules
const createPaddyTypeValidation = [
  body('name')
    .trim()
    .notEmpty().withMessage('Paddy type name is required')
    .isLength({ min: 2, max: 50 }).withMessage('Name must be between 2-50 characters'),
  body('description')
    .optional()
    .trim()
    .isLength({ max: 200 }).withMessage('Description cannot exceed 200 characters'),
  body('averageYieldPercentage')
    .optional()
    .isFloat({ min: 0, max: 100 }).withMessage('Yield percentage must be between 0-100'),
  body('averageMoistureContent')
    .optional()
    .isFloat({ min: 0, max: 100 }).withMessage('Moisture content must be between 0-100'),
  body('qualityGrade')
    .optional()
    .isIn(['premium', 'standard', 'basic']).withMessage('Invalid quality grade')
]

const updatePaddyTypeValidation = [
  body('name')
    .optional()
    .trim()
    .isLength({ min: 2, max: 50 }).withMessage('Name must be between 2-50 characters'),
  body('description')
    .optional()
    .trim()
    .isLength({ max: 200 }).withMessage('Description cannot exceed 200 characters'),
  body('averageYieldPercentage')
    .optional()
    .isFloat({ min: 0, max: 100 }).withMessage('Yield percentage must be between 0-100'),
  body('averageMoistureContent')
    .optional()
    .isFloat({ min: 0, max: 100 }).withMessage('Moisture content must be between 0-100'),
  body('qualityGrade')
    .optional()
    .isIn(['premium', 'standard', 'basic']).withMessage('Invalid quality grade'),
  body('isActive')
    .optional()
    .isBoolean().withMessage('isActive must be a boolean')
]

/**
 * All routes require authentication and company isolation
 */
router.use(auth)
router.use(companyGuard)

/**
 * @route   GET /api/paddy-types
 * @desc    Get all paddy types for company
 * @access  Private (Company users)
 */
router.get('/', async (req, res) => {
  try {
    const { qualityGrade, isActive } = req.query

    const query = { ...req.companyFilter }
    if (qualityGrade) query.qualityGrade = qualityGrade
    if (isActive !== undefined) query.isActive = isActive === 'true'

    const paddyTypes = await PaddyType.find(query)
      .sort({ name: 1 })

    res.json({
      success: true,
      data: {
        paddyTypes: paddyTypes.map(pt => pt.getPublicProfile()),
        count: paddyTypes.length
      }
    })
  } catch (error) {
    console.error('Get Paddy Types Error:', error)
    res.status(500).json({
      success: false,
      message: 'Error retrieving paddy types',
      error: error.message
    })
  }
})

/**
 * @route   GET /api/paddy-types/active
 * @desc    Get active paddy types for dropdowns
 * @access  Private (Company users)
 */
router.get('/active', async (req, res) => {
  try {
    const paddyTypes = await PaddyType.getActiveForCompany(req.companyId)

    res.json({
      success: true,
      data: {
        paddyTypes: paddyTypes.map(pt => ({
          id: pt._id,
          name: pt.name,
          qualityGrade: pt.qualityGrade,
          averageYieldPercentage: pt.averageYieldPercentage
        }))
      }
    })
  } catch (error) {
    console.error('Get Active Paddy Types Error:', error)
    res.status(500).json({
      success: false,
      message: 'Error retrieving active paddy types',
      error: error.message
    })
  }
})

/**
 * @route   GET /api/paddy-types/:id
 * @desc    Get paddy type by ID
 * @access  Private (Company users)
 */
router.get('/:id', validateObjectId('id'), async (req, res) => {
  try {
    const paddyType = await PaddyType.findOne({
      _id: req.params.id,
      ...req.companyFilter
    })

    if (!paddyType) {
      return res.status(404).json({
        success: false,
        message: 'Paddy type not found'
      })
    }

    res.json({
      success: true,
      data: {
        paddyType: paddyType.getDetailedInfo()
      }
    })
  } catch (error) {
    console.error('Get Paddy Type Error:', error)
    res.status(500).json({
      success: false,
      message: 'Error retrieving paddy type',
      error: error.message
    })
  }
})

/**
 * @route   POST /api/paddy-types
 * @desc    Create new paddy type
 * @access  Private (Company users)
 */
router.post('/', createPaddyTypeValidation, async (req, res) => {
  try {
    const { name, description, averageYieldPercentage, averageMoistureContent, qualityGrade } = req.body

    // Check if paddy type with same name already exists for this company
    const existing = await PaddyType.findOne({
      name: { $regex: new RegExp(`^${name}$`, 'i') },
      ...req.companyFilter
    })

    if (existing) {
      return res.status(409).json({
        success: false,
        message: 'Paddy type with this name already exists'
      })
    }

    const paddyType = await PaddyType.create({
      name,
      description,
      averageYieldPercentage,
      averageMoistureContent,
      qualityGrade,
      companyId: req.companyId
    })

    res.status(201).json({
      success: true,
      message: 'Paddy type created successfully',
      data: {
        paddyType: paddyType.getDetailedInfo()
      }
    })
  } catch (error) {
    console.error('Create Paddy Type Error:', error)
    res.status(500).json({
      success: false,
      message: 'Error creating paddy type',
      error: error.message
    })
  }
})

/**
 * @route   PUT /api/paddy-types/:id
 * @desc    Update paddy type
 * @access  Private (Company users)
 */
router.put('/:id', validateObjectId('id'), updatePaddyTypeValidation, async (req, res) => {
  try {
    const updates = {}
    const allowedFields = [
      'name', 'description', 'averageYieldPercentage',
      'averageMoistureContent', 'qualityGrade', 'isActive'
    ]

    allowedFields.forEach(field => {
      if (req.body[field] !== undefined) {
        updates[field] = req.body[field]
      }
    })

    const paddyType = await PaddyType.findOneAndUpdate(
      { _id: req.params.id, ...req.companyFilter },
      updates,
      { new: true, runValidators: true }
    )

    if (!paddyType) {
      return res.status(404).json({
        success: false,
        message: 'Paddy type not found'
      })
    }

    res.json({
      success: true,
      message: 'Paddy type updated successfully',
      data: {
        paddyType: paddyType.getDetailedInfo()
      }
    })
  } catch (error) {
    console.error('Update Paddy Type Error:', error)
    res.status(500).json({
      success: false,
      message: 'Error updating paddy type',
      error: error.message
    })
  }
})

/**
 * @route   DELETE /api/paddy-types/:id
 * @desc    Delete paddy type (soft delete)
 * @access  Private (Company users)
 */
router.delete('/:id', validateObjectId('id'), async (req, res) => {
  try {
    const paddyType = await PaddyType.findOneAndUpdate(
      { _id: req.params.id, ...req.companyFilter },
      { isActive: false },
      { new: true }
    )

    if (!paddyType) {
      return res.status(404).json({
        success: false,
        message: 'Paddy type not found'
      })
    }

    res.json({
      success: true,
      message: 'Paddy type deactivated successfully'
    })
  } catch (error) {
    console.error('Delete Paddy Type Error:', error)
    res.status(500).json({
      success: false,
      message: 'Error deleting paddy type',
      error: error.message
    })
  }
})

module.exports = router
