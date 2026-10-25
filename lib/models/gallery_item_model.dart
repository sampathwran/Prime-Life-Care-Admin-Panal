class GalleryItemModel {
  final String id;
  final String title;
  final String titleSi;
  final String imageUrl;
  final String category;
  final String description;
  final bool isPublished;
  final int sortOrder;
  final DateTime createdAt;

  GalleryItemModel({
    required this.id,
    required this.title,
    this.titleSi = '',
    required this.imageUrl,
    this.category = 'Elderly Care',
    this.description = '',
    this.isPublished = true,
    this.sortOrder = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  GalleryItemModel copyWith({
    String? id,
    String? title,
    String? titleSi,
    String? imageUrl,
    String? category,
    String? description,
    bool? isPublished,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return GalleryItemModel(
      id: id ?? this.id,
      title: title ?? this.title,
      titleSi: titleSi ?? this.titleSi,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      description: description ?? this.description,
      isPublished: isPublished ?? this.isPublished,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'titleSi': titleSi,
      'imageUrl': imageUrl,
      'category': category,
      'description': description,
      'isPublished': isPublished,
      'sortOrder': sortOrder,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory GalleryItemModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime parsedDate;
    if (map['createdAt'] is String) {
      parsedDate = DateTime.tryParse(map['createdAt']) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return GalleryItemModel(
      id: docId ?? map['id']?.toString() ?? 'gal_${DateTime.now().millisecondsSinceEpoch}',
      title: map['title']?.toString() ?? 'Care Photo',
      titleSi: map['titleSi']?.toString() ?? '',
      imageUrl: map['imageUrl']?.toString() ?? '',
      category: map['category']?.toString() ?? 'Elderly Care',
      description: map['description']?.toString() ?? '',
      isPublished: map['isPublished'] != false,
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
      createdAt: parsedDate,
    );
  }
}
