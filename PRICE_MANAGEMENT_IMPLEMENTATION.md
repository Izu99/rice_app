# Paddy Rice Price Management Feature - Implementation Guide

## Overview
This feature allows company owners to add daily paddy rice prices for their district, and enables all authenticated app users to view prices by district. The prices are displayed as a list showing all companies' prices in a district without averaging.

---

## Architecture & Tech Stack

### Backend (Node.js + MongoDB)
- **Framework**: Express.js
- **Database**: MongoDB with Mongoose
- **Authentication**: JWT with role-based access control

### Frontend (Flutter)
- **State Management**: Bloc/Cubit
- **HTTP Client**: Dio (via ApiService)
- **Navigation**: Go Router
- **Architecture**: Clean Architecture (Entity → Model → Repository → Datasource)

---

## Database Schema - MongoDB

### New Model: PaddyRicePrice
```javascript
{
  _id: ObjectId,
  companyId: ObjectId (ref: Company),      // Company that added the price
  district: String,                         // Denormalized for faster queries
  price: Number,                            // Starting price (e.g., 115.00)
  priceRangeEnd: Number (optional),        // End price if range (e.g., 118.00)
  qualityGrade: String (enum: ['premium', 'standard', 'basic']),
  notes: String (optional),                 // Additional notes (max 200 chars)
  createdBy: ObjectId (ref: User),         // User who added the price
  isActive: Boolean,                        // Soft delete flag
  timestamps: {
    createdAt: DateTime,
    updatedAt: DateTime
  }
}
```

### Updated Model: Company
Added field:
```javascript
district: String (required)  // District where the company operates
```

---

## API Endpoints

### Base URL: `/api/paddy-rice-price`

#### 1. **Add Price** (Company Users Only)
```
POST /api/paddy-rice-price
Authorization: Bearer {token}
Body: {
  "price": 115.00,
  "priceRangeEnd": 118.00,     // optional
  "qualityGrade": "standard",   // default: "standard"
  "notes": "Local paddy"        // optional
}
Response: 201
{
  "success": true,
  "message": "Paddy rice price added successfully",
  "data": { PaddyRicePrice object }
}
```

#### 2. **Get Prices by District** (Authenticated Users)
```
GET /api/paddy-rice-price/district/{district}?limit=50&page=1&sortBy=createdAt&sortOrder=desc
Authorization: Bearer {token}
Response: 200
{
  "success": true,
  "message": "Prices retrieved successfully",
  "data": {
    "prices": [{ PaddyRicePrice }, ...],
    "pagination": {
      "total": 10,
      "limit": 50,
      "page": 1,
      "pages": 1
    }
  }
}
```

#### 3. **Get Company's Own Prices**
```
GET /api/paddy-rice-price/company/my-prices?limit=50&page=1
Authorization: Bearer {token}
Response: 200
{
  "success": true,
  "message": "Your prices retrieved successfully",
  "data": {
    "prices": [{ PaddyRicePrice }, ...],
    "pagination": { ... }
  }
}
```

#### 4. **Get All Districts with Price Counts**
```
GET /api/paddy-rice-price/districts/list
Authorization: Bearer {token}
Response: 200
{
  "success": true,
  "data": {
    "districts": [
      {
        "district": "Colombo",
        "priceCount": 5,
        "lastUpdated": "2026-04-03T10:30:00.000Z"
      },
      ...
    ]
  }
}
```

#### 5. **Get Single Price by ID**
```
GET /api/paddy-rice-price/{id}
Authorization: Bearer {token}
Response: 200
```

#### 6. **Update Price** (Company Users Only - Own Entries)
```
PUT /api/paddy-rice-price/{id}
Authorization: Bearer {token}
Body: {
  "price": 116.00,
  "priceRangeEnd": 119.00,
  "qualityGrade": "premium",
  "notes": "Updated price"
}
Response: 200
```

#### 7. **Delete Price** (Company Users Only - Own Entries)
```
DELETE /api/paddy-rice-price/{id}
Authorization: Bearer {token}
Response: 200
```

---

## Flutter Implementation Details

### Directory Structure
```
lib/features/price_management/
├── price_management_injection.dart
├── presentation/
│   ├── cubit/
│   │   ├── price_management_cubit.dart
│   │   └── price_management_state.dart
│   ├── screens/
│   │   ├── add_price_screen.dart          // Company adds price
│   │   ├── view_prices_by_district_screen.dart  // Browse districts
│   │   └── prices_in_district_screen.dart       // View prices in district
│   └── widgets/
│       └── price_list_item.dart
data/
├── datasources/remote/
│   └── paddy_rice_price_remote_ds.dart
├── models/
│   └── paddy_rice_price_model.dart
└── repositories/
    └── paddy_rice_price_repository_impl.dart
domain/
├── entities/
│   └── paddy_rice_price_entity.dart
└── repositories/
    └── paddy_rice_price_repository.dart
```

