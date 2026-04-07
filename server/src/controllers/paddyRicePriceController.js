const PaddyRicePrice = require("../models/PaddyRicePrice");
const Company = require("../models/Company");
const { errorResponse, successResponse } = require("../utils/responseHandler");
const mongoose = require("mongoose");

/**
 * @desc    Add a new paddy rice price
 * @route   POST /api/paddy-rice-price
 * @access  Private (Company users only)
 */
exports.addPrice = async (req, res) => {
	try {
		const { price, priceRangeEnd, notes, qualityGrade, priceType } = req.body;
		const companyId = req.companyId;
		const userId = req.user.id;

		// Validation
		if (!price || price < 0) {
			return errorResponse(res, "Valid price is required", 400);
		}

		// Get company to get district
		const company = await Company.findById(companyId);
		if (!company) {
			return errorResponse(res, "Company not found", 404);
		}

		const district = company.district;

		// Create price entry
		const paddyRicePrice = await PaddyRicePrice.create({
			companyId,
			district,
			price,
			priceRangeEnd: priceRangeEnd || null,
			createdBy: userId,
			notes: notes || null,
			qualityGrade: qualityGrade || "standard",
			priceType: priceType || "paddy",
			isActive: true,
		});

		// Populate company info
		await paddyRicePrice.populate("companyId", "name");
		await paddyRicePrice.populate("createdBy", "name email");

		return successResponse(
			res,
			"Paddy rice price added successfully",
			paddyRicePrice.toPublicJSON(),
			201,
		);
	} catch (error) {
		console.error("Add Price Error:", error);
		return errorResponse(res, "Error adding price", 500, error.message);
	}
};

/**
 * @desc    Get paddy rice prices for a district
 * @route   GET /api/paddy-rice-price/district/:district
 * @access  Private (Authenticated users)
 */
exports.getPricesByDistrict = async (req, res) => {
	try {
		const { district } = req.params;
		const { limit = 50, page = 1, sortBy = "createdAt", sortOrder = "desc" } = req.query;

		if (!district) {
			return errorResponse(res, "District is required", 400);
		}

		// Build sort
		const sort = {};
		sort[sortBy] = sortOrder === "desc" ? -1 : 1;

		// Get prices for district
		const prices = await PaddyRicePrice.find({
			district,
			isActive: true,
		})
			.populate("companyId", "name")
			.populate("createdBy", "name email")
			.sort(sort)
			.limit(limit * 1)
			.skip((page - 1) * limit);

		const total = await PaddyRicePrice.countDocuments({
			district,
			isActive: true,
		});

		const data = {
			prices: prices.map((p) => p.toPublicJSON()),
			pagination: {
				total,
				limit: limit * 1,
				page: page * 1,
				pages: Math.ceil(total / limit),
			},
		};

		return successResponse(res, "Prices retrieved successfully", data);
	} catch (error) {
		console.error("Get Prices Error:", error);
		return errorResponse(res, "Error retrieving prices", 500, error.message);
	}
};

/**
 * @desc    Get paddy rice prices added by current company
 * @route   GET /api/paddy-rice-price/company/my-prices
 * @access  Private (Company users only)
 */
exports.getMyCompanyPrices = async (req, res) => {
	try {
		const companyId = req.companyId;
		const { limit = 50, page = 1, sortBy = "createdAt", sortOrder = "desc" } = req.query;

		// Build sort
		const sort = {};
		sort[sortBy] = sortOrder === "desc" ? -1 : 1;

		const prices = await PaddyRicePrice.find({
			companyId,
			isActive: true,
		})
			.populate("createdBy", "name email")
			.sort(sort)
			.limit(limit * 1)
			.skip((page - 1) * limit);

		const total = await PaddyRicePrice.countDocuments({
			companyId,
			isActive: true,
		});

		const data = {
			prices: prices.map((p) => p.toPublicJSON()),
			pagination: {
				total,
				limit: limit * 1,
				page: page * 1,
				pages: Math.ceil(total / limit),
			},
		};

		return successResponse(res, "Your prices retrieved successfully", data);
	} catch (error) {
		console.error("Get My Prices Error:", error);
		return errorResponse(res, "Error retrieving your prices", 500, error.message);
	}
};

/**
 * @desc    Update a paddy rice price entry
 * @route   PUT /api/paddy-rice-price/:id
 * @access  Private (Company users only - only their own entries)
 */
