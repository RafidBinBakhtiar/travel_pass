// Password validation utilities
class PasswordValidator {
  static const int minLength = 8;
  static const String uppercaseRegex = r'[A-Z]';
  static const String numberRegex = r'[0-9]';
  static const String specialCharRegex = r'''[@#$!%^&*()_+\-=\[\]{};:'",.<>?/\\|`~]''';

  /// Checks if password meets minimum length requirement
  static bool hasMinLength(String password) {
    return password.length >= minLength;
  }

  /// Checks if password contains at least one uppercase letter
  static bool hasUppercase(String password) {
    return RegExp(uppercaseRegex).hasMatch(password);
  }

  /// Checks if password contains at least one number
  static bool hasNumber(String password) {
    return RegExp(numberRegex).hasMatch(password);
  }

  /// Checks if password contains at least one special character
  static bool hasSpecialChar(String password) {
    return RegExp(specialCharRegex).hasMatch(password);
  }

  /// Validates the entire password against all requirements
  static bool isValid(String password) {
    return hasMinLength(password) &&
        hasUppercase(password) &&
        hasNumber(password) &&
        hasSpecialChar(password);
  }

  /// Get all validation messages
  static List<String> getValidationMessages(String password) {
    final messages = <String>[];

    if (!hasMinLength(password)) {
      messages.add('অন্তত ৮টি অক্ষর হতে হবে');
    }
    if (!hasUppercase(password) || !hasNumber(password)) {
      messages.add('একটি বড় হাতের অক্ষর (A-Z) ও একটি সংখ্যা (0-9) থাকতে হবে');
    }
    if (!hasSpecialChar(password)) {
      messages.add('একটি বিশেষ চিহ্ন (যেমন: @, #, \$) থাকতে হবে');
    }

    return messages;
  }

  /// Check which validation rules are met
  static Map<String, bool> getValidationStatus(String password) {
    return {
      'minLength': hasMinLength(password),
      'uppercase': hasUppercase(password),
      'number': hasNumber(password),
      'specialChar': hasSpecialChar(password),
    };
  }
}
