class PortfolioItemModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final List<String> imageUrls;
  final String category;
  final DateTime createdAt;

  PortfolioItemModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.imageUrls,
    required this.category,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'title': title,
        'description': description,
        'imageUrls': imageUrls,
        'category': category,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PortfolioItemModel.fromJson(Map<String, dynamic> json) =>
      PortfolioItemModel(
        id: json['id'],
        userId: json['userId'],
        title: json['title'],
        description: json['description'],
        imageUrls: List<String>.from(json['imageUrls'] ?? []),
        category: json['category'],
        createdAt: DateTime.parse(json['createdAt']),
      );
}
