class CustomerProfile {
  final String uid;
  final String name;
  final String address;
  final String zipCode;
  final String phone;
  final String? email;

  /// The internal Firebase Auth email this account signs in with. It stays fixed
  /// even if the customer later changes their phone number.
  final String? authEmail;

  const CustomerProfile({
    required this.uid,
    required this.name,
    required this.address,
    required this.zipCode,
    required this.phone,
    this.email,
    this.authEmail,
  });

  String get loginEmail => authEmail ?? authEmailForPhone(phone);

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'zipCode': zipCode,
      'phone': phone,
      'email': email,
      'authEmail': loginEmail,
    };
  }

  factory CustomerProfile.fromMap(String uid, Map<String, dynamic> map) {
    return CustomerProfile(
      uid: uid,
      name: map['name'] as String,
      address: map['address'] as String,
      zipCode: map['zipCode'] as String? ?? '',
      phone: map['phone'] as String,
      email: map['email'] as String?,
      authEmail: map['authEmail'] as String?,
    );
  }
}

/// Turns a raw phone number into the deterministic internal "email" Firebase
/// Auth uses under the hood. Phone is required at signup, so it's the one
/// stable identifier we always have - email is optional and only used as an
/// alternate lookup (see emailIndex in AppState).
String authEmailForPhone(String phone) {
  final digitsOnly = phone.replaceAll(RegExp(r'[^0-9]'), '');
  return '$digitsOnly@customers.paperboyexpress.app';
}
