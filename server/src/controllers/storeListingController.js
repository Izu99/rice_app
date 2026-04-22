const StoreListing = require('../models/StoreListing');
const Company = require('../models/Company');
const { errorResponse, successResponse } = require('../utils/responseHandler');

/**
 * @route   GET /api/store/listings?category=paddy&page=1&limit=50
 * @access  Private
 */
exports.getListings = async (req, res) => {
  try {
    const { category, page = 1, limit = 50 } = req.query;
    const query = { isActive: true };
    if (category) query.category = category;

    const skip = (parseInt(page) - 1) * parseInt(limit);
    const [listings, total] = await Promise.all([
      StoreListing.find(query).sort({ createdAt: -1 }).skip(skip).limit(parseInt(limit)),
      StoreListing.countDocuments(query),
    ]);

    const currentCompanyId = req.companyId?.toString();
    const items = listings.map((l) => ({
      id: l._id.toString(),
      companyId: l.companyId.toString(),
      companyName: l.companyName,
      category: l.category,
      variety: l.variety,
      quantityKg: l.quantityKg,
      pricePerKg: l.pricePerKg,
      district: l.district,
      description: l.description,
      contactPhone: l.contactPhone,
      isOwn: currentCompanyId ? l.companyId.toString() === currentCompanyId : false,
      createdAt: l.createdAt,
      updatedAt: l.updatedAt,
    }));

    return successResponse(res, 'Listings fetched', {
      items,
      total,
      page: parseInt(page),
      pages: Math.ceil(total / parseInt(limit)),
    });
  } catch (error) {
    console.error('Get listings error:', error);
    return errorResponse(res, 'Error fetching listings', 500, error.message);
  }
};

/**
 * @route   GET /api/store/listings/stats
 * @access  Private
 */
exports.getStats = async (req, res) => {
  try {
    const baseQuery = { isActive: true };
    const [paddy, rice, riceMeal, other, companies, districts] = await Promise.all([
      StoreListing.countDocuments({ ...baseQuery, category: 'paddy' }),
      StoreListing.countDocuments({ ...baseQuery, category: 'rice' }),
      StoreListing.countDocuments({ ...baseQuery, category: 'riceMeal' }),
      StoreListing.countDocuments({ ...baseQuery, category: 'other' }),
      StoreListing.distinct('companyId', baseQuery),
      StoreListing.distinct('district', baseQuery),
    ]);

    return successResponse(res, 'Stats fetched', {
      counts: { paddy, rice, riceMeal, other },
      totalListings: paddy + rice + riceMeal + other,
      totalCompanies: companies.length,
      totalDistricts: districts.length,
    });
  } catch (error) {
    console.error('Get stats error:', error);
    return errorResponse(res, 'Error fetching stats', 500, error.message);
  }
};

/**
 * @route   GET /api/store/listings/my
 * @access  Private (company/manager/operator)
 */
exports.getMyListings = async (req, res) => {
  try {
    const listings = await StoreListing.find({
      companyId: req.companyId,
      isActive: true,
    }).sort({ createdAt: -1 });

    const items = listings.map((l) => ({
      id: l._id.toString(),
      companyId: l.companyId.toString(),
      companyName: l.companyName,
      category: l.category,
      variety: l.variety,
      quantityKg: l.quantityKg,
      pricePerKg: l.pricePerKg,
      district: l.district,
      description: l.description,
      contactPhone: l.contactPhone,
      isOwn: true,
      createdAt: l.createdAt,
      updatedAt: l.updatedAt,
    }));

    return successResponse(res, 'My listings fetched', items);
  } catch (error) {
    console.error('Get my listings error:', error);
    return errorResponse(res, 'Error fetching listings', 500, error.message);
  }
};

/**
 * @route   POST /api/store/listings
 * @access  Private (company/manager)
 */
