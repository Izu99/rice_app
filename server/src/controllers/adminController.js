const Company = require("../models/Company");
const User = require("../models/User");
const Transaction = require("../models/Transaction");
const { validationResult } = require("express-validator");
const { errorResponse, successResponse } = require("../utils/responseHandler");
const mongoose = require("mongoose");

/**
 * @desc    Get Super Admin dashboard statistics
 * @route   GET /api/admin/dashboard
 * @access  Private (Super Admin only)
 */
exports.getDashboard = async (req, res) => {
	try {
		// Get company statistics
		const totalCompanies = await Company.countDocuments();
		const activeCompanies = await Company.countDocuments({ status: "active" });
		const pendingCompanies = await Company.countDocuments({ status: "pending" });
		const inactiveCompanies = await Company.countDocuments({ status: "inactive" });

		// Get user statistics
		const totalUsers = await User.countDocuments({ role: { $ne: "admin" } });

		// Get today's transactions count
		const today = new Date();
		today.setHours(0, 0, 0, 0);
		const tomorrow = new Date(today);
		tomorrow.setDate(tomorrow.getDate() + 1);

		const totalTransactionsToday = await Transaction.countDocuments({
			createdAt: { $gte: today, $lt: tomorrow },
		});

		// Get recent companies (last 5)
		const recentCompanies = await Company.find()
			.sort({ createdAt: -1 })
			.limit(5)
			.select("name status createdAt");

		// Get companies per month (simplified - would need aggregation in production)
		const companiesPerMonth = {}; // Placeholder - implement aggregation pipeline

		const data = {
			totalCompanies,
			activeCompanies,
			pendingCompanies,
			inactiveCompanies,
			totalUsers,
			totalTransactionsToday,
			recentCompanies,
			companiesPerMonth,
		};

		return successResponse(res, "Dashboard statistics retrieved successfully", data);
	} catch (error) {
		console.error("Dashboard Error:", error);
		return errorResponse(res, "Error retrieving dashboard statistics", 500, error.message);
	}
};

/**
 * @desc    Get all companies with filtering and pagination
 * @route   GET /api/admin/companies
 * @access  Private (Super Admin only)
 */
exports.getCompanies = async (req, res) => {
	try {
		const {
			status,
			search,
			page = 1,
			limit = 20,
			sortBy = "createdAt",
			sortOrder = "desc",
		} = req.query;

		// Build query
		const query = {};
		if (status) query.status = status;

		if (search) {
			query.$or = [
				{ name: { $regex: search, $options: "i" } },
				{ email: { $regex: search, $options: "i" } },
				{ phone: { $regex: search, $options: "i" } },
			];
		}

		// Build sort
		const sort = {};
		sort[sortBy] = sortOrder === "desc" ? -1 : 1;

		// Execute query with pagination
		const companies = await Company.find(query)
			.sort(sort)
			.limit(limit * 1)
			.skip((page - 1) * limit)
			.populate("createdBy", "name email");

		const total = await Company.countDocuments(query);
		const pages = Math.ceil(total / limit);

		const data = {
			companies,
			pagination: {
				total,
				page: parseInt(page),
				limit: parseInt(limit),
				pages,
			},
		};

		return successResponse(res, "Companies retrieved successfully", data);
	} catch (error) {
		console.error("Get Companies Error:", error);
		return errorResponse(res, "Error retrieving companies", 500, error.message);
	}
};

/**
 * @desc    Get single company details with statistics
 * @route   GET /api/admin/companies/:id
 * @access  Private (Super Admin only)
 */
exports.getCompanyById = async (req, res) => {
	try {
		const company = await Company.findById(req.params.id).populate("createdBy", "name email");

		if (!company) {
			return errorResponse(res, "Company not found", 404);
		}

		// Get company users
		const users = await User.find({ companyId: req.params.id }).select(
			"name email role isActive lastLoginAt",
		);

		// Get company statistics (placeholder - implement actual aggregations)
		const statistics = {
			totalTransactions: 0, // Implement aggregation
			totalRevenue: 0, // Implement aggregation
			totalCustomers: 0, // Implement aggregation
		};

		const data = {
			company,
			users,
			statistics,
		};

		return successResponse(res, "Company details retrieved successfully", data);
	} catch (error) {
		console.error("Get Company Error:", error);
		return errorResponse(res, "Error retrieving company details", 500, error.message);
	}
};

/**
 * @desc    Create new company and admin user
 * @route   POST /api/admin/companies
 * @access  Private (Super Admin only)
 */
