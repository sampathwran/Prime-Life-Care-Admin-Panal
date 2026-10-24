import 'package:cloud_firestore/cloud_firestore.dart';

class CaregiverModel {
  final String id;
  final String membershipNumber;
  final String name;
  final String phone;
  final String email;
  final String tier; // basic_aide, nurse_assistant, nvq_4_caregiver, nvq_5_nurse, doctor
  final String tierLabel;
  final String district;
  final bool isPoliceVerified;
  final bool isMedicalCleared;
  final bool isCprCertified;
  final String status; // available, on_duty, on_leave, inactive
  final String? activeAssignedPatient;
  final String? activeAssignedBookingId;
  final double rating;
  final int completedShifts;
  final DateTime? lastDutyCompletedAt;
  final String? nic;
  final String? address;
  final String gender;
  final int age;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String bio;
  final String experienceYears;
  final String approvalStatus; // 'pending_approval', 'approved', 'rejected'
  final String? rejectionReason;
  final List<Map<String, dynamic>> documents;

  // Language & Clinical Skills
  final List<Map<String, dynamic>> languages;
  final List<String> clinicalSkills;

  // Earnings & Finance
  final double dailyRateLKR;
  final double hourlyRateLKR;
  final double totalEarnings;
  final double pendingPayout;
  final Map<String, dynamic> bankDetails;

  // Verification & Document Pipeline Fields
  final String? profileImageUrl;
  final String profileImageStatus; // 'missing', 'pending', 'approved', 'rejected'
  final String? nicFrontUrl;
  final String nicFrontStatus;
  final String? nicBackUrl;
  final String nicBackStatus;
  final String? policeReportUrl;
  final String policeReportStatus;
  final String? qualificationCertUrl;
  final String qualificationCertStatus;
  final String faceVerificationStatus; // 'missing', 'pending', 'approved', 'rejected'
  final Map<String, dynamic>? faceVerificationData;
  final Map<String, dynamic> verificationItems;
  final bool isVerifiedMember;

  bool get isApproved => approvalStatus == 'approved';
  bool get isPendingApproval => approvalStatus == 'pending_approval';
  bool get isRejected => approvalStatus == 'rejected';

  // An already approved or verified member who submitted a new qualification for review
  bool get hasPendingQualificationUpgrade {
    if (!isVerifiedMember && !isApproved) return false;
    if (qualificationCertStatus == 'pending') return true;
    final certItem = verificationItems['qualification_cert'];
    if (certItem is Map && certItem['status'] == 'pending') return true;
    return documents.any((d) => (d['status'] == 'pending_review' || d['status'] == 'pending'));
  }

  bool get isProfileImageApproved => profileImageStatus == 'approved';
  bool get isNicFrontApproved => nicFrontStatus == 'approved';
  bool get isNicBackApproved => nicBackStatus == 'approved';
  bool get isPoliceReportApproved => policeReportStatus == 'approved';
  bool get isQualificationCertApproved => qualificationCertStatus == 'approved';
  bool get isFaceVerificationApproved => faceVerificationStatus == 'approved';

  String? get faceVerificationSnapshotUrl {
    if (faceVerificationData != null) {
      final snap = faceVerificationData!['snapshot'] ?? faceVerificationData!['selfieUrl'] ?? faceVerificationData!['url'];
      if (snap is String && snap.isNotEmpty && snap != 'live_camera_capture') {
        return snap;
      }
    }
    if (verificationItems['face_verification'] is Map) {
      final f = verificationItems['face_verification'] as Map;
      final url = f['url'] ?? f['snapshot'];
      if (url is String && url.isNotEmpty && url != 'live_camera_capture') {
        return url;
      }
    }
    return null;
  }

  int get approvedVerificationCount {
    int count = 0;
    if (isProfileImageApproved) count++;
    if (isNicFrontApproved) count++;
    if (isNicBackApproved) count++;
    if (isPoliceReportApproved) count++;
    if (isQualificationCertApproved) count++;
    if (isFaceVerificationApproved) count++;
    return count;
  }

