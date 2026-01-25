const mongoose = require('mongoose')
const bcrypt = require('bcryptjs')
const jwt = require('jsonwebtoken')

const UserSchema = new mongoose.Schema({
  email: {
    type: String,
    required: [true, 'Email is required'],
    unique: true,
    lowercase: true,
    trim: true,
    validate: {
      validator: function (v) {
        return /^\w+([-.]?\w+)*@\w+([-.]?\w+)*(\.\w{2,3})+$/.test(v)
      },
      message: 'Please enter a valid email'
    }
  },
  phone: {
    type: String,
    unique: true,
    sparse: true,
    trim: true,
    validate: {
      validator: function (v) {
        if (!v) return true // Optional field
        return /^\+?[\d\s-()]+$/.test(v)
      },
      message: 'Please enter a valid phone number'
    }
  },
  nic: {
    type: String,
    trim: true,
    sparse: true,
    maxlength: [20, 'NIC cannot exceed 20 characters']
  },
  password: {
    type: String,
    required: [true, 'Password is required'],
    minlength: [8, 'Password must be at least 8 characters'],
    select: false
  },
  name: {
    type: String,
    required: [true, 'Name is required'],
    trim: true,
    maxlength: [100, 'Name cannot exceed 100 characters']
  },
  role: {
    type: String,
    enum: ['admin', 'company', 'customer', 'manager', 'operator', 'viewer'],
    required: [true, 'Role is required']
  },
  companyId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Company',
    required: function () {
      return this.role !== 'admin'
    },
    default: null
  },
  isActive: {
    type: Boolean,
    default: true
  },
  isEmailVerified: {
    type: Boolean,
    default: false
  },
  lastLoginAt: {
    type: Date
  },
  passwordResetToken: {
    type: String
  },
  passwordResetExpires: {
    type: Date
  }
}, {
  timestamps: true
})

// Indexes
UserSchema.index({ email: 1 }, { unique: true })
UserSchema.index({ phone: 1 }, { unique: true, sparse: true })
UserSchema.index({ companyId: 1 })
UserSchema.index({ role: 1 })

// Pre-save middleware: Hash password if modified
UserSchema.pre('save', async function (next) {
  if (!this.isModified('password')) return next()

  try {
    const saltRounds = parseInt(process.env.BCRYPT_ROUNDS) || 12
    const salt = await bcrypt.genSalt(saltRounds)
    this.password = await bcrypt.hash(this.password, salt)
    next()
  } catch (error) {
    next(error)
  }
})

// Pre-save middleware: Convert email to lowercase
UserSchema.pre('save', function (next) {
  if (this.isModified('email')) {
    this.email = this.email.toLowerCase()
  }
  next()
})

// Method to compare passwords
UserSchema.methods.comparePassword = async function (candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password)
}

// Method to generate JWT token
UserSchema.methods.generateAuthToken = function () {
  const payload = {
    id: this._id,
    email: this.email,
    role: this.role,
    companyId: this.companyId
  }

  const expiresIn = process.env.JWT_EXPIRE || '24h'

  return jwt.sign(payload, process.env.JWT_SECRET, {
    expiresIn
  })
}

// Method to remove sensitive fields from JSON response
UserSchema.methods.toJSON = function () {
  const userObject = this.toObject()
  delete userObject.password
  delete userObject.passwordResetToken
  delete userObject.passwordResetExpires
  return userObject
}

module.exports = mongoose.model('User', UserSchema)
