# Postman Testing Guide

## Quick Start - Copy & Paste into Postman

### 1️⃣ REGISTER USER

**Method:** `POST`  
**URL:** `http://localhost:5000/api/auth/register`  
**Headers:**
```
Content-Type: application/json
```

**Body (raw JSON):**
```json
{
  "firstName": "Kasun",
  "lastName": "Perera",
  "nic": "199712345678",
  "address": "123 Main Street, Colombo 07",
  "phoneNumber": "+94771234567",
  "companyName": "Perera Rice Mill",
  "companyUserName": "kasunrice",
  "companyAddress": "456 Mill Road, Gampaha",
  "companyPhoneNumber": "+94112345678",
  "password": "Kasun@123",
  "confirmPassword": "Kasun@123"
}
```

**Expected Response (201):**
```json
{
  "success": true,
  "message": "User registered successfully",
  "data": {
    "user": {
      "id": "...",
      "firstName": "Kasun",
      "lastName": "Perera",
      "companyUserName": "kasunrice",
      ...
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  },
  "timestamp": "2025-12-04T11:17:00.000Z"
}
```

---

### 2️⃣ LOGIN USER

**Method:** `POST`  
**URL:** `http://localhost:5000/api/auth/login`  
**Headers:**
```
Content-Type: application/json
```

**Option 1: Login with Phone Number** ⭐ RECOMMENDED
```json
{
  "phoneNumber": "+94771234567",
  "password": "Kasun@123"
}
```

**Option 2: Login with Company Username**
```json
{
  "companyUserName": "kasunrice",
  "password": "Kasun@123"
}
```

> **Note:** Provide EITHER `phoneNumber` OR `companyUserName` (not both) along with the password.

**Expected Response (200):**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {
      "id": "...",
      "firstName": "Kasun",
      "lastName": "Perera",
      ...
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  },
  "timestamp": "2025-12-04T11:18:00.000Z"
}
```

**⚠️ IMPORTANT:** Copy the `token` from the response - you'll need it for protected routes!

---

### 3️⃣ GET CURRENT USER (Protected)

**Method:** `GET`  
**URL:** `http://localhost:5000/api/auth/me`  
**Headers:**
```
Authorization: Bearer YOUR_TOKEN_HERE
```

👉 Replace `YOUR_TOKEN_HERE` with the token from login response!

---

### 4️⃣ UPDATE PROFILE (Protected)

**Method:** `PUT`  
**URL:** `http://localhost:5000/api/auth/profile`  
**Headers:**
```
Content-Type: application/json
Authorization: Bearer YOUR_TOKEN_HERE
```

**Body (raw JSON):**
```json
{
  "firstName": "Kasun Updated",
  "phoneNumber": "+94779999999",
  "companyAddress": "New Address, Colombo"
}
```

---

### 5️⃣ CHANGE PASSWORD (Protected)

**Method:** `PUT`  
**URL:** `http://localhost:5000/api/auth/change-password`  
**Headers:**
```
Content-Type: application/json
Authorization: Bearer YOUR_TOKEN_HERE
```

**Body (raw JSON):**
```json
{
  "currentPassword": "Kasun@123",
  "newPassword": "NewPass@456",
  "confirmNewPassword": "NewPass@456"
}
```

---

## Additional Sample Users

### User 2 - Nuwan Silva
**Register:**
```json
{
  "firstName": "Nuwan",
  "lastName": "Silva",
  "nic": "198856789123",
  "address": "45 Temple Road, Kandy",
  "phoneNumber": "+94719876543",
  "companyName": "Silva Brothers Rice Mill",
  "companyUserName": "nuwansilva",
  "companyAddress": "789 Industrial Estate, Kurunegala",
  "companyPhoneNumber": "+94372223334",
  "password": "Nuwan@456",
  "confirmPassword": "Nuwan@456"
}
```

**Login (Phone):**
```json
{
  "phoneNumber": "+94719876543",
  "password": "Nuwan@456"
}
```

**Login (Username):**
```json
{
  "companyUserName": "nuwansilva",
  "password": "Nuwan@456"
}
```

---

### User 3 - Amara Fernando
**Register:**
```json
{
  "firstName": "Amara",
  "lastName": "Fernando",
  "nic": "199523456789",
  "address": "12 Lake View, Anuradhapura",
  "phoneNumber": "+94765432109",
  "companyName": "Fernando Rice Industries",
  "companyUserName": "amarafernando",
  "companyAddress": "234 Export Center, Negombo",
  "companyPhoneNumber": "+94312221234",
  "password": "Amara@789",
  "confirmPassword": "Amara@789"
}
```

**Login (Phone):**
```json
{
  "phoneNumber": "+94765432109",
  "password": "Amara@789"
}
```

**Login (Username):**
```json
{
  "companyUserName": "amarafernando",
  "password": "Amara@789"
}
```

---

## 📋 Postman Step-by-Step

### Setting up in Postman:

