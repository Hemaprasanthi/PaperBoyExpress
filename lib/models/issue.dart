/// A problem reported by any user (customer, admin or delivery) from the support screen.
class Issue {
  final String id;
  final String reporterUsername;
  final String reporterName;
  final String reporterRole;
  final String subject;
  final String description;
  final bool resolved;
  final DateTime createdAt;

  const Issue({
    required this.id,
    required this.reporterUsername,
    required this.reporterName,
    required this.reporterRole,
    required this.subject,
    required this.description,
    this.resolved = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'reporterUsername': reporterUsername,
        'reporterName': reporterName,
        'reporterRole': reporterRole,
        'subject': subject,
        'description': description,
        'resolved': resolved,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Issue.fromMap(String id, Map<String, dynamic> map) {
    return Issue(
      id: id,
      reporterUsername: map['reporterUsername'] as String? ?? '',
      reporterName: map['reporterName'] as String? ?? '',
      reporterRole: map['reporterRole'] as String? ?? '',
      subject: map['subject'] as String? ?? '',
      description: map['description'] as String? ?? '',
      resolved: map['resolved'] as bool? ?? false,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