exports.createListing = async (req, res) => {
  try {
    const { category, variety, quantityKg, pricePerKg, district, description, contactPhone, clientId } = req.body;

    if (!category || !variety || !district || !contactPhone) {
      return errorResponse(res, 'Category, variety, district, and contact phone are required', 400);
    }
    if (!['paddy', 'rice', 'riceMeal', 'other'].includes(category)) {
      return errorResponse(res, 'Invalid category', 400);
    }

    // Deduplicate by clientId
    if (clientId) {
      const existing = await StoreListing.findOne({ clientId });
      if (existing) {
        return successResponse(
          res,
          'Listing already exists',
          { id: existing._id.toString(), companyId: existing.companyId.toString(), companyName: existing.companyName, category: existing.category, variety: existing.variety, quantityKg: existing.quantityKg, pricePerKg: existing.pricePerKg, district: existing.district, description: existing.description, contactPhone: existing.contactPhone, isOwn: true, createdAt: existing.createdAt, updatedAt: existing.updatedAt },
          200
        );
      }
    }

    const company = await Company.findById(req.companyId);
    if (!company) return errorResponse(res, 'Company not found', 404);

    const listing = await StoreListing.create({
      companyId: req.companyId,
      companyName: company.name,
      category,
      variety: variety.trim(),
      quantityKg: parseFloat(quantityKg) || 0,
      pricePerKg: parseFloat(pricePerKg) || 0,
      district,
      description: description || '',
      contactPhone,
      clientId: clientId || undefined,
    });

    return successResponse(
      res,
      'Listing created successfully',
      { id: listing._id.toString(), companyId: listing.companyId.toString(), companyName: listing.companyName, category: listing.category, variety: listing.variety, quantityKg: listing.quantityKg, pricePerKg: listing.pricePerKg, district: listing.district, description: listing.description, contactPhone: listing.contactPhone, isOwn: true, createdAt: listing.createdAt, updatedAt: listing.updatedAt },
      201
    );
  } catch (error) {
    console.error('Create listing error:', error);
    return errorResponse(res, 'Error creating listing', 500, error.message);
  }
};

/**
 * @route   PUT /api/store/listings/:id
 * @access  Private (company/manager - own only)
 */
exports.updateListing = async (req, res) => {
  try {
    const listing = await StoreListing.findOne({
      _id: req.params.id,
      companyId: req.companyId,
      isActive: true,
    });
    if (!listing) return errorResponse(res, 'Listing not found or not authorized', 404);

    const { variety, quantityKg, pricePerKg, district, description, contactPhone } = req.body;
    if (variety) listing.variety = variety.trim();
    if (quantityKg !== undefined) listing.quantityKg = parseFloat(quantityKg) || 0;
    if (pricePerKg !== undefined) listing.pricePerKg = parseFloat(pricePerKg) || 0;
    if (district) listing.district = district;
    if (description !== undefined) listing.description = description;
    if (contactPhone) listing.contactPhone = contactPhone;

    await listing.save();

    return successResponse(res, 'Listing updated', {
      id: listing._id.toString(), companyId: listing.companyId.toString(), companyName: listing.companyName, category: listing.category, variety: listing.variety, quantityKg: listing.quantityKg, pricePerKg: listing.pricePerKg, district: listing.district, description: listing.description, contactPhone: listing.contactPhone, isOwn: true, createdAt: listing.createdAt, updatedAt: listing.updatedAt,
    });
  } catch (error) {
    console.error('Update listing error:', error);
    return errorResponse(res, 'Error updating listing', 500, error.message);
  }
};

/**
 * @route   DELETE /api/store/listings/:id
 * @access  Private (company/manager - own only)
 */
exports.deleteListing = async (req, res) => {
  try {
    const listing = await StoreListing.findOne({
      _id: req.params.id,
      companyId: req.companyId,
    });
    if (!listing) return errorResponse(res, 'Listing not found or not authorized', 404);

    listing.isActive = false;
    await listing.save();

    return successResponse(res, 'Listing deleted');
  } catch (error) {
    console.error('Delete listing error:', error);
    return errorResponse(res, 'Error deleting listing', 500, error.message);
  }
};
