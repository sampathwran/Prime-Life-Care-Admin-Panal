class StoreCategoryModel {
  final String id;
  final String nameEn;
  final String nameSi;
  final String? icon;
  final String? description;
  final bool isDefault;
  final int sortOrder;
  final DateTime createdAt;

  StoreCategoryModel({
    required this.id,
    required this.nameEn,
    required this.nameSi,
    this.icon,
    this.description,
    this.isDefault = false,
    this.sortOrder = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  StoreCategoryModel copyWith({
    String? id,
    String? nameEn,
    String? nameSi,
    String? icon,
    String? description,
    bool? isDefault,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return StoreCategoryModel(
      id: id ?? this.id,
      nameEn: nameEn ?? this.nameEn,
      nameSi: nameSi ?? this.nameSi,
      icon: icon ?? this.icon,
      description: description ?? this.description,
      isDefault: isDefault ?? this.isDefault,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory StoreCategoryModel.fromMap(Map<String, dynamic> map, String id) {
    return StoreCategoryModel(
      id: id.isNotEmpty ? id : (map['id']?.toString() ?? 'cat_${DateTime.now().millisecondsSinceEpoch}'),
      nameEn: map['nameEn']?.toString() ?? map['name']?.toString() ?? 'General Category',
      nameSi: map['nameSi']?.toString() ?? map['nameEn']?.toString() ?? map['name']?.toString() ?? 'සාමාන්‍ය කාණ්ඩය',
      icon: map['icon']?.toString(),
      description: map['description']?.toString(),
      isDefault: map['isDefault'] == true,
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nameEn': nameEn,
      'nameSi': nameSi,
      'icon': icon,
      'description': description,
      'isDefault': isDefault,
      'sortOrder': sortOrder,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
