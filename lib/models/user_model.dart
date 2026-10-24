class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? photoURL;
  final String district;
  final String city;
  final String address;
  final String createdAt;
  final int savedPatientsCount;
  final String? savedPatientsSummary;
  final int totalBookingsCount;
  final String status; // active, new, verified

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.photoURL,
    required this.district,
    required this.city,
    required this.address,
    required this.createdAt,
    this.savedPatientsCount = 0,
    this.savedPatientsSummary,
    this.totalBookingsCount = 0,
    this.status = 'active',
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? photoURL,
    String? district,
    String? city,
    String? address,
    String? createdAt,
    int? savedPatientsCount,
    String? savedPatientsSummary,
    int? totalBookingsCount,
    String? status,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoURL: photoURL ?? this.photoURL,
      district: district ?? this.district,
      city: city ?? this.city,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      savedPatientsCount: savedPatientsCount ?? this.savedPatientsCount,
      savedPatientsSummary: savedPatientsSummary ?? this.savedPatientsSummary,
      totalBookingsCount: totalBookingsCount ?? this.totalBookingsCount,
      status: status ?? this.status,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    int patientsCount = 0;
    String? patientsSummary;
    if (map['savedPatients'] is List) {
      final list = map['savedPatients'] as List;
      patientsCount = list.length;
      if (list.isNotEmpty) {
        patientsSummary = list.map((p) => (p is Map ? p['name'] ?? '' : '')).where((s) => s.isNotEmpty).join(', ');
      }
    }

    return UserModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      name: map['name'] ?? map['displayName'] ?? 'Registered Member',
      email: map['email'] ?? '',
      phone: map['phone'] ?? map['phoneNumber'] ?? '',
      photoURL: map['photoURL'],
      district: map['district'] ?? 'Colombo',
      city: map['city'] ?? 'Colombo',
      address: map['address'] ?? '',
      createdAt: map['createdAt'] ?? DateTime.now().toIso8601String(),
      savedPatientsCount: patientsCount > 0 ? patientsCount : (map['savedPatientsCount'] ?? 0),
      savedPatientsSummary: patientsSummary ?? map['savedPatientsSummary'],
      totalBookingsCount: map['totalBookingsCount'] ?? 0,
      status: map['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'photoURL': photoURL,
      'district': district,
      'city': city,
      'address': address,
      'createdAt': createdAt,
      'savedPatientsCount': savedPatientsCount,
      'savedPatientsSummary': savedPatientsSummary,
      'totalBookingsCount': totalBookingsCount,
      'status': status,
    };
  }
}
