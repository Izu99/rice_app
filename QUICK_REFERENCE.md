# 🎯 FEATURE OVERVIEW - Paddy Rice Price Management

## What Does This Feature Do?

**Company owners can add daily paddy rice prices for their district, and all app users can view prices by district in an easy-to-read list format.**

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         FLUTTER APP                             │
├───────────────────────┬───────────────────────┬─────────────────┤
│  Add Price Screen     │ View Districts Screen │ District Prices │
│  - User fills form    │ - Browse all          │ - List format   │
│  - Auto-populated     │   districts           │ - Company names │
│    district           │ - Price counts        │ - Prices        │
│  - Validates input    │                       │ - Quality grade │
└───────────────────────┴───────────────────────┴─────────────────┘
              │                  │                     │
              └──────────────────┼─────────────────────┘
                                 │
                         ┌───────▼────────┐
                         │   API SERVICE  │
                         └───────┬────────┘
                                 │
        ┌────────────────────────┼────────────────────────┐
        │                        │                        │
   ┌────▼────┐         ┌────────▼────────┐       ┌────────▼────────┐
   │ ADD      │         │ GET BY          │       │ GET MY          │
   │ PRICE    │         │ DISTRICT        │       │ PRICES          │
   └────┬────┘         └────────┬────────┘       └────────┬────────┘
        │                       │                        │
        └───────────────────────┼────────────────────────┘
                                │
                      ┌─────────▼──────────┐
                      │   EXPRESS SERVER   │
                      │   - Routes         │
                      │   - Controllers    │
                      │   - Validation     │
                      └─────────┬──────────┘
                                │
                             ┌──▼───┐
                             │MONGODB│
                             └───────┘
```

---

## 📋 Key Components

### 1. Database Models

#### Company (Updated)
```
{
  _id, name, ownerName, district, email, ...
}
```

#### PaddyRicePrice (NEW)
```
{
  _id,
  companyId,        // Which company added it
  district,         // District (from company)
  price,            // Starting price (e.g., 115.00)
  priceRangeEnd,    // Max price if range (e.g., 118.00)
  qualityGrade,     // Premium/Standard/Basic
  notes,            // Optional notes
  createdBy,        // User who added it
  isActive,         // Not deleted?
  createdAt,        // When
  updatedAt         // Last changed
}
```

### 2. API Endpoints (7 Total)

| Method | Endpoint | Purpose | Who Can Use |
|--------|----------|---------|-------------|
| POST | `/api/paddy-rice-price` | Add price | Company/Manager |
| GET | `/api/paddy-rice-price/district/:name` | View in district | Everyone |
| GET | `/api/paddy-rice-price/company/my-prices` | View own prices | Company/Manager |
| GET | `/api/paddy-rice-price/districts/list` | List districts | Everyone |
| GET | `/api/paddy-rice-price/:id` | Get one price | Everyone |
| PUT | `/api/paddy-rice-price/:id` | Edit own price | Company/Manager |
| DELETE | `/api/paddy-rice-price/:id` | Delete own price | Company/Manager |

### 3. Flutter Components

**Cubits** (Business Logic)
- `PriceManagementCubit` - All price operations

**Screens** (UI Pages)
- `AddPriceScreen` - Form to add price
- `ViewPricesByDistrictScreen` - Browse districts
- `PricesInDistrictScreen` - See prices for selected district

**Repositories** (Data Access)
- `PaddyRicePriceRepository` - Interface
- `PaddyRicePriceRepositoryImpl` - Implementation
- `PaddyRicePriceRemoteDataSource` - API calls

---

## 💡 How It Works - Step by Step

### Adding a Price
```
1. Company owner taps "Add Price"
   ↓
2. Form appears with fields:
   - Price (e.g., 115.00)
   - Price range (optional, e.g., 118.00)
   - Quality grade (Premium/Standard/Basic)
   - Notes (optional)
   - District (auto-filled, read-only)
   ↓
3. Owner fills and validates form
   ↓
4. Taps "Add Price"
   ↓
5. App sends POST request to backend
   ↓
6. Backend validates and saves to MongoDB
   ↓
7. Success message shown, screen closes
```

### Viewing Prices
```
1. User taps "Paddy Prices"
   ↓
2. App loads and shows list of districts
   Each shows: Name, Price Count, Last Updated
   ↓
3. User taps a district (e.g., "Colombo")
   ↓
4. App loads all prices for that district
   List shows:
   - Company A: Rs. 115.00 (Standard)
   - Company B: Rs. 115-118 (Standard)
   - Company C: Rs. 120.00 (Premium)
   - etc.
   ↓
5. User can see and compare prices
   ↓
