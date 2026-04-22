const mongoose = require('mongoose');
const { Schema } = mongoose;

const StoreListingSchema = new Schema(
  {
    companyId: { type: Schema.Types.ObjectId, ref: 'Company', required: true, index: true },
    companyName: { type: String, required: true },
    category: {
      type: String,
      enum: ['paddy', 'rice', 'riceMeal', 'other'],
      required: true,
      index: true,
    },
    variety: { type: String, required: true, trim: true },
    quantityKg: { type: Number, default: 0, min: 0 },
    pricePerKg: { type: Number, default: 0, min: 0 },
    district: { type: String, required: true },
    description: { type: String, default: '', maxlength: 500 },
    contactPhone: { type: String, required: true },
    isActive: { type: Boolean, default: true, index: true },
    clientId: { type: String, sparse: true },
    isSynced: { type: Boolean, default: true },
  },
  { timestamps: true }
);

StoreListingSchema.index({ category: 1, isActive: 1, createdAt: -1 });
StoreListingSchema.index({ companyId: 1, isActive: 1, createdAt: -1 });

module.exports = mongoose.model('StoreListing', StoreListingSchema);
