class TierPricing {
  final String tierId;
  final String tierName;
  final String tierNameSi;
  final String badge;
  final String badgeSi;
  final double priceLKR; // Customer Price
  final double staffPayoutRateLKR; // Staff Caregiver Payout Rate
  final String pricingUnit;
  final List<String> duties;
  final List<String> dutiesSi;
  final bool isRecommended;

  TierPricing({
    required this.tierId,
    required this.tierName,
    this.tierNameSi = '',
    this.badge = '',
    this.badgeSi = '',
    required this.priceLKR,
    double? staffPayoutRateLKR,
    this.pricingUnit = '/ day',
    required this.duties,
    this.dutiesSi = const [],
    this.isRecommended = false,
  }) : staffPayoutRateLKR = staffPayoutRateLKR ?? (priceLKR * 0.80);

  TierPricing copyWith({
    String? tierId,
    String? tierName,
    String? tierNameSi,
    String? badge,
    String? badgeSi,
    double? priceLKR,
    double? staffPayoutRateLKR,
    String? pricingUnit,
    List<String>? duties,
    List<String>? dutiesSi,
    bool? isRecommended,
  }) {
    return TierPricing(
      tierId: tierId ?? this.tierId,
      tierName: tierName ?? this.tierName,
      tierNameSi: tierNameSi ?? this.tierNameSi,
      badge: badge ?? this.badge,
      badgeSi: badgeSi ?? this.badgeSi,
      priceLKR: priceLKR ?? this.priceLKR,
      staffPayoutRateLKR: staffPayoutRateLKR ?? this.staffPayoutRateLKR,
      pricingUnit: pricingUnit ?? this.pricingUnit,
      duties: duties ?? this.duties,
      dutiesSi: dutiesSi ?? this.dutiesSi,
      isRecommended: isRecommended ?? this.isRecommended,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tierId': tierId,
      'tierName': {
        'en': tierName,
        'si': tierNameSi.isNotEmpty ? tierNameSi : tierName,
        'ta': '',
      },
      'tierNameEn': tierName,
      'tierNameSi': tierNameSi,
      'badge': {
        'en': badge,
        'si': badgeSi.isNotEmpty ? badgeSi : badge,
        'ta': '',
      },
      'badgeEn': badge,
      'badgeSi': badgeSi,
      'priceLKR': priceLKR,
      'staffPayoutRateLKR': staffPayoutRateLKR,
      'pricingUnit': {
        'en': pricingUnit,
        'si': pricingUnit,
        'ta': '',
      },
      'isRecommended': isRecommended,
      'responsibilities': {
        'en': duties,
        'si': dutiesSi.isNotEmpty ? dutiesSi : duties,
        'ta': <String>[],
      },
      'duties': duties,
      'dutiesSi': dutiesSi,
    };
  }

  factory TierPricing.fromMap(Map<String, dynamic> data) {
    String tName = '';
    String tNameSi = '';
    if (data['tierName'] is Map) {
      tName = data['tierName']['en']?.toString() ?? '';
      tNameSi = data['tierName']['si']?.toString() ?? '';
    } else {
      tName = data['tierNameEn']?.toString() ?? data['tierName']?.toString() ?? '';
      tNameSi = data['tierNameSi']?.toString() ?? '';
    }

    String bName = '';
    String bNameSi = '';
    if (data['badge'] is Map) {
      bName = data['badge']['en']?.toString() ?? '';
      bNameSi = data['badge']['si']?.toString() ?? '';
    } else {
      bName = data['badgeEn']?.toString() ?? data['badge']?.toString() ?? '';
      bNameSi = data['badgeSi']?.toString() ?? '';
    }

    String pUnit = '/ day';
    if (data['pricingUnit'] is Map) {
      pUnit = data['pricingUnit']['en']?.toString() ?? '/ day';
    } else if (data['pricingUnit'] is String) {
      pUnit = data['pricingUnit'];
    }

    List<String> dutyList = [];
    List<String> dutyListSi = [];
    if (data['responsibilities'] is Map) {
      final enList = data['responsibilities']['en'];
      if (enList is List) dutyList = enList.map((e) => e.toString()).toList();
      final siList = data['responsibilities']['si'];
      if (siList is List) dutyListSi = siList.map((e) => e.toString()).toList();
    } else if (data['duties'] is List) {
      dutyList = (data['duties'] as List).map((e) => e.toString()).toList();
    }

    if (dutyListSi.isEmpty && data['dutiesSi'] is List) {
      dutyListSi = (data['dutiesSi'] as List).map((e) => e.toString()).toList();
    }

    return TierPricing(
      tierId: data['tierId']?.toString() ?? 'tier_${DateTime.now().millisecondsSinceEpoch}',
      tierName: tName.isNotEmpty ? tName : 'Caregiver Tier',
      tierNameSi: tNameSi,
      badge: bName,
      badgeSi: bNameSi,
      priceLKR: (data['priceLKR'] as num?)?.toDouble() ?? 4500.0,
      staffPayoutRateLKR: (data['staffPayoutRateLKR'] as num?)?.toDouble(),
      pricingUnit: pUnit,
      duties: dutyList,
      dutiesSi: dutyListSi,
      isRecommended: data['isRecommended'] == true,
    );
  }
}

