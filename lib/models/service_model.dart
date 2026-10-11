class TierPricing {
  final String tierId;
  final String tierName;
  final double priceLKR;
  final List<String> duties;

  TierPricing({
    required this.tierId,
    required this.tierName,
    required this.priceLKR,
    required this.duties,
  });

  TierPricing copyWith({
    String? tierId,
    String? tierName,
    double? priceLKR,
    List<String>? duties,
  }) {
    return TierPricing(
      tierId: tierId ?? this.tierId,
      tierName: tierName ?? this.tierName,
      priceLKR: priceLKR ?? this.priceLKR,
      duties: duties ?? this.duties,
    );
  }
}

class ServiceModel {
  final String id;
  final String nameEn;
  final String nameSi;
  final String category; // elderly_care, child_care, recovery, specialized, short_visit
  final int hours;
  final double defaultPriceLKR;
  final String pricingUnit; // / day, / night, / visit
  final String shortDescription;
  final List<TierPricing> tiers;
  final bool isActive;

  ServiceModel({
    required this.id,
    required this.nameEn,
    required this.nameSi,
    required this.category,
    required this.hours,
    required this.defaultPriceLKR,
    required this.pricingUnit,
    required this.shortDescription,
    required this.tiers,
    this.isActive = true,
  });

  ServiceModel copyWith({
    String? id,
    String? nameEn,
    String? nameSi,
    String? category,
    int? hours,
    double? defaultPriceLKR,
    String? pricingUnit,
    String? shortDescription,
    List<TierPricing>? tiers,
    bool? isActive,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      nameEn: nameEn ?? this.nameEn,
      nameSi: nameSi ?? this.nameSi,
      category: category ?? this.category,
      hours: hours ?? this.hours,
      defaultPriceLKR: defaultPriceLKR ?? this.defaultPriceLKR,
      pricingUnit: pricingUnit ?? this.pricingUnit,
      shortDescription: shortDescription ?? this.shortDescription,
      tiers: tiers ?? this.tiers,
      isActive: isActive ?? this.isActive,
    );
  }
}