exports.updatePrice = async (req, res) => {
	try {
		const { id } = req.params;
		const { price, priceRangeEnd, notes, qualityGrade, priceType } = req.body;
		const companyId = req.companyId;
		const userId = req.user.id;

		// Validate ID
		if (!mongoose.Types.ObjectId.isValid(id)) {
			return errorResponse(res, "Invalid price ID", 400);
		}

		// Find price entry
		const paddyRicePrice = await PaddyRicePrice.findById(id);
		if (!paddyRicePrice) {
			return errorResponse(res, "Price entry not found", 404);
		}

		// Authorization: Only the company owner can update
		if (paddyRicePrice.companyId.toString() !== companyId.toString()) {
			return errorResponse(res, "Not authorized to update this entry", 403);
		}

		// Update fields
		if (price !== undefined && price >= 0) paddyRicePrice.price = price;
		if (priceRangeEnd !== undefined) paddyRicePrice.priceRangeEnd = priceRangeEnd || null;
		if (notes !== undefined) paddyRicePrice.notes = notes;
		if (qualityGrade !== undefined) paddyRicePrice.qualityGrade = qualityGrade;
		if (priceType !== undefined && ["paddy", "rice"].includes(priceType)) paddyRicePrice.priceType = priceType;

		await paddyRicePrice.save();

		await paddyRicePrice.populate("companyId", "name");
		await paddyRicePrice.populate("createdBy", "name email");

		return successResponse(res, "Price updated successfully", paddyRicePrice.toPublicJSON());
	} catch (error) {
		console.error("Update Price Error:", error);
		return errorResponse(res, "Error updating price", 500, error.message);
	}
};

/**
 * @desc    Delete (deactivate) a paddy rice price entry
 * @route   DELETE /api/paddy-rice-price/:id
 * @access  Private (Company users only - only their own entries)
 */
exports.deletePrice = async (req, res) => {
	try {
		const { id } = req.params;
		const companyId = req.companyId;

		// Validate ID
		if (!mongoose.Types.ObjectId.isValid(id)) {
			return errorResponse(res, "Invalid price ID", 400);
		}

		// Find price entry
		const paddyRicePrice = await PaddyRicePrice.findById(id);
		if (!paddyRicePrice) {
			return errorResponse(res, "Price entry not found", 404);
		}

		// Authorization
		if (paddyRicePrice.companyId.toString() !== companyId.toString()) {
			return errorResponse(res, "Not authorized to delete this entry", 403);
		}

		// Soft delete
		paddyRicePrice.isActive = false;
		await paddyRicePrice.save();

		return successResponse(res, "Price deleted successfully", { id: paddyRicePrice._id });
	} catch (error) {
		console.error("Delete Price Error:", error);
		return errorResponse(res, "Error deleting price", 500, error.message);
	}
};

/**
 * @desc    Get all unique districts with price counts
 * @route   GET /api/paddy-rice-price/districts/list
 * @access  Private (Authenticated users)
 */
exports.getDistrictsList = async (req, res) => {
	try {
		// Get all districts from companies that have added prices
		const districts = await PaddyRicePrice.aggregate([
			{
				$match: { isActive: true },
			},
			{
				$group: {
					_id: "$district",
					count: { $sum: 1 },
					lastUpdated: { $max: "$createdAt" },
				},
			},
			{
				$sort: { _id: 1 },
			},
		]);

		const data = {
			districts: districts.map((d) => ({
				district: d._id,
				priceCount: d.count,
				lastUpdated: d.lastUpdated,
			})),
		};

		return successResponse(res, "Districts retrieved successfully", data);
	} catch (error) {
		console.error("Get Districts Error:", error);
		return errorResponse(res, "Error retrieving districts", 500, error.message);
	}
};

/**
 * @desc    Get all paddy rice prices (admin only)
 * @route   GET /api/paddy-rice-price/admin/all
 * @access  Private (Admin only)
 */
exports.getAllPricesAdmin = async (req, res) => {
	try {
		const { limit = 50, page = 1, district, priceType } = req.query;

		const filter = { isActive: true };
		if (district) filter.district = district;
		if (priceType && ["paddy", "rice"].includes(priceType)) filter.priceType = priceType;

		const prices = await PaddyRicePrice.find(filter)
			.populate("companyId", "name district")
			.populate("createdBy", "name")
			.sort({ createdAt: -1 })
			.limit(limit * 1)
			.skip((page - 1) * limit);

		const total = await PaddyRicePrice.countDocuments(filter);

		const data = {
			prices: prices.map((p) => p.toPublicJSON()),
			pagination: {
				total,
				limit: limit * 1,
				page: page * 1,
				pages: Math.ceil(total / limit),
			},
		};

		return successResponse(res, "All prices retrieved successfully", data);
	} catch (error) {
		console.error("Get All Prices Error:", error);
		return errorResponse(res, "Error retrieving prices", 500, error.message);
	}
};

/**
 * @desc    Get paddy rice price details by ID
 * @route   GET /api/paddy-rice-price/:id
 * @access  Private (Authenticated users)
 */
exports.getPriceById = async (req, res) => {
	try {
		const { id } = req.params;

		// Validate ID
		if (!mongoose.Types.ObjectId.isValid(id)) {
			return errorResponse(res, "Invalid price ID", 400);
		}

		const price = await PaddyRicePrice.findById(id)
			.populate("companyId", "name address")
			.populate("createdBy", "name email");

		if (!price || !price.isActive) {
			return errorResponse(res, "Price not found", 404);
		}

		return successResponse(res, "Price retrieved successfully", price.toPublicJSON());
	} catch (error) {
		console.error("Get Price Error:", error);
		return errorResponse(res, "Error retrieving price", 500, error.message);
	}
};