1. **Open Postman**
2. Click **"New Request"**
3. For Register:
   - Set method to `POST`
   - Enter URL: `http://localhost:5000/api/auth/register`
   - Click **Headers** tab → Add `Content-Type: application/json`
   - Click **Body** tab → Select **raw** → Select **JSON** from dropdown
   - Paste the register JSON from above
   - Click **Send**

4. For Login:
   - Same steps, but use login URL and login JSON
   - **Copy the token** from the response!

5. For Protected Routes (Get Profile, Update, etc.):
   - Add header: `Authorization: Bearer <paste_token_here>`

---

## 🎯 Testing Workflow

1. ✅ Register a new user (User 1)
2. ✅ Login with that user → Save the token
3. ✅ Get current user profile (using token)
4. ✅ Update profile (using token)
5. ✅ Change password (using token)
6. ✅ Try to register same user again → Should get error (duplicate)
7. ✅ Login with wrong password → Should get error
8. ✅ Register User 2 and User 3 to test multiple accounts

---

## 🔍 Common Errors & Solutions

| Error | Reason | Solution |
|-------|--------|----------|
| 409 Conflict | NIC or username already exists | Use different NIC/username |
| 400 Bad Request | Validation failed | Check all required fields |
| 401 Unauthorized | Invalid credentials or missing token | Check username/password or token |
| 500 Internal Server Error | Server issue | Check server logs in terminal |

---

## 💡 Pro Tip for Postman

**Save the token automatically:**
1. In Login request, go to **Tests** tab
2. Add this script:
```javascript
pm.environment.set("auth_token", pm.response.json().data.token);
```
3. Create an environment variable `auth_token`
4. In protected routes, use: `{{auth_token}}` instead of pasting token manually!

**Using environment variable in Authorization header:**
```
Authorization: Bearer {{auth_token}}
```

This way, once you login, all protected routes will automatically use the saved token! 🚀

---

# 🛒 Purchase System APIs

## Customer Management

### 6️⃣ CREATE CUSTOMER

**Method:** `POST`  
**URL:** `http://localhost:5000/api/customers`  
**Headers:**
```
Content-Type: application/json
Authorization: Bearer YOUR_TOKEN_HERE
```

**Body (raw JSON):**
```json
{
  "name": "Nimal Silva",
  "phoneNumber": "+94771234567",
  "address": "123 Main Street, Colombo"
}
```

---

### 7️⃣ GET ALL CUSTOMERS

**Method:** `GET`  
**URL:** `http://localhost:5000/api/customers`  
**Headers:**
```
Authorization: Bearer YOUR_TOKEN_HERE
```

**Query Parameters (Optional):**
- `search` - Search by name or phone
- `isActive` - Filter by active status (true/false)

**Example:** `http://localhost:5000/api/customers?search=Nimal&isActive=true`

---

### 8️⃣ UPDATE CUSTOMER

**Method:** `PUT`  
**URL:** `http://localhost:5000/api/customers/:id`  
**Headers:**
```
Content-Type: application/json
Authorization: Bearer YOUR_TOKEN_HERE
```

**Body (raw JSON):**
```json
{
  "name": "Nimal Silva Updated",
  "phoneNumber": "+94779999999"
}
```

---

### 9️⃣ DELETE CUSTOMER

**Method:** `DELETE`  
**URL:** `http://localhost:5000/api/customers/:id`  
**Headers:**
```
Authorization: Bearer YOUR_TOKEN_HERE
```

---

## Paddy Type Management

### 🔟 CREATE PADDY TYPE

**Method:** `POST`  
**URL:** `http://localhost:5000/api/paddy-types`  
**Headers:**
```
Content-Type: application/json
Authorization: Bearer YOUR_TOKEN_HERE
```

**Body (raw JSON):**
```json
{
  "name": "Nadu",
  "description": "Common white rice variety"
}
```

**More Sri Lankan Paddy Types:**
```json
{
  "name": "Samba",
  "description": "Premium long grain rice"
}
```

```json
{
  "name": "Keeri Samba",
  "description": "Aromatic short grain rice"
}
```

```json
{
  "name": "Red Nadu",
  "description": "Red rice variety"
}
```

---

### 1️⃣1️⃣ GET ALL PADDY TYPES

**Method:** `GET`  
**URL:** `http://localhost:5000/api/paddy-types`  
**Headers:**
```
Authorization: Bearer YOUR_TOKEN_HERE
```

**Query Parameters (Optional):**
- `search` - Search by name
- `isActive` - Filter by active status (true/false)

---

### 1️⃣2️⃣ UPDATE PADDY TYPE

**Method:** `PUT`  
**URL:** `http://localhost:5000/api/paddy-types/:id`  
**Headers:**
```
Content-Type: application/json
Authorization: Bearer YOUR_TOKEN_HERE
```

**Body (raw JSON):**
```json
{
  "name": "Nadu Premium",
  "description": "Updated description"
}
```

---

## Purchase/Buy Transactions

### 1️⃣3️⃣ CREATE PURCHASE ⭐ MAIN FEATURE

**Method:** `POST`  
**URL:** `http://localhost:5000/api/purchases`  
**Headers:**
```
Content-Type: application/json
Authorization: Bearer YOUR_TOKEN_HERE
```