  int get totalVerificationCount => 6;
  double get verificationProgress => approvedVerificationCount / 6.0;

  CaregiverModel({
    required this.id,
    String? membershipNumber,
    required this.name,
    required this.phone,
    this.email = '',
    required this.tier,
    required this.tierLabel,
    required this.district,
    required this.isPoliceVerified,
    required this.isMedicalCleared,
    required this.isCprCertified,
    required this.status,
    this.activeAssignedPatient,
    this.activeAssignedBookingId,
    this.rating = 5.0,
    this.completedShifts = 0,
    this.lastDutyCompletedAt,
    this.nic,
    this.address,
    this.gender = 'Female',
    this.age = 32,
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.bio = '',
    this.experienceYears = '3+ Years',
    this.approvalStatus = 'pending_approval',
    this.rejectionReason,
    List<Map<String, dynamic>>? documents,
    List<Map<String, dynamic>>? languages,
    List<String>? clinicalSkills,
    this.dailyRateLKR = 4500.0,
    this.hourlyRateLKR = 500.0,
    this.totalEarnings = 0.0,
    this.pendingPayout = 0.0,
    Map<String, dynamic>? bankDetails,
    this.profileImageUrl,
    this.profileImageStatus = 'missing',
    this.nicFrontUrl,
    this.nicFrontStatus = 'missing',
    this.nicBackUrl,
    this.nicBackStatus = 'missing',
    this.policeReportUrl,
    this.policeReportStatus = 'missing',
    this.qualificationCertUrl,
    this.qualificationCertStatus = 'missing',
    this.faceVerificationStatus = 'missing',
    this.faceVerificationData,
    Map<String, dynamic>? verificationItems,
    this.isVerifiedMember = false,
  })  : membershipNumber = membershipNumber ?? id,
        documents = documents ?? [],
        languages = languages ?? [
          {'languageName': 'Sinhala', 'languageCode': 'si', 'speakingPercent': 100, 'writingPercent': 100, 'understandingPercent': 100},
          {'languageName': 'English', 'languageCode': 'en', 'speakingPercent': 80, 'writingPercent': 75, 'understandingPercent': 85},
          {'languageName': 'Tamil', 'languageCode': 'ta', 'speakingPercent': 60, 'writingPercent': 40, 'understandingPercent': 65},
        ],
        clinicalSkills = clinicalSkills ?? [
          'Elderly Bedside Assistance',
          'Bed Turning & Bedsore Prevention',
          'BP & Sugar Vitals Monitoring',
          'Medication Timing Routine',
          'Assisted Sponge Bathing',
        ],
        bankDetails = bankDetails ?? {},
        verificationItems = verificationItems ?? {};

  factory CaregiverModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    final regNo = (map['membershipNumber'] ?? map['staffRegNo'] ?? map['id'] ?? docId ?? 'PLC-1001').toString();
    final name = (map['name'] ?? map['fullName'] ?? 'Caregiver').toString();
    final tier = (map['tier'] ?? 'nvq_4_caregiver').toString();
    final tierLabel = (map['tierLabel'] ?? map['qualification'] ?? 'NVQ Level 4 Certified Caregiver').toString();
    final district = (map['district'] ?? map['assignedZone'] ?? map['city'] ?? 'Colombo').toString();
    final approval = (map['approvalStatus'] ?? (map['isPoliceVerified'] == true ? 'approved' : 'pending_approval')).toString();

    final docsList = <Map<String, dynamic>>[];
    if (map['documents'] is List) {
      for (final d in map['documents']) {
        if (d is Map) {
          docsList.add(Map<String, dynamic>.from(d));
        }
      }
    }

