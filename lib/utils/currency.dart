/// Formats an amount as Indian Rupees, e.g. formatInr(1234.5) -> "₹1,234.50"
String formatInr(double amount) {
  final isNegative = amount < 0;
  final value = amount.abs();
  final fixed = value.toStringAsFixed(2);
  final parts = fixed.split('.');
  final wholePart = parts[0];
  final decimalPart = parts[1];

  // Indian digit grouping: last 3 digits, then groups of 2.
  String grouped;
  if (wholePart.length <= 3) {
    grouped = wholePart;
  } else {
    final lastThree = wholePart.substring(wholePart.length - 3);
    final rest = wholePart.substring(0, wholePart.length - 3);
    final restGrouped = rest.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{2})+(?!\d))'),
      (m) => '${m[1]},',
    );
    grouped = '$restGrouped,$lastThree';
  }

  return '${isNegative ? '-' : ''}\u20b9$grouped.$decimalPart';
}
