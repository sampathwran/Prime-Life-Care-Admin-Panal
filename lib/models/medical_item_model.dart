class MedicalItemModel {
  final String id;
  final String nameEn;
  final String nameSi;
  final String category; // equipment, mobility, hygiene, monitoring
  final double buyPriceLKR;
  final bool canRent;
  final double? monthlyRentLKR;
  final double? securityDepositLKR;
  final int stock;
  final List<String> imageUrls;
  final String description;
  final bool isAvailable;

  MedicalItemModel({
    required this.id,
    required this.nameEn,
    required this.nameSi,
    required this.category,
    required this.buyPriceLKR,
    this.canRent = false,
    this.monthlyRentLKR,
    this.securityDepositLKR,
    required this.stock,
    required this.imageUrls,
    required this.description,
    this.isAvailable = true,
  });

  MedicalItemModel copyWith({
    String? id,
    String? nameEn,
    String? nameSi,
    String? category,
    double? buyPriceLKR,
    bool? canRent,
    double? monthlyRentLKR,
    double? securityDepositLKR,
    int? stock,
    List<String>? imageUrls,
    String? description,
    bool? isAvailable,
  }) {
    return MedicalItemModel(
      id: id ?? this.id,
      nameEn: nameEn ?? this.nameEn,
      nameSi: nameSi ?? this.nameSi,
      category: category ?? this.category,
      buyPriceLKR: buyPriceLKR ?? this.buyPriceLKR,
      canRent: canRent ?? this.canRent,
      monthlyRentLKR: monthlyRentLKR ?? this.monthlyRentLKR,
      securityDepositLKR: securityDepositLKR ?? this.securityDepositLKR,
      stock: stock ?? this.stock,
      imageUrls: imageUrls ?? this.imageUrls,
      description: description ?? this.description,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}
