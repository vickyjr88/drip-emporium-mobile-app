String sanitizeMobileNumber(String mobileNumber) {
  mobileNumber = mobileNumber.replaceAll(' ', '');
  if (mobileNumber.startsWith('0')) {
    mobileNumber = '254${mobileNumber.substring(1)}';
  } else if (mobileNumber.startsWith('+')) {
    mobileNumber = mobileNumber.substring(1);
  }
  return mobileNumber;
}
