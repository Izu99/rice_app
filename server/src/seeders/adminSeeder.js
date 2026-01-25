const User = require('../models/User')

async function seedAdmin () {
  try {
    // Check if admin already exists
    const existingAdmin = await User.findOne({ role: 'admin' })

    if (existingAdmin) {
      console.log('✅ Admin already exists:', existingAdmin.email)
      return
    }

    // Validate required environment variables
    const adminEmail = process.env.ADMIN_EMAIL || process.env.SUPER_ADMIN_EMAIL
    const adminPassword = process.env.ADMIN_PASSWORD || process.env.SUPER_ADMIN_PASSWORD
    const adminName = process.env.ADMIN_NAME || process.env.SUPER_ADMIN_NAME

    if (!adminEmail || !adminPassword || !adminName) {
      console.error('❌ Missing required environment variables for Admin creation')
      console.error('Required: ADMIN_EMAIL, ADMIN_PASSWORD, ADMIN_NAME (or legacy SUPER_ADMIN counterparts)')
      return
    }

    // Create admin
    const admin = new User({
      email: adminEmail,
      password: adminPassword, // Will be hashed by pre-save middleware
      name: adminName,
      role: 'admin',
      companyId: null, // Global admin has no company
      isActive: true,
      isEmailVerified: true
    })

    await admin.save()

    console.log('✅ Admin created successfully:', admin.email)
    console.log('🔐 Please change the default password after first login')
  } catch (error) {
    console.error('❌ Error seeding Admin:', error.message)
    throw error
  }
}

// Export for use in other files
module.exports = seedAdmin

// Allow direct execution
if (require.main === module) {
  require('dotenv').config()
  const connectDB = require('../config/database')

  connectDB().then(() => {
    seedAdmin().then(() => {
      console.log('🎉 Admin seeding completed')
      process.exit(0)
    }).catch((error) => {
      console.error('💥 Admin seeding failed:', error)
      process.exit(1)
    })
  }).catch((error) => {
    console.error('💥 Database connection failed:', error)
    process.exit(1)
  })
}
