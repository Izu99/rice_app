const mongoose = require('mongoose')

const CompanySchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Company name is required'],
    trim: true,
    maxlength: [100, 'Company name cannot exceed 100 characters']
  },
  ownerName: {
    type: String,
    required: [true, 'Owner name is required'],
    trim: true,
    maxlength: [100, 'Owner name cannot exceed 100 characters']
  },
  email: {
    type: String,
    required: [true, 'Company email is required'],
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
    required: [true, 'Contact phone is required'],
    unique: true,
    trim: true,
    validate: {
      validator: function (v) {
        return /^\+?[\d\s-()]+$/.test(v)
      },
      message: 'Please enter a valid phone number'
    }
  },
  address: {
    type: String,
    trim: true,
    maxlength: [200, 'Address cannot exceed 200 characters']
  },
  registrationNumber: {
    type: String,
    unique: true,
    sparse: true,
    trim: true,
    maxlength: [50, 'Registration number cannot exceed 50 characters']
  },
  logoUrl: {
    type: String,
    trim: true
  },
  status: {
    type: String,
    enum: ['pending', 'active', 'inactive', 'suspended'],
    default: 'pending'
  },
  isEmailVerified: {
    type: Boolean,
    default: false
  },
  maxUsers: {
    type: Number,
    default: 5,
    min: [1, 'Maximum users must be at least 1']
  },
  currentUsers: {
    type: Number,
    default: 1,
    min: [0, 'Current users cannot be negative']
  },
  subscription: {
    plan: {
      type: String,
      enum: ['free', 'basic', 'premium', 'enterprise'],
      default: 'free'
    },
    startDate: {
      type: Date
    },
    endDate: {
      type: Date
    },
    isActive: {
      type: Boolean,
      default: true
    }
  },
  settings: {
    defaultMillingPercentage: {
      type: Number,
      default: 65,
      min: [0, 'Milling percentage cannot be negative'],
      max: [100, 'Milling percentage cannot exceed 100']
    },
    lowStockThreshold: {
      type: Number,
      default: 100,
      min: [0, 'Stock threshold cannot be negative']
    },
    currency: {
      type: String,
      default: 'LKR',
      enum: ['LKR', 'USD', 'EUR', 'INR']
    },
    dateFormat: {
      type: String,
      default: 'DD/MM/YYYY',
      enum: ['DD/MM/YYYY', 'MM/DD/YYYY', 'YYYY-MM-DD']
    },
    timezone: {
      type: String,
      default: 'Asia/Colombo'
    }
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'Created by is required']
  }
}, {
  timestamps: true
})

// Indexes
CompanySchema.index({ email: 1 }, { unique: true })
CompanySchema.index({ phone: 1 }, { unique: true })
CompanySchema.index({ registrationNumber: 1 }, { unique: true, sparse: true })
CompanySchema.index({ status: 1 })

// Virtual for getting company users
CompanySchema.virtual('users', {
  ref: 'User',
  localField: '_id',
  foreignField: 'companyId'
})

// Ensure virtual fields are serialized
CompanySchema.set('toJSON', { virtuals: true })
CompanySchema.set('toObject', { virtuals: true })

// Pre-save middleware to validate subscription dates
CompanySchema.pre('save', function (next) {
  if (this.subscription && this.subscription.startDate && this.subscription.endDate) {
    if (this.subscription.startDate >= this.subscription.endDate) {
      return next(new Error('Subscription end date must be after start date'))
    }
  }
  next()
})

// Method to check if company can add more users
CompanySchema.methods.canAddUser = function () {
  return this.currentUsers < this.maxUsers
}

// Method to increment user count
CompanySchema.methods.incrementUserCount = async function () {
  if (!this.canAddUser()) {
    throw new Error('Maximum user limit reached for this company')
  }
  this.currentUsers += 1
  return this.save()
}

// Method to decrement user count
CompanySchema.methods.decrementUserCount = async function () {
  if (this.currentUsers > 0) {
    this.currentUsers -= 1
    return this.save()
  }
  return this
}

module.exports = mongoose.model('Company', CompanySchema)