### Screen Flows

#### 1. **Add Price Screen** (`/prices/add`)
- Company users can enter:
  - **Price**: Required (e.g., 115.00)
  - **Price Range**: Optional (with toggle)
    - If enabled, can enter max price (must be > min price)
  - **Quality Grade**: Dropdown (Premium/Standard/Basic)
  - **Notes**: Optional (max 200 chars)
- District is auto-populated from company profile (read-only)
- Success shows toast, closes, returns to previous screen

#### 2. **View Districts Screen** (`/prices`)
- Shows all districts with at least one price listing
- For each district displays:
  - District name
  - Number of prices listed
  - Last updated date
- Tap to view all prices in that district

#### 3. **Prices in District Screen** (`/prices/district/{district}`)
- Shows list of all prices for selected district
- Each price card displays:
  - **Company Name**
  - **Quality Grade** (badge with color)
  - **Price** (highlighted in primary color)
    - Single price: "Rs. 115.00"
    - Range: "Rs. 115.00 - 118.00"
  - **Date Added**
  - **Added By** (username)
  - **Notes** (info icon if present)
- Pull-to-refresh available
- Shows empty state when no prices

### Cubit Methods

```dart
class PriceManagementCubit extends Cubit<PriceManagementState> {
  // Load districts
  Future<void> initialize()
  Future<void> loadDistricts()

  // Load prices by district
  Future<void> loadPricesByDistrict(String district, {int page = 1})

  // Load company's own prices
  Future<void> loadMyPrices({int page = 1})

  // Add price
  Future<void> addPrice({
    required double price,
    double? priceRangeEnd,
    String qualityGrade = 'standard',
    String? notes,
  })

  // Update price
  Future<void> updatePrice(String id, {
    required double price,
    double? priceRangeEnd,
    String? qualityGrade,
    String? notes,
  })

  // Delete price
  Future<void> deletePrice(String id)

  // Pagination
  Future<void> loadNextPage()
  Future<void> loadPreviousPage()

  // Utilities
  Future<void> reload()
  void clearError()
}
```

---

## Integration Steps

### 1. **Backend Setup**

Already completed:
- ✅ Company model updated with `district` field
- ✅ PaddyRicePrice model created
- ✅ Controller with all CRUD operations
- ✅ Routes registered at `/api/paddy-rice-price`
- ✅ Role-based access control (company/manager can add, all authenticated users can view)

### 2. **Frontend Setup**

Already completed:
- ✅ Dependency injection configured
- ✅ Bloc provider registered in app.dart
- ✅ Routes added to router
- ✅ All screens and widgets created

### 3. **Navigation Integration**

Add buttons to navigate to price management:

```dart
// In Home Screen or Main Navigation
IconButton(
  icon: const Icon(Icons.local_florist),  // Rice icon
  label: 'Paddy Prices',
  onPressed: () => context.push('/prices'),
),

// In Company Dashboard (if available)
ElevatedButton(
  onPressed: () => context.push('/prices/add'),
  child: const Text('Add Today\'s Price'),
),
```

---

## User Roles & Permissions

### Company Users (Manager/Company)
- ✅ Can add prices (auto-populated with their district)
- ✅ Can view all prices by district
- ✅ Can update/delete only their own prices
- ❌ Cannot set district (comes from company profile)
- ❌ Cannot view admin panel

### Other Users (Customer/Operator/Viewer)
- ✅ Can view all prices by district
- ❌ Cannot add prices
- ❌ Cannot modify prices

### Admin
- ✅ Can view all prices
- ✅ Can specify district when creating companies

---

## Data Display Format

### Price Display Logic
```dart
// Single price
price = 115.00 → Display: "Rs. 115.00"

// Price range
price = 115.00, priceRangeEnd = 118.00 → Display: "Rs. 115.00 - 118.00"
```

### Important Notes
- **No averaging**: All prices from all companies in a district are shown
- **No filtering**: Multiple entries from same company or different companies are all displayed
- **Chronological order**: Latest prices appear first (by default)
- **Company isolation**: Each company can only manage their own prices

---

## Testing Checklist

### Backend Tests
1. ✅ Admin can create company with district field
2. ✅ Company user can add price
3. ✅ Price range validation works (end > start)
4. ✅ Get prices by district returns all prices
5. ✅ Get my prices returns only company's prices
6. ✅ Non-company users cannot add prices
7. ✅ Users can only delete their own prices
8. ✅ Pagination works correctly
9. ✅ District list shows accurate counts
10. ✅ Soft delete works (isActive flag)

### Frontend Tests
1. ✅ Add Price screen validates inputs
2. ✅ Price range toggle works
3. ✅ District is read-only and auto-populated
4. ✅ View Districts shows correct count
5. ✅ Prices in District screen shows all prices
6. ✅ Pull-to-refresh works
7. ✅ Pagination navigates correctly
8. ✅ Empty states display properly
9. ✅ Error messages show correctly
10. ✅ UI matches existing app design

