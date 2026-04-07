# Quick Start - Paddy Rice Price Feature

## For Company Users

### How to Add a Price
1. Open the Rice Mill App
2. Look for "Paddy Prices" or navigation button (Rice icon)
3. Tap "+ Add Price" or "Add Today's Price"
4. Fill in the form:
   - **Price**: Enter the starting price (e.g., 115)
   - **Price Range** (Optional): Toggle to enable, then enter max price (e.g., 118)
   - **Quality Grade**: Select between Premium, Standard, or Basic
   - **Notes** (Optional): Add any special notes about this price
5. Your **district** is automatically filled from your company profile
6. Tap "Add Price" button
7. See confirmation message and return to previous screen

### How to View Your Prices
1. Navigate to Price Management
2. Tap "My Prices" tab (if available)
3. See all prices you've added for your company
4. Edit or delete any of your entries

---

## For All Users - Viewing Prices by District

### How to Browse Prices
1. Go to "Paddy Prices" section
2. See list of all districts with active prices
3. Each district shows:
   - District name
   - Number of prices available
   - Last update time
4. Tap on a district to see all prices
5. Scroll through all companies' prices in that district

### Understanding the Price Display
- **Single Price**: "Rs. 115.00" means price is fixed at 115
- **Price Range**: "Rs. 115.00 - 118.00" means prices vary between 115 and 118
- **Quality Grade**: Colored badge shows quality (Premium/Standard/Basic)
- **Company Name**: Shows which company added the price
- **Date & By**: Shows when and by whom the price was added

### What to Look For
- Browse multiple companies' prices to compare
- Check the date to see if prices are current
- Look at quality grades - premium prices will be higher
- Read any notes for additional information

---

## For Admin Users - Creating Companies with Districts

### How to Register a New Company
1. Go to Super Admin Dashboard
2. Navigate to Companies
3. Click "+ Add Company"
4. Fill in company details
5. **Important**: Select or enter the company's **District**
6. This district cannot be changed by company users later
7. Create default admin user for the company
8. Save and the company can start adding prices

### Districts Setup
- Districts are created automatically as companies are added
- You don't need to pre-configure districts
- Prices will appear under their respective districts automatically

---

## Common Use Cases

### Use Case 1: Company Owner Tracking Price Changes
```
Monday: Add price "Rs. 115.00 - 118.00" Standard Quality
Tuesday: Add new price "Rs. 120.00" Premium Quality
Wednesday: Add price "Rs. 115.00 - 119.00" Standard Quality
→ All three entries appear in "My Prices" for history tracking
```

### Use Case 2: Buyer Comparing Prices Across Companies
```
1. Go to "Paddy Prices"
2. Tap "Colombo" district
3. See 5 different company prices:
   - Company A: Rs. 115.00 (Standard)
   - Company B: Rs. 115.00 - 118.00 (Standard)
   - Company C: Rs. 120.00 (Premium)
   - Company D: Rs. 114.00 (Basic)
   - Company E: Rs. 116.00 (Standard)
→ Can make informed decision on which company to buy from
```

### Use Case 3: Supplier in Multiple Locations
```
Note: Each company can only serve ONE district
If you operate in multiple districts, you need separate company registrations for each
```

---

## Technical Details

### Price Range Rules
- Minimum price must be less than maximum price
- Both must be positive numbers
- Can be same for single price (or omit max price)

### Quality Grades (Impact on Color)
- **Premium**: Gold/Amber (usually highest price)
- **Standard**: Green (most common)
- **Basic**: Orange (usually lowest price)

### Data Retention
- All prices are kept in history for reference
- Can delete your own entries
- Deleted entries are soft-deleted (kept in database but marked inactive)

---

## Troubleshooting

### I can't add a price
**Check:**
- Are you logged in as a company user? (Not customer or viewer)
- Does your company have a district assigned?
- Do you have manager or company role?
- Does the price you entered validate (positive number)?

### I can't see any prices
**Check:**
- Are you logged in at all?
- Does the district have any prices added by companies?
- Try refreshing the screen
- Check your internet connection

### Price range says minimum must be less than maximum
**Solution:**
When adding a range, make sure:
- Starting price: 115
- Maximum price: 116 or higher (NOT equal)

### My price disappeared
**Note:**
- If you deleted it, it won't appear anymore
- If you marked quality as "basic" instead of "standard", it still appears
- Check "My Prices" to see if you still have it

---

## Mobile App Layout

```
================================
|  < Prices by District         |
================================
|  [District Card 1]            |
|  Colombo                       |
|  8 prices listed              |
|  Last updated: 2 hrs ago      |
|                                |
|  [District Card 2]            |
|  Kandy                         |
|  3 prices listed              |
|  Last updated: 1 day ago      |
|                                |
|  [District Card 3]            |
|  Galle                         |
|  5 prices listed              |
|  Last updated: 30 mins ago    |
|                                |
|         [+ Add Price Button]   |
================================
```

---

## Price Entry Screen

```
================================
|  + Add Paddy Rice Price       |
================================
|                                |
|  District:    Colombo         | (auto-filled, read-only)
|                                |
|  Price (Rs):  [115.00    ]    |
|                                |
|  □ Price Range?                |
|                                |
|  Quality Grade:                |
|  [Standard] ▼                 |
|    - Premium                   |
|    - Standard                  |
|    - Basic                     |
|                                |
|  Notes:                        |
|  [Fresh stock from...    ]    |
|  [field for notes...]          |
|  Character limit: 30/200      |
|                                |
|       [  Add Price  ]          |
|                                |
================================
```

---

## Tips & Best Practices

1. **Update regularly**: Add prices daily for accurate market tracking
2. **Be specific**: Use quality grades to differentiate your offerings
3. **Add notes**: Help buyers understand special circumstances
4. **Check competitors**: View other company prices to stay competitive
5. **Use ranges**: If your price varies, use range feature for transparency
6. **One price per day**: You can add multiple prices, but avoid redundancy
7. **Quality matters**: Premium quality commands higher prices

---

## Support

For technical issues or questions:
1. Check this guide first
2. Contact your system administrator
3. Refer to full implementation documentation

---

Last Updated: April 3, 2026
Version: 1.0