**Body (raw JSON):**
```json
{
  "customerId": "CUSTOMER_ID_HERE",
  "paddyTypeId": "PADDY_TYPE_ID_HERE",
  "numberOfBags": 50,
  "totalWeight": 2500,
  "pricePerKg": 85.50,
  "notes": "Good quality paddy"
}
```

> **Note:** You enter the `pricePerKg` for each purchase since prices change frequently. The `totalPrice` is automatically calculated as `totalWeight × pricePerKg`!

---

### 1️⃣4️⃣ GET ALL PURCHASES

**Method:** `GET`  
**URL:** `http://localhost:5000/api/purchases`  
**Headers:**
```
Authorization: Bearer YOUR_TOKEN_HERE
```

**Query Parameters (Optional):**
- `customerId` - Filter by customer
- `paddyTypeId` - Filter by paddy type
- `startDate` - Filter from date (YYYY-MM-DD)
- `endDate` - Filter to date (YYYY-MM-DD)
- `page` - Page number (default: 1)
- `limit` - Items per page (default: 50)

**Example:** 
```
http://localhost:5000/api/purchases?startDate=2025-12-01&endDate=2025-12-31&page=1&limit=20
```

---

### 1️⃣5️⃣ GET PURCHASE SUMMARY 📊

**Method:** `GET`  
**URL:** `http://localhost:5000/api/purchases/summary`  
**Headers:**
```
Authorization: Bearer YOUR_TOKEN_HERE
```

**Query Parameters (Optional):**
- `startDate` - From date
- `endDate` - To date

**Response Example:**
```json
{
  "success": true,
  "message": "Purchase summary retrieved successfully",
  "data": {
    "overall": {
      "totalPurchases": 150,
      "totalWeight": 75000,
      "totalAmount": 6750000,
      "totalBags": 1500
    },
    "byPaddyType": [
      {
        "paddyTypeName": "Nadu",
        "totalWeight": 40000,
        "totalPrice": 3420000,
        "totalBags": 800,
        "purchaseCount": 80
      },
      {
        "paddyTypeName": "Samba",
        "totalWeight": 35000,
        "totalPrice": 3325000,
        "totalBags": 700,
        "purchaseCount": 70
      }
    ]
  }
}
```

---

### 1️⃣6️⃣ UPDATE PURCHASE

**Method:** `PUT`  
**URL:** `http://localhost:5000/api/purchases/:id`  
**Headers:**
```
Content-Type: application/json
Authorization: Bearer YOUR_TOKEN_HERE
```

**Body (raw JSON):**
```json
{
  "numberOfBags": 55,
  "totalWeight": 2750,
  "notes": "Updated weight after recount"
}
```

---

### 1️⃣7️⃣ DELETE PURCHASE

**Method:** `DELETE`  
**URL:** `http://localhost:5000/api/purchases/:id`  
**Headers:**
```
Authorization: Bearer YOUR_TOKEN_HERE
```

---

## 🎯 Complete Testing Workflow

### Step 1: Setup
1. ✅ Register a user
2. ✅ Login and save the token

### Step 2: Create Master Data
3. ✅ Create 2-3 customers
4. ✅ Create 3-4 paddy types (Nadu, Samba, etc.)

### Step 3: Create Purchases
5. ✅ Create first purchase (get customer ID and paddy type ID from previous steps)
6. ✅ Create more purchases with different customers and paddy types

### Step 4: View Data
7. ✅ Get all purchases
8. ✅ Get purchase summary to see totals
9. ✅ Filter purchases by date range
10. ✅ Update a purchase
11. ✅ Test search and filters

---

## 📝 Sample Complete Flow

**1. Login:**
```json
POST /api/auth/login
{
  "phoneNumber": "+94771234567",
  "password": "Kasun@123"
}
→ Save token: eyJhbG...
```

**2. Create Customer:**
```json
POST /api/customers
{
  "name": "Sunil Perera",
  "phoneNumber": "+94712345678",
  "address": "Galle Road, Colombo"
}
→ Save customer ID: 674f1234567890abcdef1234
```

**3. Create Paddy Type:**
```json
POST /api/paddy-types
{
  "name": "Nadu",
  "description": "Common white rice variety"
}
→ Save paddy type ID: 674f9876543210fedcba5678
```

**4. Create Purchase:**
```json
POST /api/purchases
{
  "customerId": "674f1234567890abcdef1234",
  "paddyTypeId": "674f9876543210fedcba5678",
  "numberOfBags": 50,
  "totalWeight": 2500,
  "pricePerKg": 85.50
}
→ Total price automatically calculated: 2500 × 85.50 = LKR 213,750
```

**5. View Summary:**
```json
GET /api/purchases/summary
→ See total purchases, weight, and amount by paddy type
```

---

## 💡 Tips

1. **IDs**: After creating customers and paddy types, copy their IDs from the response to use in purchases
2. **Date Filters**: Use format `YYYY-MM-DD` for dates (e.g., `2025-12-01`)
3. **Pagination**: For large datasets, use `page` and `limit` parameters
4. **Authorization**: All purchase system routes require authentication token

---
