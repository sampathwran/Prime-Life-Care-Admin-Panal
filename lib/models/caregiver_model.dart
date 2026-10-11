class CaregiverModel {
  final String id;
  final String name;
  final String phone;
  final String tier; // basic_aide, nurse_assistant, nvq_4_caregiver, nvq_5_nurse, doctor
  final String tierLabel;
  final String district;
  final bool isPoliceVerified;
  final bool isMedicalCleared;
  final bool isCprCertified;
  final String status; // available, on_duty, on_leave
  final String? activeAssignedPatient;
  final double rating;
  final int completedShifts;

  CaregiverModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.tier,
    required this.tierLabel,
    required this.district,
    required this.isPoliceVerified,
    required this.isMedicalCleared,
    required this.isCprCertified,
    required this.status,
    this.activeAssignedPatient,
    this.rating = 4.9,
    this.completedShifts = 0,
  });

  CaregiverModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? tier,
    String? tierLabel,
    String? district,
    bool? isPoliceVerified,
    bool? isMedicalCleared,
    bool? isCprCertified,
    String? status,
    String? activeAssignedPatient,
    double? rating,
    int? completedShifts,
  }) {
    return CaregiverModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      tier: tier ?? this.tier,
      tierLabel: tierLabel ?? this.tierLabel,
      district: district ?? this.district,
      isPoliceVerified: isPoliceVerified ?? this.isPoliceVerified,
      isMedicalCleared: isMedicalCleared ?? this.isMedicalCleared,
      isCprCertified: isCprCertified ?? this.isCprCertified,
      status: status ?? this.status,
      activeAssignedPatient: activeAssignedPatient ?? this.activeAssignedPatient,
      rating: rating ?? this.rating,
      completedShifts: completedShifts ?? this.completedShifts,
    );
  }
}
