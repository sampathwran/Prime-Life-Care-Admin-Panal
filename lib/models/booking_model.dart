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
  final String status; // pending_review, caregiver_assigned, in_progress, completed
  final String? assignedCaregiverId;
  final String? assignedCaregiverName;
  final String? assignedCaregiverPhone;
  final String paymentStatus; // unpaid, advance_paid, fully_paid
  final String createdAt;

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
  });

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
      assignedCaregiverId: assignedCaregiverId ?? this.assignedCaregiverId,
      assignedCaregiverName: assignedCaregiverName ?? this.assignedCaregiverName,
      assignedCaregiverPhone: assignedCaregiverPhone ?? this.assignedCaregiverPhone,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
