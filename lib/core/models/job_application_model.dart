class JobApplicationModel {
  final String id;
  final String jobId;
  final String applicantId;
  final String applicantName;
  final String applicantPhoto;
  final double applicantRating;
  final int applicantCompletedJobs;
  final String message;
  final DateTime appliedAt;
  final String status;
  
  JobApplicationModel({
    required this.id,
    required this.jobId,
    required this.applicantId,
    required this.applicantName,
    required this.applicantPhoto,
    required this.applicantRating,
    required this.applicantCompletedJobs,
    required this.message,
    required this.appliedAt,
    this.status = 'pending',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'jobId': jobId,
        'applicantId': applicantId,
        'applicantName': applicantName,
        'applicantPhoto': applicantPhoto,
        'applicantRating': applicantRating,
        'applicantCompletedJobs': applicantCompletedJobs,
        'message': message,
        'appliedAt': appliedAt.toIso8601String(),
        'status': status,
      };

  factory JobApplicationModel.fromJson(Map<String, dynamic> json) =>
      JobApplicationModel(
        id: json['id'],
        jobId: json['jobId'],
        applicantId: json['applicantId'],
        applicantName: json['applicantName'],
        applicantPhoto: json['applicantPhoto'],
        applicantRating: json['applicantRating']?.toDouble() ?? 0.0,
        applicantCompletedJobs: json['applicantCompletedJobs'] ?? 0,
        message: json['message'] ?? '',
        appliedAt: DateTime.parse(json['appliedAt']),
        status: json['status'] ?? 'pending',
      );

  factory JobApplicationModel.fromFirestore(dynamic snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return JobApplicationModel(
      id: snapshot.id,
      jobId: data['jobId'] ?? '',
      applicantId: data['applicantId'] ?? '',
      applicantName: data['applicantName'] ?? '',
      applicantPhoto: data['applicantPhoto'] ?? '',
      applicantRating: (data['applicantRating'] ?? 0).toDouble(),
      applicantCompletedJobs: data['applicantCompletedJobs'] ?? 0,
      message: data['message'] ?? '',
      appliedAt: (data['appliedAt'] as dynamic).toDate(),
      status: data['status'] ?? 'pending',
    );
  }
}
