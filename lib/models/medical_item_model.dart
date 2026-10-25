class MedicalItemModel {
  final String id;
  final String nameEn;
  final String nameSi;
  final String category; // equipment, mobility, hygiene, monitoring
  final double regularPriceLKR;
  final double salePriceLKR;
  double get buyPriceLKR => salePriceLKR;
  final bool canRent;
  final double? monthlyRentLKR;
  final double? securityDepositLKR;
  final int stock;
  final List<String> imageUrls;
  final String description;
  final bool isAvailable;
  final int discountPercentage;
  final String? brand;
  final String? badge;

  MedicalItemModel({
    required this.id,
    required this.nameEn,
    required this.nameSi,
    required this.category,
    required this.regularPriceLKR,
    required this.salePriceLKR,
    this.canRent = false,
    this.monthlyRentLKR,
    this.securityDepositLKR,
    required this.stock,
    required this.imageUrls,
    required this.description,
    this.isAvailable = true,
    int? discountPercentage,
    this.brand,
    this.badge,
  }) : discountPercentage = discountPercentage ??
            (regularPriceLKR > salePriceLKR && regularPriceLKR > 0
                ? (((regularPriceLKR - salePriceLKR) / regularPriceLKR) * 100).round()
                : 0);

  factory MedicalItemModel.fromMap(Map<String, dynamic> map, String id) {
    final regPrice = (map['regularPriceLKR'] as num?)?.toDouble() ??
        (map['buyPriceLKR'] as num?)?.toDouble() ??
        (map['priceLKR'] as num?)?.toDouble() ??
        0.0;
    final sPrice = (map['salePriceLKR'] as num?)?.toDouble() ??
        (map['buyPriceLKR'] as num?)?.toDouble() ??
        (map['priceLKR'] as num?)?.toDouble() ??
        regPrice;

    List<String> imgs = [];
    if (map['images'] is List) {
      imgs = List<String>.from((map['images'] as List).map((x) => x.toString()));
    } else if (map['imageUrls'] is List) {
      imgs = List<String>.from((map['imageUrls'] as List).map((x) => x.toString()));
    } else if (map['imageUrl'] != null) {
      imgs = [map['imageUrl'].toString()];
    }

    String nameEn = '';
    String nameSi = '';
    if (map['name'] is Map) {
      nameEn = map['name']['en']?.toString() ?? '';
      nameSi = map['name']['si']?.toString() ?? nameEn;
    } else {
      nameEn = map['nameEn']?.toString() ?? map['name']?.toString() ?? '';
      nameSi = map['nameSi']?.toString() ?? nameEn;
    }

    String desc = '';
    if (map['description'] is Map) {
      desc = map['description']['en']?.toString() ?? '';
    } else {
      desc = map['description']?.toString() ?? '';
    }

    return MedicalItemModel(
      id: id,
      nameEn: nameEn.isNotEmpty ? nameEn : 'Hospital Bed',
      nameSi: nameSi.isNotEmpty ? nameSi : nameEn,
      category: map['category']?.toString() ?? 'equipment',
      regularPriceLKR: regPrice > 0 ? regPrice : sPrice,
      salePriceLKR: sPrice > 0 ? sPrice : regPrice,
      canRent: map['canRent'] == true,
      monthlyRentLKR: (map['rentalMonthlyLKR'] ?? map['monthlyRentLKR'] as num?)?.toDouble(),
      securityDepositLKR: (map['securityDepositLKR'] as num?)?.toDouble(),
      stock: (map['stock'] as num?)?.toInt() ?? 1,
      imageUrls: imgs,
      description: desc,
      isAvailable: map['isAvailable'] != false,
      discountPercentage: (map['discountPercentage'] as num?)?.toInt(),
      brand: map['brand']?.toString(),
      badge: map['badge']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': {
        'en': nameEn,
        'si': nameSi,
        'ta': nameEn,
      },
      'nameEn': nameEn,
      'nameSi': nameSi,
      'category': category,
      'regularPriceLKR': regularPriceLKR,
      'salePriceLKR': salePriceLKR,
      'priceLKR': salePriceLKR,
      'buyPriceLKR': salePriceLKR,
      'discountPercentage': discountPercentage,
      'canRent': canRent,
      'rentalMonthlyLKR': monthlyRentLKR,
      'monthlyRentLKR': monthlyRentLKR,
      'securityDepositLKR': securityDepositLKR,
      'stock': stock,
      'inStock': stock > 0,
      'images': imageUrls,
      'imageUrls': imageUrls,
      'description': {
        'en': description,
        'si': description,
        'ta': description,
      },
      'isAvailable': isAvailable,
      'brand': brand ?? 'Paramount Health',
      'badge': badge ?? (discountPercentage > 0 ? '$discountPercentage% OFF • Essential ICU' : 'In Stock'),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  MedicalItemModel copyWith({
    String? id,
    String? nameEn,
    String? nameSi,
    String? category,
    double? regularPriceLKR,
    double? salePriceLKR,
    bool? canRent,
    double? monthlyRentLKR,
    double? securityDepositLKR,
    int? stock,
    List<String>? imageUrls,
    String? description,
    bool? isAvailable,
    int? discountPercentage,
    String? brand,
    String? badge,
  }) {
    return MedicalItemModel(
      id: id ?? this.id,
      nameEn: nameEn ?? this.nameEn,
      nameSi: nameSi ?? this.nameSi,
      category: category ?? this.category,
      regularPriceLKR: regularPriceLKR ?? this.regularPriceLKR,
      salePriceLKR: salePriceLKR ?? this.salePriceLKR,
      canRent: canRent ?? this.canRent,
      monthlyRentLKR: monthlyRentLKR ?? this.monthlyRentLKR,
      securityDepositLKR: securityDepositLKR ?? this.securityDepositLKR,
      stock: stock ?? this.stock,
      imageUrls: imageUrls ?? this.imageUrls,
      description: description ?? this.description,
      isAvailable: isAvailable ?? this.isAvailable,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      brand: brand ?? this.brand,
      badge: badge ?? this.badge,
    );
  }
}
