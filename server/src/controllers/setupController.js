const User = require('../models/User')
const { errorResponse, successResponse } = require('../utils/responseHandler')

/**
 * @desc    Create the first Super Admin (One-time setup)
 * @route   POST /api/setup/admin
 * @access  Public (Initial setup only)
 */
exports.setupSuperAdmin = async (req, res) => {
  try {
    // Check if any Admin already exists
    const adminCount = await User.countDocuments({ role: 'admin' })

    if (adminCount > 0) {
      return errorResponse(res, 'Setup already completed. Admin already exists.', 403)
    }

    const { name, email, phone, password } = req.body

    if (!name || !password || (!email && !phone)) {
      return errorResponse(res, 'Name, password, and (email or phone) are required', 400)
    }

    // Create the Super Admin
    const superAdmin = await User.create({
      name,
      email: email || `${phone}@temp.com`,
      phone,
      password,
      role: 'admin',
      isActive: true,
      isEmailVerified: true
    })

    const token = superAdmin.generateAuthToken()

    return successResponse(res, 'Admin created successfully. Setup complete.', {
      user: {
        id: superAdmin._id,
        name: superAdmin.name,
        email: superAdmin.email,
        role: superAdmin.role
      },
      token
    }, 201)
  } catch (error) {
    console.error('Setup Super Admin Error:', error)
    if (error.code === 11000) {
      return errorResponse(res, 'User with this email or phone already exists', 409)
    }
    return errorResponse(res, 'Error during setup', 500, error.message)
  }
}
