import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? photo;

  @HiveField(3)
  String phone;

  @HiveField(4)
  String email;

  @HiveField(5)
  String district;

  @HiveField(6)
  double rating;

  @HiveField(7)
  int completedJobs;

  @HiveField(8)
  List<String> skills;

  @HiveField(9)
  String availability;

  @HiveField(10)
  String description;

  @HiveField(11)
  List<String> documents;

  @HiveField(12)
  DateTime createdAt;

  @HiveField(13)
  bool isDniVerified;

  @HiveField(14)
  bool isPhoneVerified;

  @HiveField(15)
  bool isDocumentVerified;

  @HiveField(16)
  double totalEarnings;

  @HiveField(17)
  double monthlyEarnings;

  @HiveField(18)
  int totalReviews;

  UserModel({
    required this.id,
    required this.name,
    this.photo,
    required this.phone,
    required this.email,
    required this.district,
    this.rating = 0.0,
    this.completedJobs = 0,
    required this.skills,
    required this.availability,
    required this.description,
    required this.documents,
    required this.createdAt,
    this.isDniVerified = false,
    this.isPhoneVerified = false,
    this.isDocumentVerified = false,
    this.totalEarnings = 0.0,
    this.monthlyEarnings = 0.0,
    this.totalReviews = 0,
  });

  bool get isVerified => isDniVerified || isPhoneVerified || isDocumentVerified;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'photo': photo,
        'phone': phone,
        'email': email,
        'district': district,
        'rating': rating,
        'completedJobs': completedJobs,
        'skills': skills,
        'availability': availability,
        'description': description,
        'documents': documents,
        'createdAt': createdAt.toIso8601String(),
        'isDniVerified': isDniVerified,
        'isPhoneVerified': isPhoneVerified,
        'isDocumentVerified': isDocumentVerified,
        'totalEarnings': totalEarnings,
        'monthlyEarnings': monthlyEarnings,
        'totalReviews': totalReviews,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'],
        name: json['name'],
        photo: json['photo'],
        phone: json['phone'],
        email: json['email'],
        district: json['district'],
        rating: json['rating']?.toDouble() ?? 0.0,
        completedJobs: json['completedJobs'] ?? 0,
        skills: List<String>.from(json['skills'] ?? []),
        availability: json['availability'],
        description: json['description'],
        documents: List<String>.from(json['documents'] ?? []),
        createdAt: DateTime.parse(json['createdAt']),
        isDniVerified: json['isDniVerified'] ?? false,
        isPhoneVerified: json['isPhoneVerified'] ?? false,
        isDocumentVerified: json['isDocumentVerified'] ?? false,
        totalEarnings: json['totalEarnings']?.toDouble() ?? 0.0,
        monthlyEarnings: json['monthlyEarnings']?.toDouble() ?? 0.0,
        totalReviews: json['totalReviews'] ?? 0,
      );
}
