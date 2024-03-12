String? validateEmail(String? value) {
  const pattern = "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+.[a-zA-Z]{2,}\$";

  final regex = RegExp(pattern);
  if (value == null || value.isEmpty) {
    return "enter email";
  }
  if (value!.isNotEmpty && !regex.hasMatch(value)) {
    return "Enter valid email such as abc@pqr.mno";
  }
  return null;
}