---

## Styling & Design

### Colors Used (from AppColors)
- `primary`: Primary action buttons and highlights
- `success`: Standard quality grade badge
- `warning`: Basic quality grade badge
- `error`: Error states and delete actions
- `grey500-grey700`: Text and secondary elements

### Card Design
- Border radius: 12px
- Padding: 16px
- Shadow: Subtle elevation
- Consistent with other transaction cards in the app

### Quality Grade Badges
- **Premium**: Gold/Amber background
- **Standard**: Green background (success color)
- **Basic**: Orange background (warning color)

---

## Error Handling

### Common Errors & Handling
1. **No internet**: Network failure message + retry button
2. **Invalid price**: Validation error on input
3. **Unauthorized**: Auto-redirects to login
4. **Price range validation**: Must be > min price
5. **Duplicate prices**: Allowed (multiple entries per company)
6. **Server errors**: Generic message with option to retry

---

## Performance Optimizations

1. **Pagination**: Loads 50 items by default, paginated for large datasets
2. **Indexing**: Database indexes on:
   - `{companyId: 1, district: 1, createdAt: -1}`
   - `{district: 1, isActive: 1, createdAt: -1}`
3. **Soft Delete**: Uses `isActive` flag instead of hard delete
4. **Denormalization**: District stored with price for faster queries
5. **Lazy Loading**: Cubit only loads when needed

---

## Future Enhancements

1. Export prices to CSV
2. Price history/trends chart
3. Alert when price changes significantly
4. Admin ability to moderate/remove inappropriate prices
5. Price notifications to subscribed users
6. Bulk price import/edit
7. Quality-wise price comparison
8. Historical price analysis

---

## Dependencies

**Backend**
- mongoose
- express
- express-validator
- bcryptjs
- jsonwebtoken

**Frontend**
- flutter_bloc
- dartz (for Either type)
- go_router
- equatable
- dio (via ApiService)

---

## File Checklist

### Backend Files Created/Modified
- [x] `/server/src/models/Company.js` - Added district field
- [x] `/server/src/models/PaddyRicePrice.js` - New model
- [x] `/server/src/controllers/paddyRicePriceController.js` - New controller
- [x] `/server/src/routes/paddyRicePriceRoutes.js` - New routes
- [x] `/server/src/routes/index.js` - Registered new routes
- [x] `/server/src/routes/adminRoutes.js` - Updated company creation validator
- [x] `/server/src/controllers/adminController.js` - Updated createCompany

### Frontend Files Created/Modified
- [x] `/client/lib/domain/entities/paddy_rice_price_entity.dart`
- [x] `/client/lib/data/models/paddy_rice_price_model.dart`
- [x] `/client/lib/domain/repositories/paddy_rice_price_repository.dart`
- [x] `/client/lib/data/repositories/paddy_rice_price_repository_impl.dart`
- [x] `/client/lib/data/datasources/remote/paddy_rice_price_remote_ds.dart`
- [x] `/client/lib/features/price_management/price_management_injection.dart`
- [x] `/client/lib/features/price_management/presentation/cubit/price_management_cubit.dart`
- [x] `/client/lib/features/price_management/presentation/cubit/price_management_state.dart`
- [x] `/client/lib/features/price_management/presentation/screens/add_price_screen.dart`
- [x] `/client/lib/features/price_management/presentation/screens/view_prices_by_district_screen.dart`
- [x] `/client/lib/features/price_management/presentation/screens/prices_in_district_screen.dart`
- [x] `/client/lib/features/price_management/presentation/widgets/price_list_item.dart`
- [x] `/client/lib/injection_container.dart` - Updated with price management injection
- [x] `/client/lib/app.dart` - Added PriceManagementCubit provider
- [x] `/client/lib/routes/app_router.dart` - Added price management routes

---

## Next Steps for Deployment

1. **Test Backend APIs** using Postman or similar tool
2. **Run migration** to add `district` field to existing companies (required field)
3. **Test Flutter App** on physical device/emulator
4. **Create admin UI** for registering districts (optional, can be done via API)
5. **Train users** on how to use the feature
6. **Monitor** for issues in production

---

## Support & Troubleshooting

If you encounter issues:

1. **Backend won't start**
   - Check MongoDB connection
   - Verify environment variables (JWT_SECRET, PORT, etc.)
   - Check Node version (14+)

2. **Flutter app crashes on price screen**
   - Check network connectivity
   - Verify API endpoint URL in ApiService
   - Check token validity (might be expired)

3. **Prices not showing**
   - Verify district name matches exactly (case-sensitive)
   - Check if user is authenticated
   - Check database for records using Mongo compass

4. **Cannot add price**
   - Verify user role is 'company' or 'manager'
   - Check if company has district assigned
   - Verify form validation

---

## Questions or Issues?

Refer to this guide or check the code comments for detailed implementation specifics.
