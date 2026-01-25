const mongoose = require('mongoose')

const CustomerSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Customer name is required'],
    trim: true,
    maxlength: [100, 'Customer name cannot exceed 100 characters']
  },
  phone: {
    type: String,
    required: [true, 'Phone number is required'],
    trim: true,
    validate: {
      validator: function (v) {
        return /^\+?[\d\s-()]+$/.test(v)
      },
      message: 'Please enter a valid phone number'
    }
  },
  email: {
    type: String,
    trim: true,
    lowercase: true,
    validate: {
      validator: function (v) {
        if (!v) return true // Optional field
        return /^\w+([-.]?\w+)*@\w+([-.]?\w+)*(\.\w{2,3})+$/.test(v)
      },
      message: 'Please enter a valid email'
    }
  },
  address: {
    type: String,
    trim: true,
    maxlength: [200, 'Address cannot exceed 200 characters']
  },
  nic: {
    type: String,
    trim: true,
    sparse: true,
    maxlength: [20, 'NIC cannot exceed 20 characters']
  },
  secondaryPhone: {
    type: String,
    trim: true,
    validate: {
      validator: function (v) {
        if (!v) return true // Optional field
        return /^\+?[\d\s-()]+$/.test(v)
      },
      message: 'Please enter a valid secondary phone number'
    }
  },
  city: {
    type: String,
    trim: true,
    maxlength: [100, 'City cannot exceed 100 characters']
  },
  companyId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Company',
    required: [true, 'Company ID is required']
  },
  totalBuyAmount: {
    type: Number,
    default: 0,
    min: [0, 'Total buy amount cannot be negative']
  },
  totalSellAmount: {
    type: Number,
    default: 0,
    min: [0, 'Total sell amount cannot be negative']
  },
  balance: {
    type: Number,
    default: 0
  },
  notes: {
    type: String,
    trim: true,
    maxlength: [500, 'Notes cannot exceed 500 characters']
  },
  isActive: {
    type: Boolean,
    default: true
  },
  isSynced: {
    type: Boolean,
    default: true
  },
  clientId: {
    type: String,
    trim: true
  }
}, {
  timestamps: true
})

// Compound unique index for phone + companyId
CustomerSchema.index({ phone: 1, companyId: 1 }, { unique: true })

// Other indexes
CustomerSchema.index({ companyId: 1 })
CustomerSchema.index({ clientId: 1 }, { unique: true, sparse: true })
CustomerSchema.index({ city: 1 })

// Virtual for total transactions
CustomerSchema.virtual('totalTransactions').get(function () {
  return this.totalBuyAmount + this.totalSellAmount
})

// Ensure virtual fields are serialized
CustomerSchema.set('toJSON', { virtuals: true })
CustomerSchema.set('toObject', { virtuals: true })

// Pre-save middleware to calculate balance
CustomerSchema.pre('save', function (next) {
  this.balance = this.totalSellAmount - this.totalBuyAmount
  next()
})

// Method to update buy amount
CustomerSchema.methods.updateBuyAmount = async function (amount) {
  this.totalBuyAmount += amount
  return this.save()
}

// Method to update sell amount
CustomerSchema.methods.updateSellAmount = async function (amount) {
  this.totalSellAmount += amount
  return this.save()
}

// Method to get customer summary
CustomerSchema.methods.getSummary = function () {
  return {
    id: this._id,
    name: this.name,
    phone: this.phone,
    secondaryPhone: this.secondaryPhone,
    address: this.address,
    city: this.city,
    totalBuyAmount: this.totalBuyAmount,
    totalSellAmount: this.totalSellAmount,
    balance: this.balance,
    totalTransactions: this.totalTransactions,
    isActive: this.isActive
  }
}

module.exports = mongoose.model('Customer', CustomerSchema)
