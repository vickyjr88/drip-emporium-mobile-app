String? _str(dynamic value) => value?.toString();
String _strOr(dynamic value, String fallback) => _str(value) ?? fallback;
bool _bool(dynamic value, [bool fallback = false]) => value is bool ? value : fallback;

/// Mirrors the `customer` object returned by
/// POST /customer-portal/login|signup and GET /customer-portal/me. Unlike
/// the old Firestore-coupled Customer model, this has no `name`/`displayName`
/// split -- firstName/lastName are always both present -- so the round-trip
/// bug that model had (writing under one key, reading another) cannot recur.
class CustomerProfile {
  const CustomerProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.priceTier,
    required this.businessName,
    required this.referralCode,
    required this.hasPendingResellerApplication,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String? priceTier;
  final String? businessName;
  final String? referralCode;
  final bool hasPendingResellerApplication;

  String get fullName => '$firstName $lastName'.trim();

  factory CustomerProfile.fromJson(Map<String, dynamic> json) {
    return CustomerProfile(
      id: _strOr(json['id'], ''),
      firstName: _strOr(json['firstName'], ''),
      lastName: _strOr(json['lastName'], ''),
      email: _strOr(json['email'], ''),
      phone: _strOr(json['phone'], ''),
      priceTier: _str(json['priceTier']),
      businessName: _str(json['businessName']),
      referralCode: _str(json['referralCode']),
      hasPendingResellerApplication: _bool(json['hasPendingResellerApplication']),
    );
  }

  /// For caching the profile in SharedPreferences alongside the (separately,
  /// securely stored) token -- lets the UI render signed-in state instantly
  /// on cold start, before the network re-validation in
  /// CustomerAuthProvider.bootstrap() completes.
  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        'priceTier': priceTier,
        'businessName': businessName,
        'referralCode': referralCode,
        'hasPendingResellerApplication': hasPendingResellerApplication,
      };
}