class ServiceModel {
  final String id;
  final String nameEn;
  final String nameSi;
  final String category; // elderly_care, child_care, short_visit, recovery, specialized, etc.
  final int hours;
  final String shiftType; // 12h_day, 12h_night, 24h_full, short_visit
  final double defaultPriceLKR;
  final String pricingUnit; // / day, / night, / visit, / month
  final String shortDescription;
  final String shortDescriptionSi;
  final String icon; // Sun, Moon, Home, HeartPulse, Baby, Brain, Clock, Smile
  final List<TierPricing> tiers;
  final bool isActive;
  final int sortOrder;

  ServiceModel({
    required this.id,
    required this.nameEn,
    required this.nameSi,
    required this.category,
    required this.hours,
    this.shiftType = '12h_day',
    required this.defaultPriceLKR,
    required this.pricingUnit,
    required this.shortDescription,
    this.shortDescriptionSi = '',
    this.icon = 'HeartPulse',
    required this.tiers,
    this.isActive = true,
    this.sortOrder = 0,
  });

  ServiceModel copyWith({
    String? id,
    String? nameEn,
    String? nameSi,
    String? category,
    int? hours,
    String? shiftType,
    double? defaultPriceLKR,
    String? pricingUnit,
    String? shortDescription,
    String? shortDescriptionSi,
    String? icon,
    List<TierPricing>? tiers,
    bool? isActive,
    int? sortOrder,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      nameEn: nameEn ?? this.nameEn,
      nameSi: nameSi ?? this.nameSi,
      category: category ?? this.category,
      hours: hours ?? this.hours,
      shiftType: shiftType ?? this.shiftType,
      defaultPriceLKR: defaultPriceLKR ?? this.defaultPriceLKR,
      pricingUnit: pricingUnit ?? this.pricingUnit,
      shortDescription: shortDescription ?? this.shortDescription,
      shortDescriptionSi: shortDescriptionSi ?? this.shortDescriptionSi,
      icon: icon ?? this.icon,
      tiers: tiers ?? this.tiers,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'name': {
        'en': nameEn,
        'si': nameSi.isNotEmpty ? nameSi : nameEn,
        'ta': '',
      },
      'nameEn': nameEn,
      'nameSi': nameSi,
      'shortDescription': {
        'en': shortDescription,
        'si': shortDescriptionSi.isNotEmpty ? shortDescriptionSi : shortDescription,
        'ta': '',
      },
      'shortDescriptionEn': shortDescription,
      'shortDescriptionSi': shortDescriptionSi,
      'description': {
        'en': shortDescription,
        'si': shortDescriptionSi.isNotEmpty ? shortDescriptionSi : shortDescription,
        'ta': '',
      },
      'shiftType': shiftType,
      'hours': hours,
      'priceLKR': defaultPriceLKR,
      'defaultPriceLKR': defaultPriceLKR,
      'pricingUnit': {
        'en': pricingUnit,
        'si': pricingUnit,
        'ta': '',
      },
      'icon': icon,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'updatedAt': DateTime.now().toIso8601String(),
      'tiers': tiers.map((t) => t.toMap()).toList(),
    };
  }

  factory ServiceModel.fromMap(Map<String, dynamic> data, [String? docId]) {
    String nEn = '';
    String nSi = '';
    if (data['name'] is Map) {
      nEn = data['name']['en']?.toString() ?? '';
      nSi = data['name']['si']?.toString() ?? '';
    } else {
      nEn = data['nameEn']?.toString() ?? data['name']?.toString() ?? '';
      nSi = data['nameSi']?.toString() ?? '';
    }

    String descEn = '';
    String descSi = '';
    if (data['shortDescription'] is Map) {
      descEn = data['shortDescription']['en']?.toString() ?? '';
      descSi = data['shortDescription']['si']?.toString() ?? '';
    } else {
      descEn = data['shortDescriptionEn']?.toString() ?? data['shortDescription']?.toString() ?? '';
      descSi = data['shortDescriptionSi']?.toString() ?? '';
    }

    String pUnit = '/ day';
    if (data['pricingUnit'] is Map) {
      pUnit = data['pricingUnit']['en']?.toString() ?? '/ day';
    } else if (data['pricingUnit'] is String) {
      pUnit = data['pricingUnit'];
    }

    List<TierPricing> parsedTiers = [];
    if (data['tiers'] is List) {
      for (final t in (data['tiers'] as List)) {
        if (t is Map) {
          try {
            parsedTiers.add(TierPricing.fromMap(Map<String, dynamic>.from(t)));
          } catch (_) {}
        }
      }
    }

    double basePrice = (data['priceLKR'] as num?)?.toDouble() ??
        (data['defaultPriceLKR'] as num?)?.toDouble() ??
        4500.0;

    int shiftHours = (data['hours'] as num?)?.toInt() ?? 12;

    String sType = data['shiftType']?.toString() ?? (shiftHours == 24 ? '24h_full' : shiftHours == 2 ? 'short_visit' : '12h_day');

    return ServiceModel(
      id: docId ?? data['id']?.toString() ?? 'svc_${DateTime.now().millisecondsSinceEpoch}',
      nameEn: nEn.isNotEmpty ? nEn : 'Healthcare Package',
      nameSi: nSi.isNotEmpty ? nSi : nEn,
      category: data['category']?.toString() ?? 'elderly_care',
      hours: shiftHours,
      shiftType: sType,
      defaultPriceLKR: basePrice,
      pricingUnit: pUnit,
      shortDescription: descEn,
      shortDescriptionSi: descSi,
      icon: data['icon']?.toString() ?? 'HeartPulse',
      tiers: parsedTiers,
      isActive: data['isActive'] != false,
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }
}
