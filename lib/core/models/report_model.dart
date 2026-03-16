class ReportModel {
  final String id;
  final String reporterId;
  final String reportedId;
  final String reportedType; // 'user' o 'job'
  final String reason;
  final String description;
  final DateTime createdAt;
  final String status; // 'pending', 'reviewed', 'resolved'

  ReportModel({
    required this.id,
    required this.reporterId,
    required this.reportedId,
    required this.reportedType,
    required this.reason,
    required this.description,
    required this.createdAt,
    this.status = 'pending',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'reporterId': reporterId,
        'reportedId': reportedId,
        'reportedType': reportedType,
        'reason': reason,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
        'status': status,
      };

  factory ReportModel.fromJson(Map<String, dynamic> json) => ReportModel(
        id: json['id'],
        reporterId: json['reporterId'],
        reportedId: json['reportedId'],
        reportedType: json['reportedType'],
        reason: json['reason'],
        description: json['description'],
        createdAt: DateTime.parse(json['createdAt']),
        status: json['status'] ?? 'pending',
      );
}
