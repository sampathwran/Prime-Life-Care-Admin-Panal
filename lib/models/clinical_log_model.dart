class ClinicalLogModel {
  final String id;
  final String bookingCode;
  final String patientName;
  final String caregiverName;
  final String recordedAt;
  final String bloodPressure;
  final String bloodSugar;
  final int pulseRate;
  final int spO2;
  final String temperature;
  final bool bedsoreTurnDone;
  final bool medicationGiven;
  final String clinicalNotes;
  final bool isSupervisorReviewed;

  ClinicalLogModel({
    required this.id,
    required this.bookingCode,
    required this.patientName,
    required this.caregiverName,
    required this.recordedAt,
    required this.bloodPressure,
    required this.bloodSugar,
    required this.pulseRate,
    required this.spO2,
    required this.temperature,
    required this.bedsoreTurnDone,
    required this.medicationGiven,
    required this.clinicalNotes,
    this.isSupervisorReviewed = true,
  });

  ClinicalLogModel copyWith({
    String? id,
    String? bookingCode,
    String? patientName,
    String? caregiverName,
    String? recordedAt,
    String? bloodPressure,
    String? bloodSugar,
    int? pulseRate,
    int? spO2,
    String? temperature,
    bool? bedsoreTurnDone,
    bool? medicationGiven,
    String? clinicalNotes,
    bool? isSupervisorReviewed,
  }) {
    return ClinicalLogModel(
      id: id ?? this.id,
      bookingCode: bookingCode ?? this.bookingCode,
      patientName: patientName ?? this.patientName,
      caregiverName: caregiverName ?? this.caregiverName,
      recordedAt: recordedAt ?? this.recordedAt,
      bloodPressure: bloodPressure ?? this.bloodPressure,
      bloodSugar: bloodSugar ?? this.bloodSugar,
      pulseRate: pulseRate ?? this.pulseRate,
      spO2: spO2 ?? this.spO2,
      temperature: temperature ?? this.temperature,
      bedsoreTurnDone: bedsoreTurnDone ?? this.bedsoreTurnDone,
      medicationGiven: medicationGiven ?? this.medicationGiven,
      clinicalNotes: clinicalNotes ?? this.clinicalNotes,
      isSupervisorReviewed: isSupervisorReviewed ?? this.isSupervisorReviewed,
    );
  }
}
