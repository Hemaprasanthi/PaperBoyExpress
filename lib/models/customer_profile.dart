class CustomerProfile {
  final String uid;
  final String name;
  final String address;
  final String phone;
  final String? email;

  const CustomerProfile({
    required this.uid,
    required this.name,
    required this.address,
    required this.phone,
    this.email,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
    };
  }

  factory CustomerProfile.fromMap(String uid, Map<String, dynamic> map) {
    return CustomerProfile(
      uid: uid,
      name: map['name'] as String,
      address: map['address'] as String,
      phone: map['phone'] as String,
      email: map['email'] as String?,
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
