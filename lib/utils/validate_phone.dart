String? validatePhoneNumber(String? phoneNumber) {
  if (phoneNumber == null) {
    return "enter phone value";
  }
  // Remove any non-digit characters (e.g., spaces, dashes)
  final cleanedNumber = phoneNumber!.replaceAll(RegExp(r'[^0-9]'), '');

  // Check if the cleaned number has at least 10 digits
  if (!(cleanedNumber.length >= 10 && cleanedNumber.length <= 10)) {
    return "wrong phone value";
  }
  return null;
}
