
String sanitizePhoneNumber(String phoneNumber) {
  phoneNumber = phoneNumber.replaceAll(' ', '');
  if (phoneNumber.startsWith('0')) {
    phoneNumber = '254${phoneNumber.substring(1)}';
  } else if (phoneNumber.startsWith('+')) {
    phoneNumber = phoneNumber.substring(1);
  }
  return phoneNumber;
}