exports.createCompany = async (req, res) => {
	const session = await mongoose.startSession();
	session.startTransaction();

	try {
		const errors = validationResult(req);
		if (!errors.isEmpty()) {
			return errorResponse(res, "Validation failed", 400, errors.array());
		}

		const { name, ownerName, email, phone, address, district, registrationNumber, password } =
			req.body;

		// Validate required fields
		if (!district) {
			return errorResponse(res, "District is required", 400);
		}

		// For Sri Lankan systems, use phone as primary login method
		// Email is optional, phone is required for login

		// Check if email already exists
		const existingCompany = await Company.findOne({ email }).session(session);
		if (existingCompany) {
			return errorResponse(res, "Company with this email already exists", 409);
		}

		// Check if phone already exists
		const existingPhone = await Company.findOne({ phone }).session(session);
		if (existingPhone) {
			return errorResponse(res, `Company with phone number "${phone}" already exists`, 409);
		}

		// Check if registrationNumber already exists (only if provided)
		if (registrationNumber && registrationNumber.trim() !== "") {
			const existingReg = await Company.findOne({ registrationNumber: registrationNumber.trim() }).session(session);
			if (existingReg) {
				return errorResponse(res, `Company with registration number "${registrationNumber}" already exists`, 409);
			}
		}

		// Create company object and remove optional empty fields to avoid unique index conflicts
		const companyData = {
			name,
			ownerName,
			email,
			phone,
			address,
			district,
			createdBy: req.user.id,
		};

		if (registrationNumber && registrationNumber.trim() !== "") {
			companyData.registrationNumber = registrationNumber.trim();
		}

		// Create company
		const company = await Company.create([companyData], { session });

		// Create admin user for the company (using phone as primary login)
		const adminUser = await User.create(
			[
				{
					email: email || `${phone}@temp.com`, // Optional email, use temp if not provided
					phone, // Phone is the primary login method
					password, // Will be hashed by pre-save middleware
					name: ownerName,
					role: "company",
					companyId: company[0]._id,
					isActive: true,
					isEmailVerified: true,
				},
			],
			{ session },
		);

		await session.commitTransaction();

		const data = {
			company: company[0],
			adminUser: {
				email: adminUser[0].email,
				phone: adminUser[0].phone,
				name: adminUser[0].name,
				role: adminUser[0].role,
				password, // Return the password so super admin can share it
			},
		};

		return successResponse(res, "Company created successfully", data, 201);
	} catch (error) {
		await session.abortTransaction();
		console.error("Create Company Error:", error);

		// Handle duplicate key errors
		if (error.code === 11000) {
			const field = Object.keys(error.keyPattern)[0];
			return errorResponse(res, `Company with this ${field} already exists`, 409);
		}

		return errorResponse(res, "Error creating company", 500, error.message);
	} finally {
		session.endSession();
	}
};

/**
 * @desc    Update company details
 * @route   PUT /api/admin/companies/:id
 * @access  Private (Super Admin only)
 */
exports.updateCompany = async (req, res) => {
	try {
		const errors = validationResult(req);
		if (!errors.isEmpty()) {
			return errorResponse(res, "Validation failed", 400, errors.array());
		}

		const allowedUpdates = [
			"name",
			"ownerName",
			"email",
			"phone",
			"address",
			"district",
			"registrationNumber",
			"status",
			"maxUsers",
			"settings",
		];

		const updates = {};
		allowedUpdates.forEach((field) => {
			if (req.body[field] !== undefined) {
				updates[field] = req.body[field];
			}
		});

		const company = await Company.findByIdAndUpdate(req.params.id, updates, {
			new: true,
			runValidators: true,
		});

		if (!company) {
			return errorResponse(res, "Company not found", 404);
		}

		return successResponse(res, "Company updated successfully", { company });
	} catch (error) {
		console.error("Update Company Error:", error);
		return errorResponse(res, "Error updating company", 500, error.message);
	}
};

/**
 * @desc    Change company status
 * @route   PATCH /api/admin/companies/:id/status
 * @access  Private (Super Admin only)
 */
exports.updateCompanyStatus = async (req, res) => {
	try {
		const errors = validationResult(req);
		if (!errors.isEmpty()) {
			return errorResponse(res, "Validation failed", 400, errors.array());
		}

		const { status, reason } = req.body;

		const company = await Company.findByIdAndUpdate(
			req.params.id,
			{ status },
			{ new: true, runValidators: false },
		);

		if (!company) {
			return errorResponse(res, "Company not found", 404);
		}

		// TODO: Implement user logout for suspended companies
		// TODO: Send notification emails

		return successResponse(res, `Company status updated to ${status}`);
	} catch (error) {
		console.error("Change Status Error:", error);
		return errorResponse(res, "Error updating company status", 500, error.message);
	}
};

/**
 * @desc    Delete company (Hard delete)
 * @route   DELETE /api/admin/companies/:id
 * @access  Private (Super Admin only)
 */
exports.deleteCompany = async (req, res) => {
	try {
		// Hard delete the company
		const company = await Company.findByIdAndDelete(req.params.id);

		if (!company) {
			return errorResponse(res, "Company not found", 404);
		}

		// Delete all users associated with this company
		await User.deleteMany({ companyId: req.params.id });

		// Note: In a production system with transactions, you might want to 
		// check for existing transactions before allowing a hard delete.

		return successResponse(res, "Company and associated users deleted successfully");
	} catch (error) {
		console.error("Delete Company Error:", error);
		return errorResponse(res, "Error deleting company", 500, error.message);
	}
};

/**
 * @desc    Reset company admin password
 * @route   POST /api/admin/companies/:id/reset-password
 * @access  Private (Super Admin only)
 */
exports.resetCompanyPassword = async (req, res) => {
	try {
		const { newPassword } = req.body;

		if (!newPassword) {
			return errorResponse(res, "New password is required", 400);
		}

		// Find admin user for the company
		const adminUser = await User.findOne({
			companyId: req.params.id,
			role: "company",
		});

		if (!adminUser) {
			return errorResponse(res, "Company admin user not found", 404);
		}

		// Update password
		adminUser.password = newPassword;
		await adminUser.save();

		return successResponse(res, "Password reset successfully");
	} catch (error) {
		console.error("Reset Password Error:", error);
		return errorResponse(res, "Error resetting password", 500, error.message);
	}
};
