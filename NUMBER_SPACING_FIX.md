# Number Formatting with Thousand Separators

## Problem
Numbers were displayed without spacing, making large amounts hard to read:
- **Before:** Rs. 1431550.00
- **After:** Rs. 1 431 550.00

## Solution

Created a reusable `NumberFormatter` utility class that adds thousand separators (spaces) to all numbers.

### New File: `client/lib/core/utils/number_formatter.dart`

```dart
class NumberFormatter {
  // Format with spaces: 1431550.00 → 1 431 550.00
  static String formatWithSpaces(double value, {int decimals = 2})
  
  // Format currency: 1431550 → Rs. 1 431 550.00
  static String formatCurrency(double value, {String prefix = 'Rs. '})
  
  // Format integer: 1431550 → 1 431 550
  static String formatInteger(double value)
}
```

## Changes Made

### 1. Dashboard State (`dashboard_state.dart`)
```dart
// BEFORE
String _formatNumber(double value) {
  return value.toStringAsFixed(2);
}

// AFTER
String _formatNumber(double value) {
  return NumberFormatter.formatWithSpaces(value);
}
```

### 2. Recent Transactions (`recent_transactions.dart`)
```dart
// BEFORE
String _formatAmount(double amount) {
  return 'Rs.${amount.toStringAsFixed(0)}';
}

// AFTER
String _formatAmount(double amount) {
  return NumberFormatter.formatCurrency(amount);
}
```

### 3. Reports Screens
- `reports_screen.dart` - Uses `formatInteger()`
- `monthly_report_screen.dart` - Uses `formatInteger()`
- `daily_report_screen.dart` - Uses `formatInteger()`

### 4. Customers List (`customers_list_screen.dart`)
- Uses `formatInteger()` for balance display

## Examples

| Input | Output |
|-------|--------|
| 1431550.00 | 1 431 550.00 |
| 480400.00 | 480 400.00 |
| 1000.00 | 1 000.00 |
| 100.00 | 100.00 |
| 1234567.89 | 1 234 567.89 |

## Where It's Used

✅ **Dashboard Page**
- Monthly purchases
- Monthly sales
- Monthly expenses
- Monthly profit
- Stock value
- Receivables
- Payables

✅ **Reports Pages**
- Daily report numbers
- Monthly report numbers
- General report numbers

✅ **Customers Page**
- Customer balance display

✅ **Recent Transactions**
- Transaction amounts

## Benefits

✅ **Better readability**
- Large numbers are easier to read
- Follows international standard (space as thousand separator)
- Consistent across the app

✅ **Professional appearance**
- Looks more polished
- Standard formatting for financial apps
- Better user experience

✅ **Reusable**
- Single utility class
- Used everywhere in the app
- Easy to maintain

## Testing

After rebuild, verify:
- [ ] Dashboard shows "Rs. 1 431 550.00" format
- [ ] Reports show "1 431 550" format
- [ ] Customer balances show "1 431 550" format
- [ ] Recent transactions show "Rs. 1 431 550.00" format
- [ ] All numbers have proper spacing
- [ ] Decimals are preserved where needed

## Files Modified

1. `client/lib/core/utils/number_formatter.dart` (NEW)
2. `client/lib/features/home/presentation/cubit/dashboard_state.dart`
3. `client/lib/features/home/presentation/widgets/recent_transactions.dart`
4. `client/lib/features/reports/presentation/screens/reports_screen.dart`
5. `client/lib/features/reports/presentation/screens/monthly_report_screen.dart`
6. `client/lib/features/reports/presentation/screens/daily_report_screen.dart`
7. `client/lib/features/customers/presentation/screens/customers_list_screen.dart`
