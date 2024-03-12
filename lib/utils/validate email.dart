String? validatePassword(String? password) {
  if (password != null) {
    // Check length
    if (password.length < 10) {
      return "password length should be greater than 10";
    }

    // Check for at least one uppercase letter
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return "password should at least one uppercase letter";
    }

    // Check for at least one lowercase letter
    if (!password.contains(RegExp(r'[a-z]'))) {
      return "password should at least one lowercase letter";
    }

    // Check for at least one special character
    if (!password.contains(RegExp(r'[!@#\$&*~]'))) {
      return "password should at least one special character";
    }
    if (RegExp(r'\s').hasMatch(password)) {
      return "password should not include spaces";
    }

    // All checks passed, password is valid

    return null;
  }
  return "enter password";
}
