const express = require('express')
const router = express.Router()
const authController = require('../controllers/authController')
const auth = require('../middleware/auth')
const {
  loginValidation,
  registerValidation,
  createAdminValidation,
  forgotPasswordValidation,
  resetPasswordValidation,
  changePasswordValidation
} = require('../middleware/validators')

/**
 * @route   POST /api/auth/register
 * @desc    Register new company and admin user
 * @access  Public
 */
router.post('/register', ...registerValidation, authController.register)

/**
 * @route   POST /api/auth/create-admin
 * @desc    Create admin user for existing company
 * @access  Public (temporary)
 */
router.post('/create-admin', ...createAdminValidation, authController.createAdminForCompany)

/**
 * @route   POST /api/auth/login
 * @desc    Login user
 * @access  Public
 */
router.post('/login', ...loginValidation, authController.login)

/**
 * @route   POST /api/auth/refresh-token
 * @desc    Refresh JWT token
 * @access  Private
 */
router.post('/refresh-token', auth, authController.refreshToken)

/**
 * @route   POST /api/auth/logout
 * @desc    Logout user
 * @access  Private
 */
router.post('/logout', auth, authController.logout)

/**
 * @route   GET /api/auth/me
 * @desc    Get current user profile
 * @access  Private
 */
router.get('/me', auth, authController.getMe)

/**
 * @route   POST /api/auth/forgot-password
 * @desc    Request password reset
 * @access  Public
 */
router.post('/forgot-password', ...forgotPasswordValidation, authController.forgotPassword)

/**
 * @route   POST /api/auth/reset-password
 * @desc    Reset password with token
 * @access  Public
 */
router.post('/reset-password', ...resetPasswordValidation, authController.resetPassword)

/**
 * @route   POST /api/auth/change-password
 * @desc    Change password for authenticated user
 * @access  Private
 */
router.post('/change-password', auth, ...changePasswordValidation, authController.changePassword)

module.exports = router
