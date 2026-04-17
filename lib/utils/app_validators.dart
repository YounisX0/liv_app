class AppValidators {
  AppValidators._();

  static final RegExp _emailRegex = RegExp(
    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
  );

  static final RegExp _hasLetterRegex = RegExp(r'[A-Za-z]');
  static final RegExp _hasNumberRegex = RegExp(r'\d');
  static final RegExp _hasSpecialRegex = RegExp(r'[!@#$%^&*()]');

  static String normalizeSpaces(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  static String? requiredField(
    String? value, {
    String fieldName = 'This field',
  }) {
    final v = (value ?? '').trim();
    if (v.isEmpty) {
      return '$fieldName is required.';
    }
    return null;
  }

  static String? fullName(String? value) {
    final v = normalizeSpaces(value ?? '');
    if (v.isEmpty) {
      return 'Full name is required.';
    }
    if (v.length < 3) {
      return 'Full name must be at least 3 characters.';
    }
    return null;
  }

  static String? email(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) {
      return 'Email is required.';
    }
    if (!_emailRegex.hasMatch(v)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  static bool hasLetter(String value) => _hasLetterRegex.hasMatch(value);
  static bool hasNumber(String value) => _hasNumberRegex.hasMatch(value);
  static bool hasSpecialCharacter(String value) => _hasSpecialRegex.hasMatch(value);

  static String? loginPassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) {
      return 'Password is required.';
    }
    if (v.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    return null;
  }

  static String? strongPassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) {
      return 'Password is required.';
    }
    if (v.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    if (!hasLetter(v)) {
      return 'Password must contain at least one letter.';
    }
    if (!hasNumber(v)) {
      return 'Password must contain at least one number.';
    }
    return null;
  }

  static String? confirmPassword(
    String? value,
    String originalPassword,
  ) {
    final v = value ?? '';
    if (v.isEmpty) {
      return 'Please confirm your password.';
    }
    if (v != originalPassword) {
      return 'Passwords do not match.';
    }
    return null;
  }

  static String? positiveInteger(
    String? value, {
    String fieldName = 'Value',
    bool allowZero = false,
  }) {
    final v = (value ?? '').trim();
    if (v.isEmpty) {
      return '$fieldName is required.';
    }
    final parsed = int.tryParse(v);
    if (parsed == null) {
      return '$fieldName must be a valid number.';
    }
    if (allowZero) {
      if (parsed < 0) return '$fieldName must be 0 or more.';
    } else {
      if (parsed <= 0) return '$fieldName must be greater than 0.';
    }
    return null;
  }
}