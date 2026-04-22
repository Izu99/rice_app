const mongoose = require("mongoose");

const PaddyRicePriceSchema = new mongoose.Schema(
	{
		// Company reference
		companyId: {
			type: mongoose.Schema.Types.ObjectId,
			ref: "Company",
			required: [true, "Company ID is required"],
		},

		// District (denormalized from company for faster queries)
		district: {
			type: String,
			required: [true, "District is required"],
			trim: true,
		},

		// Price information
		price: {
			type: Number,
			required: [true, "Price is required"],
			min: [0, "Price cannot be negative"],
		},

		// Optional: Price range end (if user wants to provide range)
		priceRangeEnd: {
			type: Number,
			min: [0, "Price range end cannot be negative"],
			validate: {
				validator: function (v) {
					if (!v) return true; // Optional field
					return v >= this.price;
				},
				message: "Price range end must be greater than or equal to starting price",
			},
		},

		// Company owner/user who added the price
		createdBy: {
			type: mongoose.Schema.Types.ObjectId,
			ref: "User",
			required: [true, "Created by is required"],
		},

		// Status (for potential soft delete or deprecation)
		isActive: {
			type: Boolean,
			default: true,
		},

		// Notes/remarks (optional)
		notes: {
			type: String,
			trim: true,
			maxlength: [200, "Notes cannot exceed 200 characters"],
		},

		// Price type: paddy or rice
		priceType: {
			type: String,
			enum: ["paddy", "rice"],
			required: [true, "Price type is required"],
			default: "paddy",
		},

		// Quality grade (optional)
		qualityGrade: {
			type: String,
			enum: ["premium", "standard", "basic"],
			default: "standard",
		},

		// Paddy/rice variety (optional)
		variety: {
			type: String,
			trim: true,
			maxlength: [100, "Variety name cannot exceed 100 characters"],
		},
	},
	{
		timestamps: true,
	},
);

// Indexes for efficient queries
PaddyRicePriceSchema.index({ companyId: 1, createdAt: -1 });
PaddyRicePriceSchema.index({ district: 1, isActive: 1, createdAt: -1 });
PaddyRicePriceSchema.index({ district: 1, createdAt: -1 });
PaddyRicePriceSchema.index({ companyId: 1, district: 1, createdAt: -1 });

// Method to get price display (single or range)
PaddyRicePriceSchema.methods.getPriceDisplay = function () {
	if (this.priceRangeEnd && this.priceRangeEnd > this.price) {
		return `${this.price} - ${this.priceRangeEnd}`;
	}
	return `${this.price}`;
};

// Method to get full price info
PaddyRicePriceSchema.methods.toPublicJSON = function () {
	return {
		id: this._id,
		companyId: this.companyId,
		company: this.companyId, // populated via .populate("companyId", "name")
		district: this.district,
		price: this.price,
		priceRangeEnd: this.priceRangeEnd,
		priceDisplay: this.getPriceDisplay(),
		priceType: this.priceType,
		qualityGrade: this.qualityGrade,
		variety: this.variety,
		notes: this.notes,
		createdBy: this.createdBy,
		createdAt: this.createdAt,
		updatedAt: this.updatedAt,
	};
};

module.exports = mongoose.model("PaddyRicePrice", PaddyRicePriceSchema);
