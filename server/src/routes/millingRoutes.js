const express = require('express')
const router = express.Router()
const auth = require('../middleware/auth')
const companyGuard = require('../middleware/companyGuard')

const {
  getMillingRecords,
  getMillingRecordById,
  createMillingRecord,
  completeMillingRecord,
  getMillingStatistics
} = require('../controllers/millingController')

// Import validators (to be implemented)
const {
  validateMillingProcess
} = require('../validators/millingValidator')

// Apply authentication and company isolation to all routes
router.use(auth)
router.use(companyGuard)

/**
 * @route   GET /api/milling
 * @desc    Get milling history with filtering and pagination
 * @access  Private (Company users)
 */
router.get('/', getMillingRecords)

/**
 * @route   GET /api/milling/statistics
 * @desc    Get milling efficiency statistics
 * @access  Private (Company users)
 */
router.get('/statistics', getMillingStatistics)

/**
 * @route   GET /api/milling/:id
 * @desc    Get single milling record details
 * @access  Private (Company users)
 */
router.get('/:id', getMillingRecordById)

/**
 * @route   POST /api/milling
 * @desc    Process milling (Start process: convert paddy to rice or initiate batch)
 * @access  Private (Company users)
 */
router.post('/', validateMillingProcess, createMillingRecord)

/**
 * @route   PUT /api/milling/:id/complete
 * @desc    Complete milling process (add rice stock to pending batch)
 * @access  Private (Company users)
 */
router.put('/:id/complete', completeMillingRecord)

module.exports = router