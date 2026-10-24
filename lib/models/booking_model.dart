class BookingModel {
  final String id;
  final String bookingCode;
  final String serviceName;
  final String staffTierName;
  final String shiftType; // 12h_day, 12h_night, 24h_full, visit
  final int shiftHours;
  final double pricePerDayLKR;
  final String patientName;
  final int patientAge;
  final String patientGender;
  final String mobility; // independent, partial, wheelchair, bedridden
  final String medicalConditions;
  final String district;
  final String city;
  final String address;
  final String contactName;
  final String contactPhone;
  final String startDate;
  final int durationDays;
  final double totalCostLKR;
  final String status; // pending_review, in_process, broadcasted, caregiver_assigned, in_progress, completed
  final String? assignedCaregiverId;
  final String? assignedCaregiverName;
  final String? assignedCaregiverPhone;
  final String paymentStatus; // unpaid, advance_paid, fully_paid
  final String createdAt;
  final List<Map<String, dynamic>> candidateQueue;
  final int maxCandidates;
  final int acceptedCandidateCount;
  final String? targetTier;
  final double? latitude;
  final double? longitude;
  final String? googleMapsUrl;
  final double staffDailyPayoutLKR;
  final double staffTotalPayoutLKR;
  final List<Map<String, dynamic>> shifts;
  final int completedShiftsCount;
  final bool isCaregiverCheckedIn;
  final String? lastCheckInTime;
  final String? lastCheckOutTime;
  final Map<String, dynamic>? vitalsPlan;
  final List<String> carePlanTasks;
  final String? earlyDischargeNote;
  final String paymentMethod; // bank_transfer, cash_to_caregiver
  final double advanceAmountLKR;
  final Map<String, dynamic>? caregiverChangeRequest;

  BookingModel({
    required this.id,
    required this.bookingCode,
    required this.serviceName,
    required this.staffTierName,
    required this.shiftType,
    required this.shiftHours,
    required this.pricePerDayLKR,
    required this.patientName,
    required this.patientAge,
    required this.patientGender,
    required this.mobility,
    required this.medicalConditions,
    required this.district,
    required this.city,
    required this.address,
    required this.contactName,
    required this.contactPhone,
    required this.startDate,
    required this.durationDays,
    required this.totalCostLKR,
    required this.status,
    this.assignedCaregiverId,
    this.assignedCaregiverName,
    this.assignedCaregiverPhone,
    required this.paymentStatus,
    required this.createdAt,
    this.candidateQueue = const [],
    this.maxCandidates = 10,
    this.acceptedCandidateCount = 0,
    this.targetTier,
    this.latitude,
    this.longitude,
    this.googleMapsUrl,
    double? staffDailyPayoutLKR,
    double? staffTotalPayoutLKR,
    this.shifts = const [],
    this.completedShiftsCount = 0,
    this.isCaregiverCheckedIn = false,
    this.lastCheckInTime,
    this.lastCheckOutTime,
    this.vitalsPlan,
    this.carePlanTasks = const [],
    this.earlyDischargeNote,
    this.paymentMethod = 'cash_to_caregiver',
    this.advanceAmountLKR = 0.0,
    this.caregiverChangeRequest,
  })  : staffDailyPayoutLKR = staffDailyPayoutLKR ?? (pricePerDayLKR * 0.80),
        staffTotalPayoutLKR = staffTotalPayoutLKR ?? (totalCostLKR * 0.80);

  bool get hasCaregiverChangeRequest => caregiverChangeRequest != null && caregiverChangeRequest!['requested'] == true;
  String get caregiverChangeReason => caregiverChangeRequest?['reason']?.toString() ?? '';

  bool get isNewWeb => status == 'pending_review' || status == 'new_web';
  bool get isInProcess => status == 'in_process' || status == 'under_review';
  bool get isBroadcasted => status == 'broadcasted' || status == 'published_open';
  bool get isOnDuty => status == 'caregiver_assigned' || status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get hasLocation => (latitude != null && longitude != null) || (googleMapsUrl != null && googleMapsUrl!.isNotEmpty);
  String get effectiveMapsUrl => googleMapsUrl ?? (latitude != null && longitude != null ? 'https://www.google.com/maps?q=$latitude,$longitude' : '');
  bool get isQueueFull => acceptedCandidateCount >= maxCandidates || candidateQueue.length >= maxCandidates;

  int get remainingDays {
    DateTime? start = DateTime.tryParse(startDate);
    if (start == null && createdAt.isNotEmpty) {
      start = DateTime.tryParse(createdAt);
    }
    start ??= DateTime.now();
    final end = start.add(Duration(days: durationDays));
    final diff = end.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  int get totalCompletedShifts => completedShiftsCount > 0 ? completedShiftsCount : shifts.length;

  BookingModel copyWith({
    String? id,
    String? bookingCode,
    String? serviceName,
    String? staffTierName,
    String? shiftType,
    int? shiftHours,
    double? pricePerDayLKR,
    String? patientName,
    int? patientAge,
    String? patientGender,
    String? mobility,
    String? medicalConditions,
    String? district,
    String? city,
    String? address,
    String? contactName,
    String? contactPhone,
    String? startDate,
    int? durationDays,
    double? totalCostLKR,
    String? status,
    String? assignedCaregiverId,
    String? assignedCaregiverName,
    String? assignedCaregiverPhone,
    String? paymentStatus,
    String? createdAt,
    List<Map<String, dynamic>>? candidateQueue,
    int? maxCandidates,
    int? acceptedCandidateCount,
    String? targetTier,
    double? latitude,
    double? longitude,
    String? googleMapsUrl,
    double? staffDailyPayoutLKR,
    double? staffTotalPayoutLKR,
    List<Map<String, dynamic>>? shifts,
    int? completedShiftsCount,
    bool? isCaregiverCheckedIn,
    String? lastCheckInTime,
    String? lastCheckOutTime,
    Map<String, dynamic>? vitalsPlan,
    List<String>? carePlanTasks,
    String? earlyDischargeNote,
    String? paymentMethod,
    double? advanceAmountLKR,
    Map<String, dynamic>? caregiverChangeRequest,
    bool clearAssignedCaregiver = false,
  }) {
    return BookingModel(
      id: id ?? this.id,
      bookingCode: bookingCode ?? this.bookingCode,
      serviceName: serviceName ?? this.serviceName,
      staffTierName: staffTierName ?? this.staffTierName,
      shiftType: shiftType ?? this.shiftType,
      shiftHours: shiftHours ?? this.shiftHours,
      pricePerDayLKR: pricePerDayLKR ?? this.pricePerDayLKR,
      patientName: patientName ?? this.patientName,
      patientAge: patientAge ?? this.patientAge,
      patientGender: patientGender ?? this.patientGender,
      mobility: mobility ?? this.mobility,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      district: district ?? this.district,
      city: city ?? this.city,
      address: address ?? this.address,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
      startDate: startDate ?? this.startDate,
      durationDays: durationDays ?? this.durationDays,
      totalCostLKR: totalCostLKR ?? this.totalCostLKR,
      status: status ?? this.status,
      assignedCaregiverId: clearAssignedCaregiver ? null : (assignedCaregiverId ?? this.assignedCaregiverId),
      assignedCaregiverName: clearAssignedCaregiver ? null : (assignedCaregiverName ?? this.assignedCaregiverName),
      assignedCaregiverPhone: clearAssignedCaregiver ? null : (assignedCaregiverPhone ?? this.assignedCaregiverPhone),
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdAt: createdAt ?? this.createdAt,
      candidateQueue: candidateQueue ?? this.candidateQueue,
      maxCandidates: maxCandidates ?? this.maxCandidates,
      acceptedCandidateCount: acceptedCandidateCount ?? this.acceptedCandidateCount,
      targetTier: targetTier ?? this.targetTier,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      googleMapsUrl: googleMapsUrl ?? this.googleMapsUrl,
      staffDailyPayoutLKR: staffDailyPayoutLKR ?? this.staffDailyPayoutLKR,
      staffTotalPayoutLKR: staffTotalPayoutLKR ?? this.staffTotalPayoutLKR,
      shifts: shifts ?? this.shifts,
      completedShiftsCount: completedShiftsCount ?? this.completedShiftsCount,
      isCaregiverCheckedIn: isCaregiverCheckedIn ?? this.isCaregiverCheckedIn,
      lastCheckInTime: lastCheckInTime ?? this.lastCheckInTime,
      lastCheckOutTime: lastCheckOutTime ?? this.lastCheckOutTime,
      vitalsPlan: vitalsPlan ?? this.vitalsPlan,
      carePlanTasks: carePlanTasks ?? this.carePlanTasks,
      earlyDischargeNote: earlyDischargeNote ?? this.earlyDischargeNote,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      advanceAmountLKR: advanceAmountLKR ?? this.advanceAmountLKR,
      caregiverChangeRequest: caregiverChangeRequest ?? this.caregiverChangeRequest,
    );
  }

  static String resolveTargetTier(Map<String, dynamic> map) {
    final raw = (map['targetTier'] ?? map['staffTierId'] ?? map['staffTier'] ?? map['requiredTier'] ?? '').toString().toLowerCase();
    final name = (map['staffTierName'] ?? map['requiredTierName'] ?? map['serviceName'] ?? '').toString().toLowerCase();
    if (raw.contains('5') || raw.contains('nurse') || raw.contains('nurs') || name.contains('5') || name.contains('nurse') || name.contains('nurs') || name.contains('clinical')) {
      return 'nvq5_nurse';
    }
    return 'nvq4_aide';
  }

  factory BookingModel.fromMap(Map<String, dynamic> map, String docId) {
    final rawQueue = map['candidateQueue'];
    List<Map<String, dynamic>> queue = [];
    if (rawQueue is List) {
      queue = rawQueue.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    }

    final rawShifts = map['shifts'];
    List<Map<String, dynamic>> shiftsList = [];
    if (rawShifts is List) {
      shiftsList = rawShifts.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    }

    List<String> careTasks = [];
    if (map['carePlanTasks'] is List) {
      careTasks = (map['carePlanTasks'] as List).map((e) => e.toString()).toList();
    }

    Map<String, dynamic>? vitals;
    if (map['vitalsPlan'] is Map) {
      vitals = Map<String, dynamic>.from(map['vitalsPlan'] as Map);
    }

    final pricePerDay = ((map['pricePerDayLKR'] ?? map['priceLKR'] ?? map['dailyRateLKR']) as num?)?.toDouble() ?? 4500.0;
    final totalCost = ((map['totalCostLKR'] ?? map['totalEarningsLKR']) as num?)?.toDouble() ?? 0.0;
    final staffDaily = ((map['staffDailyRateLKR'] ?? map['staffDailyPayoutLKR']) as num?)?.toDouble() ?? (pricePerDay * 0.80);
    final staffTotal = ((map['staffTotalEarningsLKR'] ?? map['staffTotalPayoutLKR']) as num?)?.toDouble() ?? (totalCost * 0.80);

    return BookingModel(
      id: docId,
      bookingCode: map['bookingCode']?.toString() ?? docId,
      serviceName: map['serviceName']?.toString() ?? 'Elderly Care',
      staffTierName: (map['staffTierName'] ?? map['requiredTierName'])?.toString() ?? 'NVQ Level 4 Certified Caregiver',
      shiftType: map['shiftType']?.toString() ?? '12h_day',
      shiftHours: (map['shiftHours'] as num?)?.toInt() ?? 12,
      pricePerDayLKR: pricePerDay,
      patientName: map['patientName']?.toString() ?? 'Patient',
      patientAge: (map['patientAge'] as num?)?.toInt() ?? 75,
      patientGender: map['patientGender']?.toString() ?? 'Male',
      mobility: (map['mobility'] ?? map['mobilityLevel'])?.toString() ?? 'partial',
      medicalConditions: (map['medicalConditions'] ?? map['diagnosis'])?.toString() ?? 'None specified',
      district: map['district']?.toString() ?? 'Colombo',
      city: map['city']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      contactName: (map['contactName'] ?? map['guardianName'])?.toString() ?? '',
      contactPhone: (map['contactPhone'] ?? map['guardianPhone'])?.toString() ?? '',
      startDate: map['startDate']?.toString() ?? '',
      durationDays: (map['durationDays'] as num?)?.toInt() ?? 7,
      totalCostLKR: totalCost,
      status: map['status']?.toString() ?? 'pending_review',
      assignedCaregiverId: map['assignedCaregiverId']?.toString(),
      assignedCaregiverName: map['assignedCaregiverName']?.toString(),
      assignedCaregiverPhone: map['assignedCaregiverPhone']?.toString(),
      paymentStatus: map['paymentStatus']?.toString() ?? 'unpaid',
      createdAt: map['createdAt']?.toString() ?? '',
      candidateQueue: queue,
      maxCandidates: (map['maxCandidates'] as num?)?.toInt() ?? 10,
      acceptedCandidateCount: (map['acceptedCandidateCount'] as num?)?.toInt() ?? queue.length,
      targetTier: resolveTargetTier(map),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      googleMapsUrl: map['googleMapsUrl']?.toString(),
      staffDailyPayoutLKR: staffDaily,
      staffTotalPayoutLKR: staffTotal,
      shifts: shiftsList,
      completedShiftsCount: (map['completedShiftsCount'] as num?)?.toInt() ?? shiftsList.length,
      isCaregiverCheckedIn: map['isCaregiverCheckedIn'] == true,
      lastCheckInTime: map['lastCheckInTime']?.toString(),
      lastCheckOutTime: map['lastCheckOutTime']?.toString(),
      vitalsPlan: vitals,
      carePlanTasks: careTasks,
      earlyDischargeNote: map['earlyDischargeNote']?.toString(),
      paymentMethod: map['paymentMethod']?.toString() ?? 'cash_to_caregiver',
      advanceAmountLKR: ((map['advanceAmountLKR'] ?? map['advanceAmount']) as num?)?.toDouble() ?? 0.0,
      caregiverChangeRequest: map['caregiverChangeRequest'] is Map ? Map<String, dynamic>.from(map['caregiverChangeRequest'] as Map) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bookingCode': bookingCode,
      'serviceName': serviceName,
      'staffTierName': staffTierName,
      'shiftType': shiftType,
      'shiftHours': shiftHours,
      'pricePerDayLKR': pricePerDayLKR,
      'priceLKR': pricePerDayLKR,
      'dailyRateLKR': pricePerDayLKR,
      'staffDailyRateLKR': staffDailyPayoutLKR,
      'staffDailyPayoutLKR': staffDailyPayoutLKR,
      'patientName': patientName,
      'patientAge': patientAge,
      'patientGender': patientGender,
      'mobility': mobility,
      'mobilityLevel': mobility,
      'medicalConditions': medicalConditions,
      'diagnosis': medicalConditions,
      'district': district,
      'city': city,
      'address': address,
      'contactName': contactName,
      'guardianName': contactName,
      'contactPhone': contactPhone,
      'guardianPhone': contactPhone,
      'startDate': startDate,
      'durationDays': durationDays,
      'totalCostLKR': totalCostLKR,
      'totalEarningsLKR': totalCostLKR,
      'staffTotalEarningsLKR': staffTotalPayoutLKR,
      'staffTotalPayoutLKR': staffTotalPayoutLKR,
      'status': status,
      'assignedCaregiverId': assignedCaregiverId,
      'assignedCaregiverName': assignedCaregiverName,
      'assignedCaregiverPhone': assignedCaregiverPhone,
      'paymentStatus': paymentStatus,
      'createdAt': createdAt,
      'candidateQueue': candidateQueue,
      'maxCandidates': maxCandidates,
      'acceptedCandidateCount': acceptedCandidateCount,
      'targetTier': targetTier,
      'latitude': latitude,
      'longitude': longitude,
      'googleMapsUrl': googleMapsUrl,
      'shifts': shifts,
      'completedShiftsCount': completedShiftsCount,
      'isCaregiverCheckedIn': isCaregiverCheckedIn,
      'lastCheckInTime': lastCheckInTime,
      'lastCheckOutTime': lastCheckOutTime,
      'vitalsPlan': vitalsPlan,
      'carePlanTasks': carePlanTasks,
      if (earlyDischargeNote != null) 'earlyDischargeNote': earlyDischargeNote,
    };
  }
}