6. Pull down to refresh anytime
```

---

## 🎯 Key Features

✅ **Price Ranges** - Can specify single price or range (e.g., 115-118)

✅ **Quality Grades** - Tag prices as Premium/Standard/Basic with color coding

✅ **Company-Grouped** - Prices shown by company, not averaged

✅ **District-Based** - Prices organized by district (from company profile)

✅ **List Format** - Simple list view, easy to scan and compare

✅ **Notes** - Add context to prices (max 200 chars)

✅ **History** - All prices kept (soft delete), no data loss

✅ **Pagination** - Handles large datasets (50 items per page)

✅ **Real-time** - Prices updated instantly

✅ **Role-Based** - Only company users can add, all can view

✅ **Secure** - JWT authentication + role checking

✅ **Responsive** - Works on all screen sizes

---

## 👥 User Roles & Permissions

### Company Owner/Manager
- ✅ Add prices for their district
- ✅ View all prices in any district
- ✅ Edit/delete only their own prices
- ❌ Cannot change district
- ❌ Cannot add prices for other districts

### Customers/Buyers
- ❌ Cannot add prices
- ✅ Can view all prices by district
- ❌ Cannot edit or delete prices

### Admin
- ✅ Can view all prices
- ✅ Can set district when registering companies
- ❌ Cannot add/edit/delete prices directly

---

## 📊 Data Flow

```
USER INPUT (Form)
    ↓
BLoC/CUBIT (Business Logic)
    ↓
REPOSITORY (Data Layer)
    ↓
REMOTE DATASOURCE (API Calls)
    ↓
HTTP REQUEST
    ↓
BACKEND SERVER (Express)
    ↓
VALIDATION & PROCESSING
    ↓
MONGODB (Storage)
    ↓
RESPONSE
    ↓
BLoC STATE UPDATED
    ↓
UI RE-RENDERS
    ↓
USER SEES RESULT
```

---

## 🔒 Security Features

1. **Authentication**: All endpoints require valid JWT token
2. **Authorization**: Role-based access control
3. **Ownership**: Users can only edit/delete their own prices
4. **Validation**: Input validation on both frontend and backend
5. **Soft Delete**: No permanent data loss
6. **Audit Trail**: Track who added/changed each price

---

## ⚡ Performance Optimizations

1. **Database Indexes**: Fast queries on district and company
2. **Pagination**: Limits data per request
3. **Denormalization**: District stored with price (no joins needed)
4. **Lazy Loading**: Only loads when needed
5. **Caching**: Network-aware, checks offline status

---

## 📱 UI Flow Diagram

```
LOGIN
  ↓
MAIN NAVIGATION
  ├─ Home
  ├─ Stock
  ├─ Reports
  ├─ Expenses
  ├─ People
  └─ Paddy Prices ◄─ NEW FEATURE
      ├─ Browse Districts (View all districts with prices)
      │   ├─ Colombo (8 prices)
      │   ├─ Kandy (3 prices)
      │   └─ Galle (5 prices)
      │
      └─ Add Price (Company users only)
          ├─ Price field
          ├─ Range toggle
          ├─ Quality grade
          ├─ Notes
          └─ Submit
      
      When district tapped:
      └─ Show all prices for that district
          ├─ Company A: Rs. 115
          ├─ Company B: Rs. 115-118
          └─ Company C: Rs. 120
```

---

## 🧪 Testing Scenarios

### Scenario 1: Company Adding Price
```
Given: Logged in as Company Manager
When: Navigate to Add Price
  AND Fill in all fields correctly
  AND Tap "Add Price"
Then: Price is saved
  AND Success message shown
  AND Price appears in "My Prices"
  AND Price appears in district list
```

### Scenario 2: Customer Viewing Prices
```
Given: Logged in as Customer
When: Navigate to "Paddy Prices"
Then: Can see list of districts
  AND Can tap district to see prices
  AND Can see all companies' prices
  AND Cannot add/edit prices (no button)
```

### Scenario 3: Price Range
```
Given: Company adding price with range
When: Toggle "Price Range" ON
  AND Enter min=115, max=118
Then: Price displays as "Rs. 115.00 - 118.00"
  AND Maximum > Minimum validation works
```

---

## 📚 Related Documentation

For more details, see:
1. **PRICE_MANAGEMENT_IMPLEMENTATION.md** - Technical deep dive
2. **PRICE_FEATURE_USER_GUIDE.md** - User instructions
3. **IMPLEMENTATION_COMPLETE.md** - Full checklist

---

## ✨ Example User Journey

### Company Owner - Morning Routine
```
1. Open app, login
2. Go to "Paddy Prices" → "Add Price"
3. Enter: Price=115.50, Max=117.50, Grade=Standard, Notes="Fresh stock"
4. District auto-filled as "Colombo"
5. Tap "Add Price" ✓
6. Success! Can view it in list immediately
7. Throughout day, can see competitors' prices by viewing district
```

### Buyer - Decision Making
```
1. Open app after login
2. Go to "Paddy Prices"
3. See list: Colombo (8 prices), Kandy (3), Galle (5)
4. Tap "Colombo"
5. See all 8 company prices:
   - Company A: Rs. 115 (Standard)
   - Company B: Rs. 115-118 (Standard)
   - Company C: Rs. 120 (Premium)
   - ...more
6. Compare prices, decide where to buy
7. Exit app with information
```

---

## 🚀 Ready to Use!

This feature is **fully implemented** and ready for:
- ✅ Testing
- ✅ Deployment
- ✅ User training
- ✅ Production use

No additional development needed for basic functionality.

---

**Version 1.0** | **April 2026** | **Status: Complete** ✅
