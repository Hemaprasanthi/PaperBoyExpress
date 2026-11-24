/// Dummy payment and support details - replace with real ones before launch.
const String kUpiId = 'paperboyexpress@upi';
const String kUpiPayeeName = 'PaperBoy Express';

/// How long a generated UPI QR code stays valid.
const Duration kUpiQrValidity = Duration(minutes: 15);

const String kSupportContactName = 'Ravi Kumar';
const String kSupportContactPhone = '+91 90000 00000';
const String kSupportEmail = 'support@paperboyexpress.example';

const String kSupportPromise =
    'Our support team will get back to you within 1 business day.';

String digitsOnly(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');

const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String formatDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

String formatDateTime(DateTime d) {
  final hour = d.hour == 0 ? 12 : (d.hour > 12 ? d.hour - 12 : d.hour);
  final ampm = d.hour >= 12 ? 'PM' : 'AM';
  return '${d.day} ${_months[d.month - 1]} ${d.year}, $hour:${d.minute.toString().padLeft(2, '0')} $ampm';
}
