const express = require('express')
const router = express.Router()
const customerController = require('../controllers/customerController')
const auth = require('../middleware/auth')
const companyGuard = require('../middleware/companyGuard')
const { validateObjectId } = require('../middleware/validator')
const {
  createCustomerValidation,
  updateCustomerValidation
} = require('../middleware/validators')

/**
 * All routes require authentication and company isolation
 */
router.use(auth)
router.use(companyGuard)

/**
 * @route   GET /api/customers/check-phone/:phone
 * @desc    Check if phone number exists
 * @access  Private (Company users)
 */
router.get('/check-phone/:phone', customerController.checkPhone)

/**
 * @route   GET /api/customers
 * @desc    Get all customers with filtering and pagination
 * @access  Private (Company users)
 */
router.get('/', customerController.getCustomers)

/**
 * @route   GET /api/customers/:id
 * @desc    Get customer by ID with transaction history
 * @access  Private (Company users)
 */
router.get('/:id',
  validateObjectId('id'),
  customerController.getCustomerById
)

/**
 * @route   GET /api/customers/:id/transactions
 * @desc    Get customer's transaction history
 * @access  Private (Company users)
 */
router.get('/:id/transactions',
  validateObjectId('id'),
  customerController.getCustomerTransactions
)

/**
 * @route   POST /api/customers
 * @desc    Create a new customer
 * @access  Private (Company users)
 */
router.post('/', ...createCustomerValidation, customerController.createCustomer)

/**
 * @route   PUT /api/customers/:id
 * @desc    Update customer
 * @access  Private (Company users)
 */
router.put('/:id',
  validateObjectId('id'),
  ...updateCustomerValidation,
  customerController.updateCustomer
)

/**
 * @route   DELETE /api/customers/:id
 * @desc    Delete customer (soft delete)
 * @access  Private (Company users)
 */
router.delete('/:id',
  validateObjectId('id'),
  customerController.deleteCustomer
)

module.exports = router
