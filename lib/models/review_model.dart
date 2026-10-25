class ReviewModel {
  final String id;
  final String authorName;
  final String authorLocation;
  final int rating;
  final String relativeTime;
  final String text;
  final String avatarUrl;
  final bool isVerified;
  final bool isPublished;
  final int sortOrder;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.authorName,
    this.authorLocation = '',
    this.rating = 5,
    this.relativeTime = 'Recently',
    required this.text,
    this.avatarUrl = '',
    this.isVerified = true,
    this.isPublished = true,
    this.sortOrder = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  ReviewModel copyWith({
    String? id,
    String? authorName,
    String? authorLocation,
    int? rating,
    String? relativeTime,
    String? text,
    String? avatarUrl,
    bool? isVerified,
    bool? isPublished,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      authorName: authorName ?? this.authorName,
      authorLocation: authorLocation ?? this.authorLocation,
      rating: rating ?? this.rating,
      relativeTime: relativeTime ?? this.relativeTime,
      text: text ?? this.text,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isVerified: isVerified ?? this.isVerified,
      isPublished: isPublished ?? this.isPublished,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'authorName': authorName,
      'authorLocation': authorLocation,
      'rating': rating,
      'relativeTime': relativeTime,
      'text': text,
      'avatarUrl': avatarUrl,
      'isVerified': isVerified,
      'isPublished': isPublished,
      'sortOrder': sortOrder,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ReviewModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    String textVal = '';
    if (map['text'] is Map) {
      textVal = map['text']['en']?.toString() ?? map['text']['si']?.toString() ?? '';
    } else {
      textVal = map['text']?.toString() ?? '';
    }

    String locVal = '';
    if (map['authorLocation'] is Map) {
      locVal = map['authorLocation']['en']?.toString() ?? map['authorLocation']['si']?.toString() ?? '';
    } else {
      locVal = map['authorLocation']?.toString() ?? '';
    }

    String timeVal = '';
    if (map['relativeTime'] is Map) {
      timeVal = map['relativeTime']['en']?.toString() ?? map['relativeTime']['si']?.toString() ?? '';
    } else {
      timeVal = map['relativeTime']?.toString() ?? map['timeAgo']?.toString() ?? 'Recently';
    }

    DateTime parsedDate;
    if (map['createdAt'] is String) {
      parsedDate = DateTime.tryParse(map['createdAt']) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return ReviewModel(
      id: docId ?? map['id']?.toString() ?? 'rev_${DateTime.now().millisecondsSinceEpoch}',
      authorName: map['authorName']?.toString() ?? 'Google User',
      authorLocation: locVal,
      rating: (map['rating'] as num?)?.toInt() ?? 5,
      relativeTime: timeVal,
      text: textVal,
      avatarUrl: map['avatarUrl']?.toString() ?? '',
      isVerified: map['isVerified'] != false && map['verified'] != false,
      isPublished: map['isPublished'] != false,
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
      createdAt: parsedDate,
    );
  }
}
