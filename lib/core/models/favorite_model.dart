class FavoriteModel {
  final String id;
  final String userId;
  final String jobId;
  final DateTime savedAt;

  FavoriteModel({
    required this.id,
    required this.userId,
    required this.jobId,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'jobId': jobId,
        'savedAt': savedAt.toIso8601String(),
      };

  factory FavoriteModel.fromJson(Map<String, dynamic> json) => FavoriteModel(
        id: json['id'],
        userId: json['userId'],
        jobId: json['jobId'],
        savedAt: DateTime.parse(json['savedAt']),
      );
}