    final langsList = <Map<String, dynamic>>[];
    if (map['languages'] is List && (map['languages'] as List).isNotEmpty) {
      for (final l in map['languages']) {
        if (l is Map) {
          langsList.add(Map<String, dynamic>.from(l));
        }
      }
    }

    final skillsList = <String>[];
    if (map['clinicalSkills'] is List && (map['clinicalSkills'] as List).isNotEmpty) {
      for (final s in map['clinicalSkills']) {
        skillsList.add(s.toString());
      }
    }

    final bDetails = (map['bankDetails'] is Map)
        ? Map<String, dynamic>.from(map['bankDetails'] as Map)
        : <String, dynamic>{};

    final vItems = (map['verificationItems'] is Map)
        ? Map<String, dynamic>.from(map['verificationItems'] as Map)
        : <String, dynamic>{};

    String getVStatus(String key, String fallbackField) {
      if (vItems[key] is Map && vItems[key]['status'] != null) {
        return vItems[key]['status'].toString();
      }
      return (map[fallbackField] ?? 'missing').toString();
    }

    String? getVUrl(String key, String fallbackField) {
      if (vItems[key] is Map && vItems[key]['url'] != null) {
        return vItems[key]['url'] as String?;
      }
      return map[fallbackField] as String?;
    }

    final pImgStatus = getVStatus('profile_image', 'profileImageStatus');
    final nFrontStatus = getVStatus('nic_front', 'nicFrontStatus');
    final nBackStatus = getVStatus('nic_back', 'nicBackStatus');
    final pRepStatus = getVStatus('police_report', 'policeReportStatus');
    final qCertStatus = getVStatus('qualification_cert', 'qualificationCertStatus');
    final fVerStatus = getVStatus('face_verification', 'faceVerificationStatus');

    final bool allApproved = pImgStatus == 'approved' &&
        nFrontStatus == 'approved' &&
        nBackStatus == 'approved' &&
        pRepStatus == 'approved' &&
        qCertStatus == 'approved' &&
        fVerStatus == 'approved';

    final bool isVerified = (map['isVerifiedMember'] == true) || allApproved;

    DateTime? lastDuty;
    if (map['lastDutyCompletedAt'] != null) {
      final val = map['lastDutyCompletedAt'];
      if (val is Timestamp) {
        lastDuty = val.toDate();
      } else if (val is DateTime) {
        lastDuty = val;
      } else if (val is int) {
        lastDuty = DateTime.fromMillisecondsSinceEpoch(val);
      } else if (val is String) {
        lastDuty = DateTime.tryParse(val);
      }
    }

