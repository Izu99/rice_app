/// Application validators for form inputs
class Validators {
  Validators._();

  // ==================== REQUIRED VALIDATION ====================

  /// Check if value is required
  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    return null;
  }

  /// Check if value is required (Sinhala)
  static String? requiredSinhala(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'මෙම ක්ෂේත්‍රය'} අවශ්‍යයි';
    }
    return null;
  }

  // ==================== STRING VALIDATION ====================

  /// Validate minimum length
  static String? minLength(String? value, int min, [String? fieldName]) {
    if (value == null || value.isEmpty) return null;
    if (value.length < min) {
      return '${fieldName ?? 'Value'} must be at least $min characters';
    }
    return null;
  }

  /// Validate maximum length
  static String? maxLength(String? value, int max, [String? fieldName]) {
    if (value == null || value.isEmpty) return null;
    if (value.length > max) {
      return '${fieldName ?? 'Value'} must not exceed $max characters';
    }
    return null;
  }

  /// Validate length range
  static String? lengthRange(
    String? value,
    int min,
    int max, [
    String? fieldName,
  ]) {
    if (value == null || value.isEmpty) return null;
    if (value.length < min || value.length > max) {
      return '${fieldName ?? 'Value'} must be between $min and $max characters';
    }
    return null;
  }

  /// Validate exact length
  static String? exactLength(String? value, int length, [String? fieldName]) {
    if (value == null || value.isEmpty) return null;
    if (value.length != length) {
      return '${fieldName ?? 'Value'} must be exactly $length characters';
    }
    return null;
  }

  /// Validate alphanumeric only
  static String? alphanumeric(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) return null;
    final regex = RegExp(r'^[a-zA-Z0-9]+$');
    if (!regex.hasMatch(value)) {
      return '${fieldName ?? 'Value'} must contain only letters and numbers';
    }
    return null;
  }

  /// Validate letters only
  static String? lettersOnly(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) return null;
    final regex = RegExp(r'^[a-zA-Z\s]+$');
    if (!regex.hasMatch(value)) {
      return '${fieldName ?? 'Value'} must contain only letters';
    }
    return null;
  }

  /// Validate no special characters
  static String? noSpecialChars(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) return null;
    final regex = RegExp(r'^[a-zA-Z0-9\s]+$');
    if (!regex.hasMatch(value)) {
      return '${fieldName ?? 'Value'} must not contain special characters';
    }
    return null;
  }

  // ==================== NAME VALIDATION ====================

  /// Validate name
  static String? name(String? value, [String? fieldName]) {
    final requiredError = required(value, fieldName ?? 'Name');
    if (requiredError != null) return requiredError;

    if (value!.length < 2) {
      return '${fieldName ?? 'Name'} must be at least 2 characters';
    }

    if (value.length > 100) {
      return '${fieldName ?? 'Name'} must not exceed 100 characters';
    }

    // Allow letters, spaces, and common name characters
    final regex = RegExp(r"^[a-zA-Z\u0D80-\u0DFF\s.'-]+$");
    if (!regex.hasMatch(value)) {
      return '${fieldName ?? 'Name'} contains invalid characters';
    }

    return null;
  }

  /// Validate Sinhala name
  static String? sinhalaName(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) return null;

    // Sinhala Unicode range: \u0D80-\u0DFF
    final regex = RegExp(r'^[\u0D80-\u0DFF\s]+$');
    if (!regex.hasMatch(value)) {
      return '${fieldName ?? 'නම'} සිංහල අක්ෂර පමණක් ඇතුළත් කරන්න';
    }

    return null;
  }

  // ==================== PHONE VALIDATION ====================

  /// Validate phone number (Sri Lankan)
  static String? phone(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Phone number'} is required';
    }

    // Remove spaces and dashes
    final cleaned = value.replaceAll(RegExp(r'[\s\-()]'), '');

    // Sri Lankan phone number patterns:
    // 0XX XXXXXXX (10 digits starting with 0)
    // +94 XX XXXXXXX (12 digits with country code)
    // 94 XX XXXXXXX (11 digits with country code without +)

    final regex = RegExp(r'^(?:\+?94|0)?[0-9]{9,10}$');
    if (!regex.hasMatch(cleaned)) {
      return 'Enter a valid phone number';
    }

    return null;
  }

  /// Validate mobile phone (Sri Lankan)
  static String? mobilePhone(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Mobile number'} is required';
    }

    final cleaned = value.replaceAll(RegExp(r'[\s\-()]'), '');

    // Sri Lankan mobile prefixes: 70, 71, 72, 74, 75, 76, 77, 78
    final regex = RegExp(r'^(?:\+?94|0)?7[0-8][0-9]{7}$');
    if (!regex.hasMatch(cleaned)) {
      return 'Enter a valid mobile number';
    }

    return null;
  }

  /// Validate landline phone (Sri Lankan)
  static String? landlinePhone(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) return null;

    final cleaned = value.replaceAll(RegExp(r'[\s\-()]'), '');

    // Sri Lankan landline: area code (2 digits) + 7 digits
    final regex = RegExp(r'^(?:\+?94|0)?[1-9][0-9]{8}$');
    if (!regex.hasMatch(cleaned)) {
      return 'Enter a valid landline number';
    }

    return null;
  }

  /// Check if phone exists (for async validation)
  static String? phoneFormat(String? value) {
    if (value == null || value.isEmpty) return null;

    final cleaned = value.replaceAll(RegExp(r'[\s\-()]'), '');
    if (cleaned.length < 9 || cleaned.length > 12) {
      return 'Invalid phone number format';
    }

    return null;
  }

  // ==================== EMAIL VALIDATION ====================

  /// Validate email
  static String? email(String? value, [bool isRequired = false]) {
    if (value == null || value.isEmpty) {
      return isRequired ? 'Email is required' : null;
    }

    final regex = RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$',
    );

    if (!regex.hasMatch(value)) {
      return 'Enter a valid email address';
    }

    return null;
  }

  // ==================== PASSWORD VALIDATION ====================

  /// Validate password
  static String? password(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Password'} is required';
    }

    if (value.length < 6) {
      return '${fieldName ?? 'Password'} must be at least 6 characters';
    }

    if (value.length > 50) {
      return '${fieldName ?? 'Password'} must not exceed 50 characters';
    }

    return null;
  }

  /// Validate strong password
  static String? strongPassword(String? value, [String? fieldName]) {
    final basicError = password(value, fieldName);
    if (basicError != null) return basicError;

    if (value!.length < 8) {
      return '${fieldName ?? 'Password'} must be at least 8 characters';
    }

    // Check for uppercase
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return '${fieldName ?? 'Password'} must contain at least one uppercase letter';
    }

    // Check for lowercase
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return '${fieldName ?? 'Password'} must contain at least one lowercase letter';
    }

    // Check for digit
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return '${fieldName ?? 'Password'} must contain at least one number';
    }

    // Check for special character
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return '${fieldName ?? 'Password'} must contain at least one special character';
    }

    return null;
  }

  /// Validate confirm password
  static String? confirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Confirm password is required';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null;
  }

  // ==================== NIC VALIDATION ====================

  /// Validate NIC (Sri Lankan)
  static String? nic(String? value, [bool isRequired = false]) {
    if (value == null || value.isEmpty) {
      return isRequired ? 'NIC is required' : null;
    }

    final cleaned = value.trim().toUpperCase();

    // Old format: 9 digits + V/X
    final oldNicRegex = RegExp(r'^[0-9]{9}[VX]$');

    // New format: 12 digits
    final newNicRegex = RegExp(r'^[0-9]{12}$');

    if (!oldNicRegex.hasMatch(cleaned) && !newNicRegex.hasMatch(cleaned)) {
      return 'Enter a valid NIC number';
    }

    return null;
  }

  /// Validate old format NIC
  static String? nicOldFormat(String? value) {
    if (value == null || value.isEmpty) return null;

    final regex = RegExp(r'^[0-9]{9}[VXvx]$');
    if (!regex.hasMatch(value)) {
      return 'Enter a valid old format NIC (e.g., 901234567V)';
    }

    return null;
  }

  /// Validate new format NIC
  static String? nicNewFormat(String? value) {
    if (value == null || value.isEmpty) return null;

    final regex = RegExp(r'^[0-9]{12}$');
    if (!regex.hasMatch(value)) {
      return 'Enter a valid new format NIC (12 digits)';
    }

    return null;
  }

  // ==================== NUMBER VALIDATION ====================

  /// Validate positive number
  static String? positiveNumber(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Value'} is required';
    }

    final number = double.tryParse(value);
    if (number == null) {
      return 'Enter a valid number';
    }

    if (number <= 0) {
      return '${fieldName ?? 'Value'} must be greater than zero';
    }

    return null;
  }

  /// Validate non-negative number
  static String? nonNegativeNumber(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Value'} is required';
    }

    final number = double.tryParse(value);
    if (number == null) {
      return 'Enter a valid number';
    }

    if (number < 0) {
      return '${fieldName ?? 'Value'} cannot be negative';
    }

    return null;
  }

  /// Validate integer
  static String? integer(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Value'} is required';
    }

    final number = int.tryParse(value);
    if (number == null) {
      return 'Enter a valid whole number';
    }

    return null;
  }

  /// Validate number range
  static String? numberRange(
    String? value,
    double min,
    double max, [
    String? fieldName,
  ]) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Value'} is required';
    }

    final number = double.tryParse(value);
    if (number == null) {
      return 'Enter a valid number';
    }

    if (number < min || number > max) {
      return '${fieldName ?? 'Value'} must be between $min and $max';
    }

    return null;
  }

  /// Validate minimum value
  static String? minValue(String? value, double min, [String? fieldName]) {
    if (value == null || value.isEmpty) return null;

    final number = double.tryParse(value);
    if (number == null) {
      return 'Enter a valid number';
    }

    if (number < min) {
      return '${fieldName ?? 'Value'} must be at least $min';
    }

    return null;
  }

  /// Validate maximum value
  static String? maxValue(String? value, double max, [String? fieldName]) {
    if (value == null || value.isEmpty) return null;

    final number = double.tryParse(value);
    if (number == null) {
      return 'Enter a valid number';
    }

    if (number > max) {
      return '${fieldName ?? 'Value'} must not exceed $max';
    }

    return null;
  }

  // ==================== WEIGHT VALIDATION ====================

  /// Validate weight
  static String? weight(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Weight'} is required';
    }

    final weight = double.tryParse(value);
    if (weight == null) {
      return 'Enter a valid weight';
    }

    if (weight <= 0) {
      return '${fieldName ?? 'Weight'} must be greater than zero';
    }

    if (weight > 100000) {
      return '${fieldName ?? 'Weight'} seems too large';
    }

    return null;
  }

  /// Validate bag weight (typical range)
  static String? bagWeight(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Bag weight'} is required';
    }

    final weight = double.tryParse(value);
    if (weight == null) {
      return 'Enter a valid weight';
    }

    if (weight <= 0) {
      return '${fieldName ?? 'Weight'} must be greater than zero';
    }

    // Typical bag weight range: 1-100 kg
    if (weight > 200) {
      return '${fieldName ?? 'Bag weight'} seems too large (max 200 kg)';
    }

    return null;
  }

  // ==================== BAGS VALIDATION ====================

  /// Validate bags count
  static String? bags(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Number of bags'} is required';
    }

    final bags = int.tryParse(value);
    if (bags == null) {
      return 'Enter a valid number';
    }

    if (bags <= 0) {
      return '${fieldName ?? 'Bags'} must be at least 1';
    }

    if (bags > 10000) {
      return '${fieldName ?? 'Bags'} count seems too large';
    }

    return null;
  }

  // ==================== PRICE VALIDATION ====================

  /// Validate price
  static String? price(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Price'} is required';
    }

    final price = double.tryParse(value);
    if (price == null) {
      return 'Enter a valid price';
    }

    if (price < 0) {
      return '${fieldName ?? 'Price'} cannot be negative';
    }

    return null;
  }

  /// Validate price per kg
  static String? pricePerKg(String? value, [String? fieldName]) {
    final error = price(value, fieldName ?? 'Price per kg');
    if (error != null) return error;

    final priceValue = double.parse(value!);

    // Reasonable range for rice/paddy prices in Sri Lanka
    if (priceValue > 1000) {
      return '${fieldName ?? 'Price per kg'} seems too high';
    }

    return null;
  }

  /// Validate amount
  static String? amount(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Amount'} is required';
    }

    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Enter a valid amount';
    }

    if (amount < 0) {
      return '${fieldName ?? 'Amount'} cannot be negative';
    }

    return null;
  }

  // ==================== ADDRESS VALIDATION ====================

  /// Validate address
  static String? address(String? value, [bool isRequired = false]) {
    if (value == null || value.isEmpty) {
      return isRequired ? 'Address is required' : null;
    }

    if (value.length < 5) {
      return 'Address is too short';
    }

    if (value.length > 255) {
      return 'Address must not exceed 255 characters';
    }

    return null;
  }

  // ==================== NOTES VALIDATION ====================

  /// Validate notes
  static String? notes(String? value, [int maxLength = 500]) {
    if (value == null || value.isEmpty) return null;

    if (value.length > maxLength) {
      return 'Notes must not exceed $maxLength characters';
    }

    return null;
  }

  // ==================== DATE VALIDATION ====================

  /// Validate date is not in future
  static String? notFutureDate(DateTime? value, [String? fieldName]) {
    if (value == null) return null;

    if (value.isAfter(DateTime.now())) {
      return '${fieldName ?? 'Date'} cannot be in the future';
    }

    return null;
  }

  /// Validate date is not in past
  static String? notPastDate(DateTime? value, [String? fieldName]) {
    if (value == null) return null;

    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);

    if (value.isBefore(startOfToday)) {
      return '${fieldName ?? 'Date'} cannot be in the past';
    }

    return null;
  }

  /// Validate date range
  static String? dateRange(
    DateTime? value,
    DateTime minDate,
    DateTime maxDate, [
    String? fieldName,
  ]) {
    if (value == null) return null;

    if (value.isBefore(minDate) || value.isAfter(maxDate)) {
      return '${fieldName ?? 'Date'} must be within the valid range';
    }

    return null;
  }

  // ==================== COMBINATION VALIDATORS ====================

  /// Combine multiple validators
  static String? Function(String?) combine(
    List<String? Function(String?)> validators,
  ) {
    return (String? value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }

  /// Validate only if value is not empty
  static String? Function(String?) optional(
    String? Function(String?) validator,
  ) {
    return (String? value) {
      if (value == null || value.isEmpty) return null;
      return validator(value);
    };
  }
}

