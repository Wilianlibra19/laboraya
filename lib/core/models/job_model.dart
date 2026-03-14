import 'package:hive/hive.dart';

part 'job_model.g.dart';

@HiveType(typeId: 1)
class JobModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  String category;

  @HiveField(4)
  double payment;

  @HiveField(5)
  String paymentType;

  @HiveField(6)
  int workersNeeded;

  @HiveField(7)
  String duration;

  @HiveField(8)
  double latitude;

  @HiveField(9)
  double longitude;

  @HiveField(10)
  String address;

  @HiveField(11)
  String createdBy;

  @HiveField(12)
  String? acceptedBy;

  @HiveField(13)
  String status;

  @HiveField(14)
  bool isUrgent;

  @HiveField(15)
  List<String> images;

  @HiveField(16)
  DateTime createdAt;

  @HiveField(17)
  DateTime? scheduledDate;

  @HiveField(18)
  String jobStatus;

  @HiveField(19)
  DateTime? acceptedAt;

  @HiveField(20)
  DateTime? startedAt;

  @HiveField(21)
  DateTime? finishedAt;

  @HiveField(22)
  DateTime? confirmedAt;

  @HiveField(23)
  DateTime? completedAt;

  @HiveField(24)
  double? ratingWorker;

  @HiveField(25)
  String? commentWorker;

  @HiveField(26)
  double? ratingClient;

  @HiveField(27)
  String? commentClient;

  @HiveField(28)
  List<String> documents;

  JobModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.payment,
    required this.paymentType,
    this.workersNeeded = 1,
    required this.duration,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.createdBy,
    this.acceptedBy,
    this.status = 'available',
    this.isUrgent = false,
    required this.images,
    required this.createdAt,
    this.scheduledDate,
    this.jobStatus = 'available',
    this.acceptedAt,
    this.startedAt,
    this.finishedAt,
    this.confirmedAt,
    this.completedAt,
    this.ratingWorker,
    this.commentWorker,
    this.ratingClient,
    this.commentClient,
    this.documents = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category,
        'payment': payment,
        'paymentType': paymentType,
        'workersNeeded': workersNeeded,
        'duration': duration,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'createdBy': createdBy,
        'acceptedBy': acceptedBy,
        'status': status,
        'isUrgent': isUrgent,
        'images': images,
        'createdAt': createdAt.toIso8601String(),
        'scheduledDate': scheduledDate?.toIso8601String(),
        'jobStatus': jobStatus,
        'acceptedAt': acceptedAt?.toIso8601String(),
        'startedAt': startedAt?.toIso8601String(),
        'finishedAt': finishedAt?.toIso8601String(),
        'confirmedAt': confirmedAt?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'ratingWorker': ratingWorker,
        'commentWorker': commentWorker,
        'ratingClient': ratingClient,
        'commentClient': commentClient,
        'documents': documents,
      };

  factory JobModel.fromJson(Map<String, dynamic> json) => JobModel(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        category: json['category'],
        payment: json['payment']?.toDouble() ?? 0.0,
        paymentType: json['paymentType'],
        workersNeeded: json['workersNeeded'] ?? 1,
        duration: json['duration'],
        latitude: json['latitude']?.toDouble() ?? 0.0,
        longitude: json['longitude']?.toDouble() ?? 0.0,
        address: json['address'],
        createdBy: json['createdBy'],
        acceptedBy: json['acceptedBy'],
        status: json['status'] ?? 'available',
        isUrgent: json['isUrgent'] ?? false,
        images: List<String>.from(json['images'] ?? []),
        createdAt: DateTime.parse(json['createdAt']),
        scheduledDate: json['scheduledDate'] != null
            ? DateTime.parse(json['scheduledDate'])
            : null,
        jobStatus: json['jobStatus'] ?? 'available',
        acceptedAt: json['acceptedAt'] != null
            ? DateTime.parse(json['acceptedAt'])
            : null,
        startedAt: json['startedAt'] != null
            ? DateTime.parse(json['startedAt'])
            : null,
        finishedAt: json['finishedAt'] != null
            ? DateTime.parse(json['finishedAt'])
            : null,
        confirmedAt: json['confirmedAt'] != null
            ? DateTime.parse(json['confirmedAt'])
            : null,
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'])
            : null,
        ratingWorker: json['ratingWorker']?.toDouble(),
        commentWorker: json['commentWorker'],
        ratingClient: json['ratingClient']?.toDouble(),
        commentClient: json['commentClient'],
        documents: List<String>.from(json['documents'] ?? []),
      );

  // Crear desde DocumentSnapshot de Firestore
  factory JobModel.fromFirestore(dynamic snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return JobModel(
      id: snapshot.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      payment: (data['payment'] ?? 0).toDouble(),
      paymentType: data['paymentType'] ?? '',
      workersNeeded: data['workersNeeded'] ?? 1,
      duration: data['duration'] ?? '',
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      address: data['address'] ?? '',
      createdBy: data['createdBy'] ?? '',
      acceptedBy: data['acceptedBy'],
      status: data['status'] ?? 'available',
      isUrgent: data['isUrgent'] ?? false,
      images: List<String>.from(data['images'] ?? []),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as dynamic).toDate()
          : DateTime.now(),
      scheduledDate: data['scheduledDate'] != null
          ? (data['scheduledDate'] as dynamic).toDate()
          : null,
      jobStatus: data['jobStatus'] ?? 'available',
      acceptedAt: data['acceptedAt'] != null
          ? (data['acceptedAt'] as dynamic).toDate()
          : null,
      startedAt: data['startedAt'] != null
          ? (data['startedAt'] as dynamic).toDate()
          : null,
      finishedAt: data['finishedAt'] != null
          ? (data['finishedAt'] as dynamic).toDate()
          : null,
      confirmedAt: data['confirmedAt'] != null
          ? (data['confirmedAt'] as dynamic).toDate()
          : null,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as dynamic).toDate()
          : null,
      ratingWorker: data['ratingWorker']?.toDouble(),
      commentWorker: data['commentWorker'],
      ratingClient: data['ratingClient']?.toDouble(),
      commentClient: data['commentClient'],
      documents: List<String>.from(data['documents'] ?? []),
    );
  }
}
