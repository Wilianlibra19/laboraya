import 'package:hive/hive.dart';

part 'message_model.g.dart';

@HiveType(typeId: 2)
class MessageModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String jobId;

  @HiveField(2)
  String senderId;

  @HiveField(3)
  String text;

  @HiveField(4)
  String? image;

  @HiveField(5)
  String? file;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  bool isRead;

  @HiveField(8)
  String? receiverId;

  MessageModel({
    required this.id,
    required this.jobId,
    required this.senderId,
    required this.text,
    this.image,
    this.file,
    required this.createdAt,
    this.isRead = false,
    this.receiverId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'jobId': jobId,
        'senderId': senderId,
        'text': text,
        'image': image,
        'file': file,
        'createdAt': createdAt.toIso8601String(),
        'isRead': isRead,
        'receiverId': receiverId,
      };

  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
        id: json['id'],
        jobId: json['jobId'],
        senderId: json['senderId'],
        text: json['text'],
        image: json['image'],
        file: json['file'],
        createdAt: DateTime.parse(json['createdAt']),
        isRead: json['isRead'] ?? false,
        receiverId: json['receiverId'],
      );
}
