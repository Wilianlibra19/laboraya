class ReviewModel {
  String id;
  String jobId;
  String reviewerId; // Quien califica
  String reviewedUserId; // Quien es calificado
  double rating; // 1-5 estrellas
  String comment;
  DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.jobId,
    required this.reviewerId,
    required this.reviewedUserId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'jobId': jobId,
        'reviewerId': reviewerId,
        'reviewedUserId': reviewedUserId,
        'rating': rating,
        'comment': comment,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
        id: json['id'],
        jobId: json['jobId'],
        reviewerId: json['reviewerId'],
        reviewedUserId: json['reviewedUserId'],
        rating: json['rating']?.toDouble() ?? 0.0,
        comment: json['comment'],
        createdAt: DateTime.parse(json['createdAt']),
      );
}
