class ValidationUtils {
  // Email validation regex - now allows dots in local part
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  // Password validation regex - at least 8 characters, one uppercase, one lowercase, one number, and special characters
  static final RegExp _passwordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&.])[A-Za-z\d@$!%*?&.]{8,}$',
  );

  // Phone number validation regex - basic international format
  static final RegExp _phoneRegex = RegExp(
    r'^\+?[1-9]\d{1,14}$',
  );

  // Name validation regex - only letters, spaces, hyphens, and apostrophes
  static final RegExp _nameRegex = RegExp(
    r"^[a-zA-Z\s\-']+$",
  );

  /// Validates email address
  static bool isValidEmail(String input) {
    if (input.trim().isEmpty) return false;
    // Find any email-like pattern in the input
    final match = _emailRegex.firstMatch(input.trim());
    return match != null;
  }

  /// Validates password strength
  static bool isValidPassword(String password) {
    if (password.trim().isEmpty) return false;
    return _passwordRegex.hasMatch(password);
  }

  /// Validates phone number
  static bool isValidPhoneNumber(String phone) {
    if (phone.trim().isEmpty) return false;
    // Remove common formatting characters
    final cleanedPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    return _phoneRegex.hasMatch(cleanedPhone);
  }

  /// Validates full name
  static bool isValidName(String name) {
    if (name.trim().isEmpty) return false;
    if (name.trim().length < 2) return false;
    return _nameRegex.hasMatch(name.trim());
  }

  /// Get email validation error message
  static String? getEmailError(String input) {
    if (input.trim().isEmpty) {
      return 'Email is required';
    }
    if (!isValidEmail(input)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Get password validation error message
  static String? getPasswordError(String password) {
    if (password.trim().isEmpty) {
      return 'Password is required';
    }
    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!RegExp(r'\d').hasMatch(password)) {
      return 'Password must contain at least one number';
    }
    if (!RegExp(r'[@$!%*?&.]').hasMatch(password)) {
      return 'Password must contain at least one special character (@\$!%*?&.)';
    }
    return null;
  }

  /// Get phone validation error message
  static String? getPhoneError(String phone) {
    if (phone.trim().isEmpty) {
      return 'Phone number is required';
    }
    if (!isValidPhoneNumber(phone)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  /// Get name validation error message
  static String? getNameError(String name) {
    if (name.trim().isEmpty) {
      return 'Name is required';
    }
    if (name.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (!isValidName(name)) {
      return 'Name can only contain letters, spaces, hyphens, and apostrophes';
    }
    return null;
  }

  /// Validates password confirmation
  static String? getConfirmPasswordError(String password, String confirmPassword) {
    if (confirmPassword.trim().isEmpty) {
      return 'Please confirm your password';
    }
    if (password != confirmPassword) {
      return 'Passwords do not match';
    }
    return null;
  }
} 