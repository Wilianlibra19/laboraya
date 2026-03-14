import 'package:hive/hive.dart';

part 'document_model.g.dart';

@HiveType(typeId: 3)
class DocumentModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String userId;

  @HiveField(2)
  String type;

  @HiveField(3)
  String fileUrl;

  @HiveField(4)
  DateTime createdAt;

  DocumentModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.fileUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'type': type,
        'fileUrl': fileUrl,
        'createdAt': createdAt.toIso8601String(),
      };

  factory DocumentModel.fromJson(Map<String, dynamic> json) => DocumentModel(
        id: json['id'],
        userId: json['userId'],
        type: json['type'],
        fileUrl: json['fileUrl'],
        createdAt: DateTime.parse(json['createdAt']),
      );
}
