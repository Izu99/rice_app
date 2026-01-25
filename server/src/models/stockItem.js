const mongoose = require('mongoose')

const StockItemSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Item name is required'],
    trim: true,
    maxlength: [100, 'Item name cannot exceed 100 characters']
  },
  itemType: {
    type: String,
    enum: ['paddy', 'rice'],
    required: [true, 'Item type is required']
  },
  totalWeightKg: {
    type: Number,
    required: [true, 'Total weight is required'],
    default: 0,
    min: [0, 'Total weight cannot be negative']
  },
  totalBags: {
    type: Number,
    required: [true, 'Total bags is required'],
    default: 0,
    min: [0, 'Total bags cannot be negative']
  },
  pricePerKg: {
    type: Number,
    required: [true, 'Price per kg is required'],
    default: 0,
    min: [0, 'Price per kg cannot be negative']
  },
  avgPurchasePrice: {
    type: Number,
    min: [0, 'Average purchase price cannot be negative']
  },
  minimumStock: {
    type: Number,
    default: 10,
    min: [0, 'Minimum stock cannot be negative']
  },
  description: {
    type: String,
    trim: true,
    maxlength: [500, 'Description cannot exceed 500 characters']
  },
  companyId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Company',
    required: [true, 'Company ID is required']
  },
  sourceMillingBatch: {
    type: String,
    trim: true
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
  timestamps: true,
  collection: 'stock'
})

// Compound unique index for name + itemType + companyId
StockItemSchema.index({ name: 1, itemType: 1, companyId: 1 }, { unique: true })

// Other indexes
StockItemSchema.index({ companyId: 1 })
StockItemSchema.index({ itemType: 1 })
StockItemSchema.index({ clientId: 1 }, { unique: true, sparse: true })

// Virtual for total value
StockItemSchema.virtual('totalValue').get(function () {
  return this.totalWeightKg * this.pricePerKg
})

// Virtual for low stock status
StockItemSchema.virtual('isLowStock').get(function () {
  return this.totalWeightKg < this.minimumStock
})

// Ensure virtual fields are serialized
StockItemSchema.set('toJSON', { virtuals: true })
StockItemSchema.set('toObject', { virtuals: true })

// Pre-save middleware to set avgPurchasePrice if not set
StockItemSchema.pre('save', function (next) {
  if (!this.avgPurchasePrice && this.pricePerKg > 0) {
    this.avgPurchasePrice = this.pricePerKg
  }
  next()
})

// Method to update stock
StockItemSchema.methods.updateStock = async function (weightKg, bags = 0, operation = 'add') {
  const weightChange = operation === 'subtract' ? -weightKg : weightKg
  const bagChange = operation === 'subtract' ? -bags : bags

  this.totalWeightKg += weightChange
  this.totalBags += bagChange

  // Ensure stock doesn't go negative
  if (this.totalWeightKg < 0) this.totalWeightKg = 0
  if (this.totalBags < 0) this.totalBags = 0

  return this.save()
}

// Method to update average purchase price (weighted average)
StockItemSchema.methods.updateAvgPurchasePrice = async function (newPrice, quantityToAdd) {
  if (!this.avgPurchasePrice || this.totalWeightKg === 0) {
    this.avgPurchasePrice = newPrice
  } else {
    const currentTotalValue = this.avgPurchasePrice * this.totalWeightKg
    const addedValue = newPrice * quantityToAdd
    const newTotalWeight = this.totalWeightKg + quantityToAdd

    if (newTotalWeight > 0) {
      this.avgPurchasePrice = (currentTotalValue + addedValue) / newTotalWeight
    } else {
      this.avgPurchasePrice = newPrice
    }
  }

  return this.save()
}

// Static method to get stock summary for company
StockItemSchema.statics.getStockSummary = async function (companyId) {
  const summary = await this.aggregate([
    { $match: { companyId, isActive: true } },
    {
      $group: {
        _id: '$itemType',
        totalKg: { $sum: '$totalWeightKg' },
        totalBags: { $sum: '$totalBags' },
        totalValue: { $sum: { $multiply: ['$totalWeightKg', '$pricePerKg'] } },
        itemCount: { $sum: 1 }
      }
    }
  ])

  return {
    paddy: summary.find(s => s._id === 'paddy') || { totalKg: 0, totalBags: 0, totalValue: 0, itemCount: 0 },
    rice: summary.find(s => s._id === 'rice') || { totalKg: 0, totalBags: 0, totalValue: 0, itemCount: 0 }
  }
}

// Method to get item details with status
StockItemSchema.methods.getDetails = function () {
  return {
    id: this._id,
    name: this.name,
    itemType: this.itemType,
    totalWeightKg: this.totalWeightKg,
    totalBags: this.totalBags,
    pricePerKg: this.pricePerKg,
    avgPurchasePrice: this.avgPurchasePrice,
    totalValue: this.totalValue,
    minimumStock: this.minimumStock,
    isLowStock: this.isLowStock,
    description: this.description,
    sourceMillingBatch: this.sourceMillingBatch,
    isActive: this.isActive,
    lastUpdated: this.updatedAt
  }
}

module.exports = mongoose.model('StockItem', StockItemSchema)