    return CaregiverModel(
      id: docId ?? regNo,
      membershipNumber: regNo,
      name: name,
      phone: (map['phone'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      tier: tier,
      tierLabel: tierLabel,
      district: district,
      isPoliceVerified: map['isPoliceVerified'] == true,
      isMedicalCleared: map['isMedicalCleared'] != false,
      isCprCertified: map['isCprCertified'] == true,
      status: (map['status'] ?? 'available').toString(),
      activeAssignedPatient: map['activeAssignedPatient'] as String?,
      activeAssignedBookingId: map['activeAssignedBookingId'] as String?,
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      completedShifts: (map['completedShifts'] as num?)?.toInt() ?? 0,
      lastDutyCompletedAt: lastDuty,
      nic: map['nic'] as String?,
      address: map['address'] as String?,
      gender: (map['gender'] ?? 'Female').toString(),
      age: (map['age'] as num?)?.toInt() ?? 32,
      emergencyContactName: (map['emergencyContactName'] ?? '').toString(),
      emergencyContactPhone: (map['emergencyContactPhone'] ?? '').toString(),
      bio: (map['bio'] ?? '').toString(),
      experienceYears: (map['experienceYears'] ?? '3+ Years').toString(),
      approvalStatus: approval,
      rejectionReason: map['rejectionReason'] as String?,
      documents: docsList,
      languages: langsList.isNotEmpty ? langsList : null,
      clinicalSkills: skillsList.isNotEmpty ? skillsList : null,
      dailyRateLKR: (map['dailyRateLKR'] as num?)?.toDouble() ?? (map['dailyEarnings'] as num?)?.toDouble() ?? 4500.0,
      hourlyRateLKR: (map['hourlyRateLKR'] as num?)?.toDouble() ?? 500.0,
      totalEarnings: (map['totalEarnings'] as num?)?.toDouble() ?? 0.0,
      pendingPayout: (map['pendingPayout'] as num?)?.toDouble() ?? 0.0,
      bankDetails: bDetails,
      profileImageUrl: getVUrl('profile_image', 'profileImageUrl'),
      profileImageStatus: pImgStatus,
      nicFrontUrl: getVUrl('nic_front', 'nicFrontUrl'),
      nicFrontStatus: nFrontStatus,
      nicBackUrl: getVUrl('nic_back', 'nicBackUrl'),
      nicBackStatus: nBackStatus,
      policeReportUrl: getVUrl('police_report', 'policeReportUrl'),
      policeReportStatus: pRepStatus,
      qualificationCertUrl: getVUrl('qualification_cert', 'qualificationCertUrl'),
      qualificationCertStatus: qCertStatus,
      faceVerificationStatus: fVerStatus,
      faceVerificationData: (map['faceVerificationData'] is Map)
          ? Map<String, dynamic>.from(map['faceVerificationData'] as Map)
          : null,
      verificationItems: vItems,
      isVerifiedMember: isVerified,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'membershipNumber': membershipNumber,
      'staffRegNo': membershipNumber,
      'name': name,
      'fullName': name,
      'phone': phone,
      'email': email,
      'tier': tier,
      'tierLabel': tierLabel,
      'qualification': tierLabel,
      'district': district,
      'assignedZone': district,
      'isPoliceVerified': isPoliceVerified,
      'isMedicalCleared': isMedicalCleared,
      'isCprCertified': isCprCertified,
      'status': status,
      'activeAssignedPatient': activeAssignedPatient,
      'activeAssignedBookingId': activeAssignedBookingId,
      'rating': rating,
      'completedShifts': completedShifts,
      if (lastDutyCompletedAt != null) 'lastDutyCompletedAt': lastDutyCompletedAt!.toIso8601String(),
      'approvalStatus': approvalStatus,
      'isApproved': isApproved,
      'isVerifiedMember': isVerifiedMember,
      'verificationStatus': isVerifiedMember ? 'verified' : 'inactive',
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      'documents': documents,
      if (nic != null) 'nic': nic,
      if (address != null) 'address': address,
      'gender': gender,
      'age': age,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'bio': bio,
      'experienceYears': experienceYears,
      'languages': languages,
      'clinicalSkills': clinicalSkills,
      'dailyRateLKR': dailyRateLKR,
      'dailyEarnings': dailyRateLKR,
      'hourlyRateLKR': hourlyRateLKR,
      'totalEarnings': totalEarnings,
      'pendingPayout': pendingPayout,
      'bankDetails': bankDetails,
      // Verification Items
      'profileImageUrl': profileImageUrl,
      'profileImageStatus': profileImageStatus,
      'nicFrontUrl': nicFrontUrl,
      'nicFrontStatus': nicFrontStatus,
      'nicBackUrl': nicBackUrl,
      'nicBackStatus': nicBackStatus,
      'policeReportUrl': policeReportUrl,
      'policeReportStatus': policeReportStatus,
      'qualificationCertUrl': qualificationCertUrl,
      'qualificationCertStatus': qualificationCertStatus,
      'faceVerificationStatus': faceVerificationStatus,
      if (faceVerificationData != null) 'faceVerificationData': faceVerificationData,
      'verificationItems': verificationItems,
    };
  }

  CaregiverModel copyWith({
    String? id,
    String? membershipNumber,
    String? name,
    String? phone,
    String? email,
    String? tier,
    String? tierLabel,
    String? district,
    bool? isPoliceVerified,
    bool? isMedicalCleared,
    bool? isCprCertified,
    String? status,
    String? activeAssignedPatient,
    String? activeAssignedBookingId,
    double? rating,
    int? completedShifts,
    DateTime? lastDutyCompletedAt,
    String? nic,
    String? address,
    String? gender,
    int? age,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? bio,
    String? experienceYears,
    String? approvalStatus,
    String? rejectionReason,
    List<Map<String, dynamic>>? documents,
    List<Map<String, dynamic>>? languages,
    List<String>? clinicalSkills,
    double? dailyRateLKR,
    double? hourlyRateLKR,
    double? totalEarnings,
    double? pendingPayout,
    Map<String, dynamic>? bankDetails,
    String? profileImageUrl,
    String? profileImageStatus,
    String? nicFrontUrl,
    String? nicFrontStatus,
    String? nicBackUrl,
    String? nicBackStatus,
    String? policeReportUrl,
    String? policeReportStatus,
    String? qualificationCertUrl,
    String? qualificationCertStatus,
    String? faceVerificationStatus,
    Map<String, dynamic>? faceVerificationData,
    Map<String, dynamic>? verificationItems,
    bool? isVerifiedMember,
  }) {
    return CaregiverModel(
      id: id ?? this.id,
      membershipNumber: membershipNumber ?? this.membershipNumber,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      tier: tier ?? this.tier,
      tierLabel: tierLabel ?? this.tierLabel,
      district: district ?? this.district,
      isPoliceVerified: isPoliceVerified ?? this.isPoliceVerified,
      isMedicalCleared: isMedicalCleared ?? this.isMedicalCleared,
      isCprCertified: isCprCertified ?? this.isCprCertified,
      status: status ?? this.status,
      activeAssignedPatient: activeAssignedPatient ?? this.activeAssignedPatient,
      activeAssignedBookingId: activeAssignedBookingId ?? this.activeAssignedBookingId,
      rating: rating ?? this.rating,
      completedShifts: completedShifts ?? this.completedShifts,
      lastDutyCompletedAt: lastDutyCompletedAt ?? this.lastDutyCompletedAt,
      nic: nic ?? this.nic,
      address: address ?? this.address,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      bio: bio ?? this.bio,
      experienceYears: experienceYears ?? this.experienceYears,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      documents: documents ?? this.documents,
      languages: languages ?? this.languages,
      clinicalSkills: clinicalSkills ?? this.clinicalSkills,
      dailyRateLKR: dailyRateLKR ?? this.dailyRateLKR,
      hourlyRateLKR: hourlyRateLKR ?? this.hourlyRateLKR,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      pendingPayout: pendingPayout ?? this.pendingPayout,
      bankDetails: bankDetails ?? this.bankDetails,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      profileImageStatus: profileImageStatus ?? this.profileImageStatus,
      nicFrontUrl: nicFrontUrl ?? this.nicFrontUrl,
      nicFrontStatus: nicFrontStatus ?? this.nicFrontStatus,
      nicBackUrl: nicBackUrl ?? this.nicBackUrl,
      nicBackStatus: nicBackStatus ?? this.nicBackStatus,
      policeReportUrl: policeReportUrl ?? this.policeReportUrl,
      policeReportStatus: policeReportStatus ?? this.policeReportStatus,
      qualificationCertUrl: qualificationCertUrl ?? this.qualificationCertUrl,
      qualificationCertStatus: qualificationCertStatus ?? this.qualificationCertStatus,
      faceVerificationStatus: faceVerificationStatus ?? this.faceVerificationStatus,
      faceVerificationData: faceVerificationData ?? this.faceVerificationData,
      verificationItems: verificationItems ?? this.verificationItems,
      isVerifiedMember: isVerifiedMember ?? this.isVerifiedMember,
    );
  }
}
