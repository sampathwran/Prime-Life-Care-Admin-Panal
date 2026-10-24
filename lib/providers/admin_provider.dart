import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import '../models/service_model.dart';
import '../models/medical_item_model.dart';
import '../models/order_model.dart';
import '../models/caregiver_model.dart';
import '../models/clinical_log_model.dart';
import '../models/user_model.dart';

class AdminProvider extends ChangeNotifier {
  int _selectedNavIndex = 0;
  int get selectedNavIndex => _selectedNavIndex;

  void setSelectedNavIndex(int index) {
    _selectedNavIndex = index;
    notifyListeners();
  }

  // Selected Tab for Bookings Workflow
  String _selectedBookingTab = 'all';
  String get selectedBookingTab => _selectedBookingTab;
  void setSelectedBookingTab(String tab) {
    _selectedBookingTab = tab;
    notifyListeners();
  }

  // Search filter query
  String _searchQuery = '';
  String get searchQuery => _searchQuery;
  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  // ===================== FIREBASE REAL-TIME SYNC =====================
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _bookingsSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ordersSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _usersSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _statsSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _deletedBookingsSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _caregiversSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _servicesSubscription;
  bool _isFirebaseConnected = false;
  bool get isFirebaseConnected => _isFirebaseConnected;

  List<Map<String, dynamic>> _deletedBookings = [];
  List<Map<String, dynamic>> get deletedBookings => _deletedBookings;

  void initFirebaseListeners() {
    try {
      final firestore = FirebaseFirestore.instance;

      // 1. Listen to real-time Bookings from Web & Apps
      _bookingsSubscription = firestore
          .collection('bookings')
          .snapshots()
          .listen((snapshot) {
        _isFirebaseConnected = true;
        _bookings = snapshot.docs.map((doc) {
          return BookingModel.fromMap(doc.data(), doc.id);
        }).toList();
        notifyListeners();
      }, onError: (err) {
        debugPrint('[AdminProvider] Firestore bookings listen warning: $err');
      });

      // 2. Listen to real-time Orders from Web Store
      _ordersSubscription = firestore
          .collection('orders')
          .snapshots()
          .listen((snapshot) {
        _isFirebaseConnected = true;
        _orders = snapshot.docs.map((doc) {
          return OrderModel.fromMap(doc.data(), doc.id);
        }).toList();
        notifyListeners();
      }, onError: (err) {
        debugPrint('[AdminProvider] Firestore orders listen warning: $err');
      });

      // 3. Listen to real-time Registered Users from Web
      _usersSubscription = firestore
          .collection('users')
          .snapshots()
          .listen((snapshot) {
        _isFirebaseConnected = true;
        _users = snapshot.docs.map((doc) {
          return UserModel.fromMap(doc.data(), doc.id);
        }).toList();
        notifyListeners();
      }, onError: (err) {
        debugPrint('[AdminProvider] Firestore users listen warning: $err');
      });

      // 4. Listen to real-time Traffic / Visitors stats
      final trafficDocRef = firestore.collection('site_stats').doc('traffic');
      trafficDocRef.get().then((docSnap) {
        if (docSnap.exists) {
          final data = docSnap.data();
          if (data != null && (data['totalVisitors'] ?? 0) >= 14820) {
            trafficDocRef.set({
              'totalVisitors': 0,
              'todayVisitors': 0,
              'lastResetAt': DateTime.now().toIso8601String(),
            }, SetOptions(merge: true));
          }
        }
      }).catchError((_) {});

      _statsSubscription = trafficDocRef.snapshots().listen((snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data()!;
          int total = (data['totalVisitors'] as num?)?.toInt() ?? 0;
          int today = (data['todayVisitors'] as num?)?.toInt() ?? 0;
          if (total >= 14820) total = 0;
          if (today >= 340) today = 0;
          _totalWebsiteVisitors = total;
          _todayWebsiteVisitors = today;
          notifyListeners();
        }
      }, onError: (err) {
        debugPrint('[AdminProvider] Firestore traffic stats listen warning: $err');
      });

      // 5. Listen to Deleted Bookings History & Enforce 7-Day Auto Purge Retention
      _deletedBookingsSubscription = firestore
          .collection('deleted_bookings')
          .snapshots()
          .listen((snapshot) {
        final now = DateTime.now();
        final List<Map<String, dynamic>> list = [];
        for (final doc in snapshot.docs) {
          final data = doc.data();
          data['id'] = doc.id;

          DateTime? deletedAt;
          if (data['deletedAt'] != null) {
            deletedAt = DateTime.tryParse(data['deletedAt'].toString());
          }
          DateTime? expiresAt;
          if (data['expiresAt'] != null) {
            expiresAt = DateTime.tryParse(data['expiresAt'].toString());
          }

          bool isExpired = false;
          if (expiresAt != null && now.isAfter(expiresAt)) {
            isExpired = true;
          } else if (deletedAt != null && now.difference(deletedAt).inDays >= 7) {
            isExpired = true;
          }

          if (isExpired) {
            // Auto-purge permanently from Firestore after 7 days
            doc.reference.delete().catchError((e) => debugPrint('[Firestore] Auto purge error: $e'));
          } else {
            list.add(data);
          }
        }
        _deletedBookings = list;
        notifyListeners();
      }, onError: (err) {
        debugPrint('[AdminProvider] Firestore deleted_bookings listen warning: $err');
      });

      // 6. Listen to Real-Time Caregivers & Staff Directory
      _caregiversSubscription = firestore
          .collection('caregivers')
          .snapshots()
          .listen((snapshot) {
        _caregivers = snapshot.docs.map((doc) {
          return CaregiverModel.fromMap(doc.data(), doc.id);
        }).toList();
        notifyListeners();
      }, onError: (err) {
        debugPrint('[AdminProvider] Firestore caregivers listen warning: $err');
      });

      // 7. Listen to Real-Time Care Packages & Staff Tiers (Auto-sync with Public Web)
      _servicesSubscription = firestore
          .collection('services')
          .snapshots()
          .listen((snapshot) {
        _isFirebaseConnected = true;
        if (snapshot.docs.isNotEmpty) {
          _services = snapshot.docs.map((doc) {
            return ServiceModel.fromMap(doc.data(), doc.id);
          }).toList();
          _services.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          notifyListeners();
        } else {
          // If Firestore is empty, auto-seed rich defaults
          _seedDefaultServicesToFirestore();
        }
      }, onError: (err) {
        debugPrint('[AdminProvider] Firestore services listen warning: $err');
      });
    } catch (e) {
      debugPrint('[AdminProvider] Firebase init warning: $e');
    }
  }

  // ===================== CAREGIVERS DIRECTORY =====================
  List<CaregiverModel> _caregivers = [];

  List<CaregiverModel> get caregivers => _caregivers;

  void addCaregiver(CaregiverModel caregiver) {
    final idx = _caregivers.indexWhere((c) => c.id == caregiver.id || c.membershipNumber == caregiver.membershipNumber);
    if (idx != -1) {
      _caregivers[idx] = caregiver;
    } else {
      _caregivers.add(caregiver);
    }
    notifyListeners();

    try {
      final docId = caregiver.membershipNumber.isNotEmpty ? caregiver.membershipNumber : caregiver.id;
      FirebaseFirestore.instance
          .collection('caregivers')
          .doc(docId)
          .set(caregiver.toMap(), SetOptions(merge: true))
          .catchError((e) => debugPrint('[Firestore] addCaregiver error: $e'));
    } catch (e) {
      debugPrint('[Firestore] addCaregiver error: $e');
    }
  }

  void updateCaregiver(CaregiverModel caregiver) {
    final idx = _caregivers.indexWhere((c) => c.id == caregiver.id || c.membershipNumber == caregiver.membershipNumber);
    if (idx != -1) {
      _caregivers[idx] = caregiver;
      notifyListeners();
    }
    try {
      final docId = caregiver.membershipNumber.isNotEmpty ? caregiver.membershipNumber : caregiver.id;
      FirebaseFirestore.instance
          .collection('caregivers')
          .doc(docId)
          .set(caregiver.toMap(), SetOptions(merge: true))
          .catchError((e) => debugPrint('[Firestore] updateCaregiver error: $e'));
    } catch (e) {
      debugPrint('[Firestore] updateCaregiver error: $e');
    }
  }

  void deleteCaregiver(String id) {
    _caregivers.removeWhere((c) => c.id == id || c.membershipNumber == id);
    notifyListeners();
    try {
      FirebaseFirestore.instance
          .collection('caregivers')
          .doc(id)
          .delete()
          .catchError((e) => debugPrint('[Firestore] deleteCaregiver error: $e'));
    } catch (e) {
      debugPrint('[Firestore] deleteCaregiver error: $e');
    }
  }

  void toggleCaregiverVerification(String id, String field, bool currentValue) {
    final idx = _caregivers.indexWhere((c) => c.id == id || c.membershipNumber == id);
    if (idx != -1) {
      CaregiverModel updated;
      if (field == 'police') {
        updated = _caregivers[idx].copyWith(isPoliceVerified: !currentValue);
      } else if (field == 'medical') {
        updated = _caregivers[idx].copyWith(isMedicalCleared: !currentValue);
      } else if (field == 'cpr') {
        updated = _caregivers[idx].copyWith(isCprCertified: !currentValue);
      } else {
        return;
      }
      _caregivers[idx] = updated;
      notifyListeners();

      try {
        final docId = updated.membershipNumber.isNotEmpty ? updated.membershipNumber : updated.id;
        FirebaseFirestore.instance
            .collection('caregivers')
            .doc(docId)
            .set(updated.toMap(), SetOptions(merge: true))
            .catchError((e) => debugPrint('[Firestore] toggleCaregiverVerification error: $e'));
      } catch (e) {
        debugPrint('[Firestore] toggleCaregiverVerification error: $e');
      }
    }
  }

  Future<void> updateCaregiverApproval(
    String id,
    String status, {
    String? rejectionReason,
  }) async {
    final idx = _caregivers.indexWhere((c) => c.id == id || c.membershipNumber == id);
    if (idx != -1) {
      final isAppr = status == 'approved';
      final updated = _caregivers[idx].copyWith(
        approvalStatus: status,
        isPoliceVerified: isAppr ? true : _caregivers[idx].isPoliceVerified,
        isMedicalCleared: isAppr ? true : _caregivers[idx].isMedicalCleared,
        isCprCertified: isAppr ? true : _caregivers[idx].isCprCertified,
        rejectionReason: isAppr ? null : rejectionReason,
      );
      _caregivers[idx] = updated;
      notifyListeners();

      final docId = updated.membershipNumber.isNotEmpty ? updated.membershipNumber : updated.id;
      try {
        await FirebaseFirestore.instance.collection('caregivers').doc(docId).set(
          updated.toMap(),
          SetOptions(merge: true),
        );

        // Multilingual notification for staff
        final notifId = 'notif-${DateTime.now().millisecondsSinceEpoch}';
        final notif = {
          'id': notifId,
          'titleSinhala': isAppr ? 'සුබ පැතුම්! ඔබගේ ගිණුම අනුමත කරන ලදී 🎉' : 'ලේඛන ප්‍රතික්ෂේප විය - කරුණාකර නැවත යොමු කරන්න ⚠️',
          'titleEnglish': isAppr ? 'Congratulations! Your Account Approved 🎉' : 'Credentials Rejected - Resubmission Needed ⚠️',
          'titleTamil': isAppr ? 'வாழ்த்துக்கள்! உங்கள் கணக்கு அங்கீகரிக்கப்பட்டது 🎉' : 'ஆவணங்கள் நிராகரிக்கப்பட்டன - மீண்டும் சமர்ப்பிக்கவும் ⚠️',
          'messageSinhala': isAppr
              ? 'ඔබගේ ගිණුම සහ සහතික Admin විසින් සාර්ථකව අනුමත කර ඇත. ඔබට දැන් රාජකාරි භාරගත හැක.'
              : 'හේතුව: ${rejectionReason ?? "ලේඛන අසම්පූර්ණයි"}. කරුණාකර නැවත නිවැරදි ලේඛන යොමු කරන්න.',
          'messageEnglish': isAppr
              ? 'Your account and credentials have been verified and approved by Admin. You are now eligible to accept duty bookings.'
              : 'Reason: ${rejectionReason ?? "Incomplete credentials"}. Please resubmit your document via the Staff App.',
          'messageTamil': isAppr
              ? 'உங்கள் கணக்கு மற்றும் ஆவணங்கள் நிர்வாகியால் அங்கீகரிக்கப்பட்டுள்ளன.'
              : 'காரணம்: ${rejectionReason ?? "ஆவணங்கள் முழுமையற்றவை"}. ஆவணங்களை மீண்டும் பதிவேற்றவும்.',
          'timestamp': DateTime.now().toIso8601String(),
          'category': 'qualification',
          'isRead': false,
        };

        await FirebaseFirestore.instance
            .collection('caregivers')
            .doc(docId)
            .collection('notifications')
            .doc(notifId)
            .set(notif);
      } catch (e) {
        debugPrint('[Firestore] updateCaregiverApproval error: $e');
      }
    }
  }

  Future<void> updateCaregiverDocumentStatus(
    String caregiverId,
    String docId,
    String docStatus, {
    String? rejectionReason,
  }) async {
    final idx = _caregivers.indexWhere((c) => c.id == caregiverId || c.membershipNumber == caregiverId);
    if (idx != -1) {
      final cg = _caregivers[idx];
      final docs = List<Map<String, dynamic>>.from(cg.documents);
      final docIdx = docs.indexWhere((d) => d['id'] == docId);
      if (docIdx != -1) {
        docs[docIdx] = Map<String, dynamic>.from(docs[docIdx]);
        docs[docIdx]['status'] = docStatus;
        if (docStatus == 'rejected') {
          docs[docIdx]['rejectionReason'] = rejectionReason;
        } else {
          docs[docIdx].remove('rejectionReason');
        }

        final updated = cg.copyWith(documents: docs);
        _caregivers[idx] = updated;
        notifyListeners();

        final cgDocId = updated.membershipNumber.isNotEmpty ? updated.membershipNumber : updated.id;
        try {
          await FirebaseFirestore.instance.collection('caregivers').doc(cgDocId).set({
            'documents': docs,
          }, SetOptions(merge: true));

          final isVerified = docStatus == 'verified';
          final docTitle = docs[docIdx]['title'] ?? 'Document';
          final notifId = 'notif-doc-${DateTime.now().millisecondsSinceEpoch}';

          final notif = {
            'id': notifId,
            'titleSinhala': isVerified ? '$docTitle සහතිකය අනුමත විය ✓' : '$docTitle සහතිකය ප්‍රතික්ෂේප විය ⚠️',
            'titleEnglish': isVerified ? '$docTitle Approved ✓' : '$docTitle Rejected ⚠️',
            'titleTamil': isVerified ? '$docTitle அங்கீகரிக்கப்பட்டது ✓' : '$docTitle நிராகரிக்கப்பட்டது ⚠️',
            'messageSinhala': isVerified
                ? '$docTitle සහතිකය Admin විසින් සාර්ථකව පරීක්ෂා කර අනුමත කරන ලදී.'
                : '$docTitle ප්‍රතික්ෂේප විය. හේතුව: ${rejectionReason ?? "අසම්පූර්ණයි"}. කරුණාකර නැවත upload කරන්න.',
            'messageEnglish': isVerified
                ? '$docTitle has been verified and approved by Admin.'
                : '$docTitle was rejected. Reason: ${rejectionReason ?? "Incomplete"}. Please re-upload.',
            'messageTamil': isVerified
                ? '$docTitle நிர்வாகியால் சரிபார்க்கப்பட்டது.'
                : '$docTitle நிராகரிக்கப்பட்டது. காரணம்: ${rejectionReason ?? "முழுமையற்றது"}.',
            'timestamp': DateTime.now().toIso8601String(),
            'category': 'qualification',
            'isRead': false,
          };

          await FirebaseFirestore.instance
              .collection('caregivers')
              .doc(cgDocId)
              .collection('notifications')
              .doc(notifId)
              .set(notif);
        } catch (e) {
          debugPrint('[Firestore] updateCaregiverDocumentStatus error: $e');
        }
      }
    }
  }

  Map<String, dynamic> _sanitizeVMap(Map<String, dynamic> vMap) {
    final sanitized = Map<String, dynamic>.from(vMap);
    for (final k in sanitized.keys) {
      if (sanitized[k] is Map) {
        final m = Map<String, dynamic>.from(sanitized[k] as Map);
        if (m['url'] != null && m['url'].toString().startsWith('data:image')) {
          m.remove('url');
        }
        sanitized[k] = m;
      }
    }
    return sanitized;
  }

  // Update Individual Verification Item Status (Profile Image, NIC, Police Report, Qualification, Face Verification)
  Future<void> updateVerificationItemStatus(
    String caregiverId,
    String itemKey,
    String status, {
    String? rejectionReason,
  }) async {
    final idx = _caregivers.indexWhere((c) => c.id == caregiverId || c.membershipNumber == caregiverId);
    if (idx != -1) {
      final cg = _caregivers[idx];
      final vMap = Map<String, dynamic>.from(cg.verificationItems);
      final itemData = (vMap[itemKey] is Map)
          ? Map<String, dynamic>.from(vMap[itemKey] as Map)
          : <String, dynamic>{};

      final isAppr = status == 'approved';
      itemData['status'] = status;
      if (isAppr) {
        itemData.remove('rejectionReason');
      } else {
        itemData['rejectionReason'] = rejectionReason;
      }
      itemData['updatedAt'] = DateTime.now().toIso8601String();
      vMap[itemKey] = itemData;

      // Map itemKey to specific status field
      String? pImgStatus = cg.profileImageStatus;
      String? nFrontStatus = cg.nicFrontStatus;
      String? nBackStatus = cg.nicBackStatus;
      String? pRepStatus = cg.policeReportStatus;
      String? qCertStatus = cg.qualificationCertStatus;
      String? fVerStatus = cg.faceVerificationStatus;

      if (itemKey == 'profile_image') pImgStatus = status;
      if (itemKey == 'nic_front') nFrontStatus = status;
      if (itemKey == 'nic_back') nBackStatus = status;
      if (itemKey == 'police_report') pRepStatus = status;
      if (itemKey == 'qualification_cert') qCertStatus = status;
      if (itemKey == 'face_verification') fVerStatus = status;

      final bool allApproved = pImgStatus == 'approved' &&
          nFrontStatus == 'approved' &&
          nBackStatus == 'approved' &&
          pRepStatus == 'approved' &&
          qCertStatus == 'approved' &&
          fVerStatus == 'approved';

      // Crucial rule: an already verified member never becomes unverified upon uploading a new qualification cert
      final bool isStillVerified = cg.isVerifiedMember || allApproved;

      final updated = cg.copyWith(
        verificationItems: vMap,
        profileImageStatus: pImgStatus,
        nicFrontStatus: nFrontStatus,
        nicBackStatus: nBackStatus,
        policeReportStatus: pRepStatus,
        qualificationCertStatus: qCertStatus,
        faceVerificationStatus: fVerStatus,
        isVerifiedMember: isStillVerified,
        approvalStatus: isStillVerified ? 'approved' : cg.approvalStatus,
      );

      _caregivers[idx] = updated;
      notifyListeners();

      final cgDocId = updated.membershipNumber.isNotEmpty ? updated.membershipNumber : updated.id;
      try {
        final updateData = <String, dynamic>{
          'verificationItems': _sanitizeVMap(vMap),
          'profileImageStatus': pImgStatus,
          'nicFrontStatus': nFrontStatus,
          'nicBackStatus': nBackStatus,
          'policeReportStatus': pRepStatus,
          'qualificationCertStatus': qCertStatus,
          'faceVerificationStatus': fVerStatus,
          'isVerifiedMember': isStillVerified,
          'verificationStatus': isStillVerified ? 'verified' : 'inactive',
        };
        if (isStillVerified) {
          updateData['approvalStatus'] = 'approved';
          updateData['isPoliceVerified'] = true;
        }

        await FirebaseFirestore.instance.collection('caregivers').doc(cgDocId).set(
          updateData,
          SetOptions(merge: true),
        );

        // Titles for push notifications
        String titleSi = 'ලේඛනය';
        String titleEn = 'Item';
        if (itemKey == 'profile_image') {
          titleSi = 'පැතිකඩ ඡායාරූපය (Profile Photo)';
          titleEn = 'Profile Photo';
        } else if (itemKey == 'nic_front') {
          titleSi = 'හැඳුනුම්පත් පෙරපස (NIC Front)';
          titleEn = 'National ID Card Front';
        } else if (itemKey == 'nic_back') {
          titleSi = 'හැඳුනුම්පත් පසුපස (NIC Back)';
          titleEn = 'National ID Card Back';
        } else if (itemKey == 'police_report') {
          titleSi = 'පොලිස් වාර්තාව (Police Report)';
          titleEn = 'Police Clearance Report';
        } else if (itemKey == 'qualification_cert') {
          titleSi = 'මූලික සුදුසුකම් සහතිකය (Qualification Letter)';
          titleEn = 'Qualification Certificate';
        } else if (itemKey == 'face_verification') {
          titleSi = 'සජීවී මුහුණු සත්‍යාපනය (Live Face Verification)';
          titleEn = 'Live Face Biometric Scan';
        }

        final notifId = 'notif-vitem-${DateTime.now().millisecondsSinceEpoch}';
        final notif = {
          'id': notifId,
          'titleSinhala': isAppr ? '$titleSi අනුමත කරන ලදී ✓' : '$titleSi ප්‍රතික්ෂේප විය ⚠️',
          'titleEnglish': isAppr ? '$titleEn Verified & Approved ✓' : '$titleEn Rejected ⚠️',
          'titleTamil': isAppr ? '$titleEn அங்கீகரிக்கப்பட்டது ✓' : '$titleEn நிராகரிக்கப்பட்டது ⚠️',
          'messageSinhala': isAppr
              ? '$titleSi Admin විසින් සාර්ථකව පරීක්ෂා කර අනුමත කරන ලදී.'
              : '$titleSi ප්‍රතික්ෂේප විය. හේතුව: ${rejectionReason ?? "නැවත පැහැදිලි පිටපතක් ඉදිරිපත් කරන්න"}.',
          'messageEnglish': isAppr
              ? '$titleEn was successfully verified & approved by Admin.'
              : '$titleEn was rejected. Reason: ${rejectionReason ?? "Please resubmit"}.',
          'messageTamil': isAppr
              ? '$titleEn நிர்வாகியால் அங்கீகரிக்கப்பட்டது.'
              : '$titleEn நிராகரிக்கப்பட்டது. காரணம்: ${rejectionReason ?? "மீண்டும் சமர்ப்பிக்கவும்"}.',
          'timestamp': DateTime.now().toIso8601String(),
          'category': 'qualification',
          'isRead': false,
        };

        await FirebaseFirestore.instance
            .collection('caregivers')
            .doc(cgDocId)
            .collection('notifications')
            .doc(notifId)
            .set(notif);
      } catch (e) {
        debugPrint('[Firestore] updateVerificationItemStatus error: $e');
      }
    }
  }

  // Master Approve All 6 Verification Items & Activate Member
  Future<void> approveAllVerificationItems(String caregiverId) async {
    final idx = _caregivers.indexWhere((c) => c.id == caregiverId || c.membershipNumber == caregiverId);
    if (idx != -1) {
      final cg = _caregivers[idx];
      final vMap = Map<String, dynamic>.from(cg.verificationItems);
      final keys = ['profile_image', 'nic_front', 'nic_back', 'police_report', 'qualification_cert', 'face_verification'];
      for (final k in keys) {
        final item = (vMap[k] is Map) ? Map<String, dynamic>.from(vMap[k] as Map) : <String, dynamic>{};
        item['status'] = 'approved';
        item.remove('rejectionReason');
        item['updatedAt'] = DateTime.now().toIso8601String();
        vMap[k] = item;
      }

      final updated = cg.copyWith(
        verificationItems: vMap,
        profileImageStatus: 'approved',
        nicFrontStatus: 'approved',
        nicBackStatus: 'approved',
        policeReportStatus: 'approved',
        qualificationCertStatus: 'approved',
        faceVerificationStatus: 'approved',
        isVerifiedMember: true,
        approvalStatus: 'approved',
        isPoliceVerified: true,
        isMedicalCleared: true,
        isCprCertified: true,
      );

      _caregivers[idx] = updated;
      notifyListeners();

      final cgDocId = updated.membershipNumber.isNotEmpty ? updated.membershipNumber : updated.id;
      try {
        await FirebaseFirestore.instance.collection('caregivers').doc(cgDocId).set({
          'verificationItems': _sanitizeVMap(vMap),
          'profileImageStatus': 'approved',
          'nicFrontStatus': 'approved',
          'nicBackStatus': 'approved',
          'policeReportStatus': 'approved',
          'qualificationCertStatus': 'approved',
          'faceVerificationStatus': 'approved',
          'isVerifiedMember': true,
          'verificationStatus': 'verified',
          'approvalStatus': 'approved',
          'isPoliceVerified': true,
          'isMedicalCleared': true,
          'isCprCertified': true,
        }, SetOptions(merge: true));

        final notifId = 'notif-master-${DateTime.now().millisecondsSinceEpoch}';
        final notif = {
          'id': notifId,
          'titleSinhala': 'සුබ පැතුම්! ඔබ දැන් Verified Member කෙනෙකි 🎉',
          'titleEnglish': 'Congratulations! You are now a Verified Member 🎉',
          'titleTamil': 'வாழ்த்துக்கள்! நீங்கள் இப்போது சரிபார்க்கப்பட்ட உறுப்பினர் 🎉',
          'messageSinhala': 'ඔබගේ සියලුම ලේඛන හා මුහුණු සත්‍යාපනය Admin විසින් අනුමත කර ඇත. දැන් ඔබට සියලු රාජකාරි භාරගත හැක.',
          'messageEnglish': 'All your credentials and face verification have been approved. Duty acceptance is now fully unlocked!',
          'messageTamil': 'உங்கள் அனைத்து ஆவணங்களும் அங்கீகரிக்கப்பட்டுள்ளன. இப்போது நீங்கள் அனைத்து பணிகளையும் ஏற்கலாம்.',
          'timestamp': DateTime.now().toIso8601String(),
          'category': 'qualification',
          'isRead': false,
        };

        await FirebaseFirestore.instance
            .collection('caregivers')
            .doc(cgDocId)
            .collection('notifications')
            .doc(notifId)
            .set(notif);
      } catch (e) {
        debugPrint('[Firestore] approveAllVerificationItems error: $e');
      }
    }
  }

  // Get or calculate sequential membership number
  String getNextMembershipNumber() {
    int maxNum = 1000;
    for (final c in _caregivers) {
      final match = RegExp(r'(\d+)').firstMatch(c.membershipNumber);
      if (match != null) {
        final n = int.tryParse(match.group(1)!) ?? 0;
        if (n > maxNum) maxNum = n;
      }
    }
    return 'PLC-${maxNum + 1}';
  }

  // Get Last Duty Completed for a Caregiver
  DateTime? getLastDutyCompleted(CaregiverModel caregiver) {
    if (caregiver.lastDutyCompletedAt != null) {
      return caregiver.lastDutyCompletedAt;
    }
    final completedBookings = _bookings.where((b) {
      final isCompleted = b.status.toLowerCase() == 'completed';
      final matchesStaff = b.assignedCaregiverId == caregiver.id ||
          b.assignedCaregiverId == caregiver.membershipNumber ||
          b.assignedCaregiverName == caregiver.name;
      return isCompleted && matchesStaff;
    }).toList();

    if (completedBookings.isNotEmpty) {
      completedBookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return DateTime.tryParse(completedBookings.first.startDate) ??
          DateTime.tryParse(completedBookings.first.createdAt);
    }
    return null;
  }

  // Upgrade Caregiver Tier & Level upon Qualification Certificate Review
  Future<void> upgradeCaregiverLevel({
    required String caregiverId,
    required String newTier,
    required String newTierLabel,
    String? remarks,
  }) async {
    final idx = _caregivers.indexWhere((c) => c.id == caregiverId || c.membershipNumber == caregiverId);
    if (idx != -1) {
      final cg = _caregivers[idx];
      final vMap = Map<String, dynamic>.from(cg.verificationItems);
      if (vMap['qualification_cert'] is Map) {
        final qData = Map<String, dynamic>.from(vMap['qualification_cert'] as Map);
        qData['status'] = 'approved';
        qData['approvedAt'] = DateTime.now().toIso8601String();
        if (remarks != null && remarks.isNotEmpty) {
          qData['remarks'] = remarks;
        }
        vMap['qualification_cert'] = qData;
      }

      final docs = List<Map<String, dynamic>>.from(cg.documents);
      for (int i = 0; i < docs.length; i++) {
        if (docs[i]['status'] == 'pending_review' || docs[i]['status'] == 'pending') {
          docs[i] = Map<String, dynamic>.from(docs[i]);
          docs[i]['status'] = 'verified';
        }
      }

      final updated = cg.copyWith(
        tier: newTier,
        tierLabel: newTierLabel,
        qualificationCertStatus: 'approved',
        verificationItems: vMap,
        documents: docs,
        isVerifiedMember: true, // Absolutely remains verified!
        approvalStatus: 'approved',
      );

      _caregivers[idx] = updated;
      notifyListeners();

      final docId = updated.membershipNumber.isNotEmpty ? updated.membershipNumber : updated.id;
      try {
        await FirebaseFirestore.instance.collection('caregivers').doc(docId).set({
          'tier': newTier,
          'tierLabel': newTierLabel,
          'qualification': newTierLabel,
          'qualificationCertStatus': 'approved',
          'verificationItems': _sanitizeVMap(vMap),
          'documents': docs,
          'isVerifiedMember': true,
          'verificationStatus': 'verified',
          'approvalStatus': 'approved',
        }, SetOptions(merge: true));

        final notifId = 'notif-upgrade-${DateTime.now().millisecondsSinceEpoch}';
        final notif = {
          'id': notifId,
          'titleSinhala': 'සුබ පැතුම්! ඔබගේ කාණ්ඩය උසස් කරන ලදී 🎖️',
          'titleEnglish': 'Congratulations! Rank Upgraded 🎖️',
          'titleTamil': 'வாழ்த்துக்கள்! தரம் உயர்த்தப்பட்டது 🎖️',
          'messageSinhala': 'ඔබ යොමු කළ සහතිකය සාර්ථකව පරීක්ෂා කර ඔබගේ සේවා මට්ටම "$newTierLabel" දක්වා උසස් කරන ලදී.',
          'messageEnglish': 'Your submitted qualification certificate was approved and your clinical rank has been upgraded to $newTierLabel.',
          'messageTamil': 'உங்கள் சான்றிதழ் அங்கீகரிக்கப்பட்டு தரம் $newTierLabel ஆக உயர்த்தப்பட்டது.',
          'timestamp': DateTime.now().toIso8601String(),
          'category': 'qualification',
          'isRead': false,
        };

        await FirebaseFirestore.instance
            .collection('caregivers')
            .doc(docId)
            .collection('notifications')
            .doc(notifId)
            .set(notif);
      } catch (e) {
        debugPrint('[Firestore] upgradeCaregiverLevel error: $e');
      }
    }
  }

  // Update Caregiver Profile Image from Admin (Crop, PC upload, or replacement)
  Future<void> updateCaregiverProfileImage({
    required String caregiverId,
    required String imageBase64,
    bool autoApprove = true,
  }) async {
    final idx = _caregivers.indexWhere((c) => c.id == caregiverId || c.membershipNumber == caregiverId);
    if (idx != -1) {
      final cg = _caregivers[idx];
      final vMap = Map<String, dynamic>.from(cg.verificationItems);
      final itemData = (vMap['profile_image'] is Map)
          ? Map<String, dynamic>.from(vMap['profile_image'] as Map)
          : <String, dynamic>{};

      final newStatus = autoApprove ? 'approved' : 'pending';
      itemData['status'] = newStatus;
      itemData['title'] = 'Profile Photo';
      itemData['updatedAt'] = DateTime.now().toIso8601String();
      itemData.remove('rejectionReason');
      vMap['profile_image'] = itemData;

      final updated = cg.copyWith(
        profileImageUrl: imageBase64,
        profileImageStatus: newStatus,
        verificationItems: vMap,
      );
      _caregivers[idx] = updated;
      notifyListeners();

      final docId = updated.membershipNumber.isNotEmpty ? updated.membershipNumber : updated.id;
      try {
        await FirebaseFirestore.instance.collection('caregivers').doc(docId).set({
          'profileImageUrl': imageBase64,
          'profileImageStatus': newStatus,
          'verificationItems': _sanitizeVMap(vMap),
        }, SetOptions(merge: true));

        final notifId = 'notif-pimg-${DateTime.now().millisecondsSinceEpoch}';
        final notif = {
          'id': notifId,
          'titleSinhala': 'පැතිකඩ ඡායාරූපය Admin විසින් යාවත්කාලීන කරන ලදී',
          'titleEnglish': 'Profile Photo Updated by Admin',
          'titleTamil': 'சுயவிவரப் படம் நிர்வாகியால் புதுப்பிக்கப்பட்டது',
          'messageSinhala': 'ඔබගේ Profile ඡායාරූපය Admin විසින් සාර්ථකව සකසා අනුමත කරන ලදී.',
          'messageEnglish': 'Your profile photo was adjusted and approved by the management.',
          'messageTamil': 'உங்கள் சுயவிவரப் படம் நிர்வாகியால் சரிபார்க்கப்பட்டது.',
          'timestamp': DateTime.now().toIso8601String(),
          'category': 'qualification',
          'isRead': false,
        };

        await FirebaseFirestore.instance
            .collection('caregivers')
            .doc(docId)
            .collection('notifications')
            .doc(notifId)
            .set(notif);
      } catch (e) {
        debugPrint('[AdminProvider] updateCaregiverProfileImage error: $e');
      }
    }
  }

  // ===================== REAL-TIME BOOKINGS =====================
  List<BookingModel> _bookings = [];
  List<BookingModel> get bookings => _bookings;

  void assignCaregiver(String bookingId, CaregiverModel caregiver) {
    final idx = _bookings.indexWhere((b) => b.id == bookingId || b.bookingCode == bookingId);
    if (idx != -1) {
      final updated = _bookings[idx].copyWith(
        assignedCaregiverId: caregiver.id,
        assignedCaregiverName: caregiver.name,
        assignedCaregiverPhone: caregiver.phone,
        status: 'caregiver_assigned',
      );
      _bookings[idx] = updated;

      // Sync to Firestore cloud
      final docId = updated.id.isNotEmpty ? updated.id : updated.bookingCode;
      try {
        FirebaseFirestore.instance
            .collection('bookings')
            .doc(docId)
            .set(updated.toMap(), SetOptions(merge: true))
            .catchError((e) => debugPrint('[Firestore] assignCaregiver write error: $e'));
      } catch (e) {
        debugPrint('[Firestore] assignCaregiver fallback: $e');
      }

      // Also update caregiver status
      final cgIdx = _caregivers.indexWhere((c) => c.id == caregiver.id);
      if (cgIdx != -1) {
        _caregivers[cgIdx] = _caregivers[cgIdx].copyWith(
          status: 'on_duty',
          activeAssignedPatient: '${_bookings[idx].patientName} (${_bookings[idx].city})',
        );
      }
      notifyListeners();
    }
  }

  void markBookingInProcess(String bookingId) {
    final idx = _bookings.indexWhere((b) => b.id == bookingId || b.bookingCode == bookingId);
    if (idx != -1) {
      final bk = _bookings[idx];
      final updated = bk.copyWith(status: 'in_process');
      _bookings[idx] = updated;

      final docId = updated.id.isNotEmpty ? updated.id : updated.bookingCode;
      try {
        FirebaseFirestore.instance
            .collection('bookings')
            .doc(docId)
            .set({
              'status': 'in_process',
              'inProcessAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true))
            .catchError((e) => debugPrint('[Firestore] markBookingInProcess error: $e'));
      } catch (e) {
        debugPrint('[Firestore] markBookingInProcess fallback: $e');
      }
      notifyListeners();
    }
  }

  void broadcastBookingToStaff(String bookingId, {String? targetTier, double? customStaffDailyPayout}) {
    final idx = _bookings.indexWhere((b) => b.id == bookingId || b.bookingCode == bookingId);
    if (idx != -1) {
      final bk = _bookings[idx];
      final raw = (targetTier ?? bk.targetTier ?? bk.staffTierName).toLowerCase();
      final name = bk.staffTierName.toLowerCase();
      final isNurse = raw.contains('5') || raw.contains('nurse') || raw.contains('nurs') || name.contains('5') || name.contains('nurse') || name.contains('nurs') || name.contains('clinical');
      final tier = isNurse ? 'nvq5_nurse' : 'nvq4_aide';

      // Look up staff payout rate from service tier if configured
      double staffDailyRate = customStaffDailyPayout ?? bk.staffDailyPayoutLKR;
      for (final s in _services) {
        for (final t in s.tiers) {
          if (t.tierId == bk.targetTier || t.tierName.toLowerCase() == bk.staffTierName.toLowerCase()) {
            if (t.staffPayoutRateLKR > 0) {
              staffDailyRate = t.staffPayoutRateLKR;
              break;
            }
          }
        }
      }
      if (staffDailyRate <= 0) {
        staffDailyRate = bk.pricePerDayLKR * 0.80;
      }
      final staffTotalPayout = staffDailyRate * bk.durationDays;

      final updated = bk.copyWith(
        status: 'broadcasted',
        targetTier: tier,
        staffDailyPayoutLKR: staffDailyRate,
        staffTotalPayoutLKR: staffTotalPayout,
        candidateQueue: [],
        acceptedCandidateCount: 0,
        maxCandidates: 10,
      );
      _bookings[idx] = updated;

      final docId = updated.id.isNotEmpty ? updated.id : updated.bookingCode;
      try {
        FirebaseFirestore.instance
            .collection('bookings')
            .doc(docId)
            .set({
              'status': 'broadcasted',
              'targetTier': tier,
              'requiredTier': tier,
              'staffTierId': tier,
              'staffDailyRateLKR': staffDailyRate,
              'staffDailyPayoutLKR': staffDailyRate,
              'staffTotalEarningsLKR': staffTotalPayout,
              'staffTotalPayoutLKR': staffTotalPayout,
              'candidateQueue': [],
              'acceptedCandidateCount': 0,
              'maxCandidates': 10,
              'broadcastedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true))
            .catchError((e) => debugPrint('[Firestore] broadcastBookingToStaff error: $e'));
      } catch (e) {
        debugPrint('[Firestore] broadcastBookingToStaff fallback: $e');
      }
      notifyListeners();
    }
  }

  void assignFromCandidateQueue(String bookingId, Map<String, dynamic> candidate) {
    final idx = _bookings.indexWhere((b) => b.id == bookingId || b.bookingCode == bookingId);
    if (idx != -1) {
      final cgId = candidate['caregiverId']?.toString() ?? '';
      final cgName = candidate['caregiverName']?.toString() ?? '';
      final cgPhone = candidate['caregiverPhone']?.toString() ?? '';

      final updated = _bookings[idx].copyWith(
        assignedCaregiverId: cgId,
        assignedCaregiverName: cgName,
        assignedCaregiverPhone: cgPhone,
        status: 'caregiver_assigned',
      );
      _bookings[idx] = updated;

      final docId = updated.id.isNotEmpty ? updated.id : updated.bookingCode;
      try {
        FirebaseFirestore.instance
            .collection('bookings')
            .doc(docId)
            .set({
              'assignedCaregiverId': cgId,
              'assignedCaregiverName': cgName,
              'assignedCaregiverPhone': cgPhone,
              'status': 'caregiver_assigned',
              'assignedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true))
            .catchError((e) => debugPrint('[Firestore] assignFromCandidateQueue error: $e'));
      } catch (e) {
        debugPrint('[Firestore] assignFromCandidateQueue fallback: $e');
      }

      // Update Caregiver doc status to on_duty
      if (cgId.isNotEmpty) {
        try {
          FirebaseFirestore.instance
              .collection('caregivers')
              .doc(cgId)
              .set({
                'status': 'on_duty',
                'activeAssignedPatient': '${_bookings[idx].patientName} (${_bookings[idx].city})',
                'activeBookingId': docId,
              }, SetOptions(merge: true))
              .catchError((e) => debugPrint('[Firestore] caregiver status on_duty error: $e'));
        } catch (_) {}

        final cgIdx = _caregivers.indexWhere((c) => c.id == cgId);
        if (cgIdx != -1) {
          _caregivers[cgIdx] = _caregivers[cgIdx].copyWith(
            status: 'on_duty',
            activeAssignedPatient: '${_bookings[idx].patientName} (${_bookings[idx].city})',
          );
        }
      }
      notifyListeners();
    }
  }

  void unassignCaregiver(String bookingId) {
    final idx = _bookings.indexWhere((b) => b.id == bookingId || b.bookingCode == bookingId);
    if (idx != -1) {
      final oldCgId = _bookings[idx].assignedCaregiverId;
      final updated = _bookings[idx].copyWith(
        assignedCaregiverId: null,
        assignedCaregiverName: null,
        assignedCaregiverPhone: null,
        status: 'pending_review',
      );
      _bookings[idx] = updated;

      final docId = updated.id.isNotEmpty ? updated.id : updated.bookingCode;
      try {
        FirebaseFirestore.instance
            .collection('bookings')
            .doc(docId)
            .set({
              'assignedCaregiverId': null,
              'assignedCaregiverName': null,
              'assignedCaregiverPhone': null,
              'status': 'pending_review',
            }, SetOptions(merge: true))
            .catchError((e) => debugPrint('[Firestore] unassignCaregiver write error: $e'));
      } catch (e) {
        debugPrint('[Firestore] unassignCaregiver fallback: $e');
      }

      if (oldCgId != null) {
        final cgIdx = _caregivers.indexWhere((c) => c.id == oldCgId);
        if (cgIdx != -1) {
          _caregivers[cgIdx] = _caregivers[cgIdx].copyWith(
            status: 'available',
            activeAssignedPatient: null,
          );
        }
      }
      notifyListeners();
    }
  }

  void updateBookingStatus(String bookingId, String newStatus) {
    final idx = _bookings.indexWhere((b) => b.id == bookingId || b.bookingCode == bookingId);
    if (idx != -1) {
      final updated = _bookings[idx].copyWith(status: newStatus);
      _bookings[idx] = updated;

      // Sync to Firestore cloud
      final docId = updated.id.isNotEmpty ? updated.id : updated.bookingCode;
      try {
        FirebaseFirestore.instance
            .collection('bookings')
            .doc(docId)
            .set({'status': newStatus}, SetOptions(merge: true))
            .catchError((e) => debugPrint('[Firestore] updateBookingStatus write error: $e'));
      } catch (e) {
        debugPrint('[Firestore] updateBookingStatus fallback: $e');
      }

      notifyListeners();
    }
  }

  void updateBookingPaymentStatus(String bookingId, String newStatus) {
    final idx = _bookings.indexWhere((b) => b.id == bookingId || b.bookingCode == bookingId);
    if (idx != -1) {
      final updated = _bookings[idx].copyWith(paymentStatus: newStatus);
      _bookings[idx] = updated;

      // Sync to Firestore cloud
      final docId = updated.id.isNotEmpty ? updated.id : updated.bookingCode;
      try {
        FirebaseFirestore.instance
            .collection('bookings')
            .doc(docId)
            .set({'paymentStatus': newStatus}, SetOptions(merge: true))
            .catchError((e) => debugPrint('[Firestore] updateBookingPaymentStatus write error: $e'));
      } catch (e) {
        debugPrint('[Firestore] updateBookingPaymentStatus fallback: $e');
      }

      notifyListeners();
    }
  }

  void extendBookingDuration(String bookingId, int additionalDays) {
    final idx = _bookings.indexWhere((b) => b.id == bookingId || b.bookingCode == bookingId);
    if (idx != -1 && additionalDays > 0) {
      final current = _bookings[idx];
      final newDuration = current.durationDays + additionalDays;
      final newTotalCost = current.pricePerDayLKR * newDuration;
      final newStaffPayout = current.staffDailyPayoutLKR * newDuration;

      final updated = current.copyWith(
        durationDays: newDuration,
        totalCostLKR: newTotalCost,
        staffTotalPayoutLKR: newStaffPayout,
      );
      _bookings[idx] = updated;

      final docId = updated.id.isNotEmpty ? updated.id : updated.bookingCode;
      try {
        FirebaseFirestore.instance
            .collection('bookings')
            .doc(docId)
            .set({
              'durationDays': newDuration,
              'totalCostLKR': newTotalCost,
              'staffTotalEarningsLKR': newStaffPayout,
              'staffTotalPayoutLKR': newStaffPayout,
            }, SetOptions(merge: true))
            .catchError((e) => debugPrint('[Firestore] extendBookingDuration write error: $e'));
      } catch (e) {
        debugPrint('[Firestore] extendBookingDuration fallback: $e');
      }

      notifyListeners();
    }
  }

  void earlyDischargeBooking(String bookingId, {required int workedDays, String reason = 'Family requested early discharge'}) {
    final idx = _bookings.indexWhere((b) => b.id == bookingId || b.bookingCode == bookingId);
    if (idx != -1) {
      final current = _bookings[idx];
      final actualDays = workedDays.clamp(0, current.durationDays);
      final settledCustomerCost = actualDays * current.pricePerDayLKR;
      final customerRefund = (current.durationDays - actualDays) * current.pricePerDayLKR;
      final settledStaffPayout = actualDays * current.staffDailyPayoutLKR;
      final dischargeNote = 'Early discharged after $actualDays/${current.durationDays} days. Reason: $reason. Pro-rata staff payout: LKR $settledStaffPayout. Refund: LKR $customerRefund.';

      final updated = current.copyWith(
        status: 'completed',
        durationDays: actualDays,
        totalCostLKR: settledCustomerCost,
        staffTotalPayoutLKR: settledStaffPayout,
        earlyDischargeNote: dischargeNote,
      );
      _bookings[idx] = updated;

      // Free assigned caregiver back to available
      if (current.assignedCaregiverId != null && current.assignedCaregiverId!.isNotEmpty) {
        final cgIdx = _caregivers.indexWhere((c) => c.id == current.assignedCaregiverId);
        if (cgIdx != -1) {
          _caregivers[cgIdx] = _caregivers[cgIdx].copyWith(status: 'available');
        }
      }

      final docId = updated.id.isNotEmpty ? updated.id : updated.bookingCode;
      try {
        final batch = FirebaseFirestore.instance.batch();
        final bookingRef = FirebaseFirestore.instance.collection('bookings').doc(docId);
        batch.set(bookingRef, {
          'status': 'completed',
          'durationDays': actualDays,
          'totalCostLKR': settledCustomerCost,
          'staffTotalEarningsLKR': settledStaffPayout,
          'staffTotalPayoutLKR': settledStaffPayout,
          'earlyDischargeNote': dischargeNote,
          'dischargedAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));

        if (current.assignedCaregiverId != null && current.assignedCaregiverId!.isNotEmpty) {
          final caregiverRef = FirebaseFirestore.instance.collection('caregivers').doc(current.assignedCaregiverId!);
          batch.set(caregiverRef, {'status': 'available', 'currentBookingId': null}, SetOptions(merge: true));
        }

        batch.commit().catchError((e) => debugPrint('[Firestore] earlyDischarge batch error: $e'));
      } catch (e) {
        debugPrint('[Firestore] earlyDischarge fallback: $e');
      }

      notifyListeners();
    }
  }

  void updateCareAndVitalsPlan(String bookingId, {Map<String, dynamic>? vitalsPlan, List<String>? carePlanTasks}) {
    final idx = _bookings.indexWhere((b) => b.id == bookingId || b.bookingCode == bookingId);
    if (idx != -1) {
      final updated = _bookings[idx].copyWith(
        vitalsPlan: vitalsPlan ?? _bookings[idx].vitalsPlan,
        carePlanTasks: carePlanTasks ?? _bookings[idx].carePlanTasks,
      );
      _bookings[idx] = updated;

      final docId = updated.id.isNotEmpty ? updated.id : updated.bookingCode;
      try {
        final payload = <String, dynamic>{};
        if (vitalsPlan != null) payload['vitalsPlan'] = vitalsPlan;
        if (carePlanTasks != null) payload['carePlanTasks'] = carePlanTasks;

        FirebaseFirestore.instance
            .collection('bookings')
            .doc(docId)
            .set(payload, SetOptions(merge: true))
            .catchError((e) => debugPrint('[Firestore] updateCareAndVitalsPlan error: $e'));
      } catch (e) {
        debugPrint('[Firestore] updateCareAndVitalsPlan fallback: $e');
      }

      notifyListeners();
    }
  }

  void deleteBooking(String bookingId) {
    final idx = _bookings.indexWhere((b) => b.id == bookingId || b.bookingCode == bookingId);
    if (idx != -1) {
      final b = _bookings[idx];
      final docId = b.id.isNotEmpty ? b.id : b.bookingCode;
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(days: 7));

      final archiveData = b.toMap();
      archiveData['id'] = docId;
      archiveData['originalDocId'] = docId;
      archiveData['deletedAt'] = now.toIso8601String();
      archiveData['expiresAt'] = expiresAt.toIso8601String();
      archiveData['deletedBy'] = 'Operations Admin';

      _bookings.removeAt(idx);
      notifyListeners();

      try {
        final firestore = FirebaseFirestore.instance;
        // 1. Save to deleted_bookings archive (7-day retention)
        firestore
            .collection('deleted_bookings')
            .doc(docId)
            .set(archiveData, SetOptions(merge: true))
            .catchError((e) => debugPrint('[Firestore] archive error: $e'));

        // 2. Remove from active bookings
        firestore
            .collection('bookings')
            .doc(docId)
            .delete()
            .catchError((e) => debugPrint('[Firestore] deleteBooking error: $e'));
      } catch (e) {
        debugPrint('[Firestore] deleteBooking fallback: $e');
      }
    }
  }

  void restoreBooking(String bookingId) {
    final idx = _deletedBookings.indexWhere((d) => d['id'] == bookingId || d['bookingCode'] == bookingId);
    if (idx != -1) {
      final data = Map<String, dynamic>.from(_deletedBookings[idx]);
      final docId = (data['originalDocId'] ?? data['id'] ?? data['bookingCode']).toString();

      // Clean archive metadata before restoring
      data.remove('deletedAt');
      data.remove('expiresAt');
      data.remove('deletedBy');
      data.remove('originalDocId');

      _deletedBookings.removeAt(idx);
      notifyListeners();

      try {
        final firestore = FirebaseFirestore.instance;
        // 1. Put back to active bookings
        firestore
            .collection('bookings')
            .doc(docId)
            .set(data, SetOptions(merge: true))
            .catchError((e) => debugPrint('[Firestore] restore error: $e'));

        // 2. Remove from deleted_bookings
        firestore
            .collection('deleted_bookings')
            .doc(docId)
            .delete()
            .catchError((e) => debugPrint('[Firestore] delete archive error: $e'));
      } catch (e) {
        debugPrint('[Firestore] restoreBooking fallback: $e');
      }
    }
  }

  void purgeBookingPermanently(String bookingId) {
    _deletedBookings.removeWhere((d) => d['id'] == bookingId || d['bookingCode'] == bookingId);
    notifyListeners();

    try {
      FirebaseFirestore.instance
          .collection('deleted_bookings')
          .doc(bookingId)
          .delete()
          .catchError((e) => debugPrint('[Firestore] purge error: $e'));
    } catch (e) {
      debugPrint('[Firestore] purge fallback: $e');
    }
  }

  // ===================== REGISTERED USERS =====================
  List<UserModel> _users = [];
  List<UserModel> get users => _users;

  // ===================== TRAFFIC STATS =====================
  int _totalWebsiteVisitors = 0;
  int get totalWebsiteVisitors => _totalWebsiteVisitors;

  int _todayWebsiteVisitors = 0;
  int get todayWebsiteVisitors => _todayWebsiteVisitors;

  // ===================== CARE SERVICES & STAFF TIERS =====================
  List<ServiceModel> _services = _getDefaultServicesList();

  List<ServiceModel> get services => _services;

  DateTime? _lastServicesPublishedAt;
  DateTime? get lastServicesPublishedAt => _lastServicesPublishedAt;

  bool _isPublishingServices = false;
  bool get isPublishingServices => _isPublishingServices;

  Future<bool> publishAllServicesToFirestore() async {
    _isPublishingServices = true;
    notifyListeners();

    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      for (final s in _services) {
        final docRef = firestore.collection('services').doc(s.id);
        batch.set(docRef, s.toMap(), SetOptions(merge: true));
      }
      await batch.commit();
      _lastServicesPublishedAt = DateTime.now();
      _isPublishingServices = false;
      notifyListeners();
      debugPrint('[AdminProvider] Successfully published all ${_services.length} services to Firestore & Web!');
      return true;
    } catch (e) {
      _isPublishingServices = false;
      notifyListeners();
      debugPrint('[AdminProvider] publishAllServicesToFirestore error: $e');
      return false;
    }
  }

  static List<ServiceModel> _getDefaultServicesList() {
    return [
      ServiceModel(
        id: 'day_care_12h',
        nameEn: '12-Hour Day Shift Care',
        nameSi: 'පැය 12 දිවා සාත්තු සේවය',
        category: 'elderly_care',
        hours: 12,
        shiftType: '12h_day',
        defaultPriceLKR: 4500,
        pricingUnit: '/ day',
        shortDescription: '07:00 AM - 07:00 PM dedicated daytime care for bedridden or elderly needing daily assistance.',
        shortDescriptionSi: 'උදෑසන 7 සිට සවස 7 දක්වා ඇඳ විවේකයේ සිටින හෝ දෛනික කටයුතුවලට සහාය අවශ්‍ය වැඩිහිටියන් සඳහා.',
        icon: 'Sun',
        sortOrder: 1,
        tiers: [
          TierPricing(
            tierId: 'basic_aide',
            tierName: 'Basic Companion Aide',
            tierNameSi: 'මූලික සහායක',
            badge: 'Affordable Companion',
            priceLKR: 3000,
            pricingUnit: '/ day',
            duties: [
              'Conversation & companionship',
              'Assisted sponge bathing',
              'Routine meal prep',
              'Feeding & medication reminding',
              'Garden short walk',
              'Wheelchair transfer',
            ],
          ),
          TierPricing(
            tierId: 'nurse_assistant',
            tierName: 'Nurse Assistant',
            tierNameSi: 'හෙද සහායක',
            badge: 'Nurse Aide Trained',
            priceLKR: 3800,
            pricingUnit: '/ day',
            duties: [
              'Conversation & companionship',
              'Assisted sponge bathing',
              'Routine meal prep',
              'Feeding & medication reminding',
              'Garden short walk',
              'Wheelchair transfer',
            ],
          ),
          TierPricing(
            tierId: 'nvq_4_caregiver',
            tierName: 'NVQ 4 Certified Caregiver',
            tierNameSi: 'NVQ 4 පුහුණු සාත්තු',
            badge: 'Most Popular ⭐',
            isRecommended: true,
            priceLKR: 4500,
            pricingUnit: '/ day',
            duties: [
              'Bed turning every 2h',
              'Aseptic surgical dressings',
              'BP & Sugar vitals log',
              'Catheter & Ryles tube',
              'Dementia patient calming',
              'IV medication',
            ],
          ),
          TierPricing(
            tierId: 'nvq_5_nurse',
            tierName: 'NVQ 5 Senior Clinical Nurse',
            tierNameSi: 'NVQ 5 ජ්‍යෙෂ්ඨ හෙද',
            badge: 'Diploma Clinical',
            priceLKR: 5800,
            pricingUnit: '/ day',
            duties: [
              'Bed turning every 2h',
              'Aseptic surgical dressings',
              'BP & Sugar vitals log',
              'Catheter & Ryles tube',
              'Dementia patient calming',
              'IV medication',
            ],
          ),
        ],
      ),
      ServiceModel(
        id: 'night_care_12h',
        nameEn: '12-Hour Night Shift Care',
        nameSi: 'පැය 12 රාත්‍රී සාත්තු සේවය',
        category: 'elderly_care',
        hours: 12,
        shiftType: '12h_night',
        defaultPriceLKR: 5000,
        pricingUnit: '/ night',
        shortDescription: '07:00 PM - 07:00 AM vigilant nighttime assistance ensuring safety, comfort, and peaceful sleep.',
        shortDescriptionSi: 'සවස 7 සිට උදෑසන 7 දක්වා රාත්‍රී නින්ද, වැසිකිලි යාම සහ හදිසි ආරක්ෂාව තහවුරු කරන සත්කාරය.',
        icon: 'Moon',
        sortOrder: 2,
        tiers: [
          TierPricing(
            tierId: 'basic_aide',
            tierName: 'Basic Night Aide',
            tierNameSi: 'මූලික රාත්‍රී සහායක',
            badge: 'Night Companion',
            priceLKR: 3500,
            pricingUnit: '/ night',
            duties: [
              'Nighttime bathroom assistance',
              'Overnight vital signs',
              'Hydration & comfort',
              'Emergency notification',
            ],
          ),
          TierPricing(
            tierId: 'nurse_assistant',
            tierName: 'Nurse Assistant',
            tierNameSi: 'හෙද සහායක',
            badge: 'Nurse Aide Trained',
            priceLKR: 4200,
            pricingUnit: '/ night',
            duties: [
              'Nighttime bathroom assistance',
              'Overnight vital signs',
              'Hydration & comfort',
              'Emergency notification',
            ],
          ),
          TierPricing(
            tierId: 'nvq_4_caregiver',
            tierName: 'NVQ 4 Certified ⭐',
            tierNameSi: 'NVQ 4 පුහුණු සාත්තු',
            badge: 'Recommended ⭐',
            isRecommended: true,
            priceLKR: 5000,
            pricingUnit: '/ night',
            duties: [
              'Bed turning every 2 hours',
              'Ventilator/tracheostomy care',
              'Calming disoriented wandering',
              'Oxygen titration',
            ],
          ),
          TierPricing(
            tierId: 'nvq_5_nurse',
            tierName: 'NVQ 5 Senior Nurse',
            tierNameSi: 'NVQ 5 ජ්‍යෙෂ්ඨ හෙද',
            badge: 'Critical Overnight',
            priceLKR: 6200,
            pricingUnit: '/ night',
            duties: [
              'Bed turning every 2 hours',
              'Ventilator/tracheostomy care',
              'Calming disoriented wandering',
              'Oxygen titration',
            ],
          ),
        ],
      ),
      ServiceModel(
        id: 'live_in_24h',
        nameEn: '24-Hour Full Live-In Care',
        nameSi: 'පැය 24 පූර්ණ නේවාසික සාත්තු සේවය',
        category: 'elderly_care',
        hours: 24,
        shiftType: '24h_full',
        defaultPriceLKR: 7500,
        pricingUnit: '/ day',
        shortDescription: 'Round-the-clock live-in caregiver providing constant care, comfort, and emergency readiness.',
        shortDescriptionSi: 'නිවසේම නේවාසිකව රැඳී සිටින පුහුණු සාත්තු සේවකයෙකුගේ පැය 24 පුරාම සත්කාරය.',
        icon: 'Home',
        sortOrder: 3,
        tiers: [
          TierPricing(
            tierId: 'basic_aide',
            tierName: 'Live-In Companion',
            tierNameSi: 'නේවාසික සහායක',
            badge: 'Budget Live-in',
            priceLKR: 5500,
            pricingUnit: '/ day',
            duties: [
              'Light cooking, companionship',
              'Bathing, feeding, movement',
              'Room tidying',
              'Medication routine',
            ],
          ),
          TierPricing(
            tierId: 'nurse_assistant',
            tierName: 'Live-in Nurse Aide',
            tierNameSi: 'පුහුණු හෙද සහායක',
            badge: 'Trained Live-in',
            priceLKR: 6500,
            pricingUnit: '/ day',
            duties: [
              'Light cooking, companionship',
              'Bathing, feeding, movement',
              'Room tidying',
              'Medication routine',
            ],
          ),
          TierPricing(
            tierId: 'nvq_4_caregiver',
            tierName: 'NVQ 4 Live-in ⭐',
            tierNameSi: 'NVQ 4 නේවාසික සාත්තු',
            badge: 'Top Choice ⭐',
            isRecommended: true,
            priceLKR: 7500,
            pricingUnit: '/ day',
            duties: [
              'Total bedridden elder care',
              'Complex medical cases',
              'Daily vitals logbook',
              'Specialist doctor liaison',
            ],
          ),
          TierPricing(
            tierId: 'nvq_5_nurse',
            tierName: 'NVQ 5 Live-in Nurse',
            tierNameSi: 'NVQ 5 නේවාසික හෙද',
            badge: 'Intensive Clinical',
            priceLKR: 9500,
            pricingUnit: '/ day',
            duties: [
              'Total bedridden elder care',
              'Complex medical cases',
              'Daily vitals logbook',
              'Specialist doctor liaison',
            ],
          ),
        ],
      ),
      ServiceModel(
        id: 'postnatal_care',
        nameEn: 'Newborn & Mother Post-Natal Care',
        nameSi: 'මාතෘ සහ අලුත උපන් බිළිඳු සත්කාරය',
        category: 'child_care',
        hours: 12,
        shiftType: '12h_day',
        defaultPriceLKR: 4800,
        pricingUnit: '/ day',
        shortDescription: 'Dedicated postpartum assistance: umbilical cord care, lactation guidance, colic soothing.',
        shortDescriptionSi: 'අලුත උපන් බිළිඳාගේ පෙකණි වැල රැකවරණය, ස්නානය, නිසි නින්ද සහ මවගේ සුවය තහවුරු කරන විශ්වාසනීය සාත්තු සේවය.',
        icon: 'Baby',
        sortOrder: 4,
        tiers: [
          TierPricing(
            tierId: 'basic_aide',
            tierName: 'Infant Care Aide',
            tierNameSi: 'බිළිඳු සහායිකා',
            badge: 'Family Aide',
            priceLKR: 3500,
            pricingUnit: '/ day',
            duties: [
              'Bottle sterilizing',
              'Umbilical cord antiseptic care',
              'Gentle infant sponge bath',
              'Colic burping protocol',
              'Lactation guidance',
            ],
          ),
          TierPricing(
            tierId: 'nvq_4_caregiver',
            tierName: 'Maternity Nurse NVQ 4 ⭐',
            tierNameSi: 'පුහුණු මාතෘ හෙද',
            badge: 'Most Recommended ⭐',
            isRecommended: true,
            priceLKR: 4800,
            pricingUnit: '/ day',
            duties: [
              'Bottle sterilizing',
              'Umbilical cord antiseptic care',
              'Gentle infant sponge bath',
              'Colic burping protocol',
              'Lactation guidance',
            ],
          ),
          TierPricing(
            tierId: 'nvq_5_nurse',
            tierName: 'NICU Trained Specialist Nurse',
            tierNameSi: 'ළමා රෝග විශේෂඥ හෙද',
            badge: 'NICU Specialist',
            priceLKR: 6500,
            pricingUnit: '/ day',
            duties: [
              'Premature infant monitoring',
              'Phototherapy oversight',
            ],
          ),
        ],
      ),
      ServiceModel(
        id: 'doctor_visit',
        nameEn: 'Doctor Home Visit & Clinical Assessment',
        nameSi: 'වෛද්‍ය නිවාස පරීක්ෂණ (MBBS වෛද්‍යවරයා)',
        category: 'short_visit',
        hours: 2,
        shiftType: 'short_visit',
        defaultPriceLKR: 5500,
        pricingUnit: '/ visit',
        shortDescription: 'SLMC-registered MBBS physician visiting patient at home for clinical checkup, prescriptions, and health review.',
        shortDescriptionSi: 'ශ්‍රී ලංකා වෛද්‍ය සභාවේ (SLMC) ලියාපදිංචි MBBS වෛද්‍යවරයෙකු නිවසටම පැමිණ සිදුකරන සම්පූර්ණ පරීක්ෂාව.',
        icon: 'HeartPulse',
        sortOrder: 5,
        tiers: [
          TierPricing(
            tierId: 'doctor',
            tierName: 'SLMC Registered MBBS Medical Officer',
            tierNameSi: 'SLMC ලියාපදිංචි MBBS වෛද්‍යවරයා',
            badge: 'Certified Physician ⭐',
            isRecommended: true,
            priceLKR: 5500,
            pricingUnit: '/ visit',
            duties: [
              'Comprehensive clinical exam',
              'Prescription writing',
              'Hospital referral if needed',
              'ECG review',
            ],
          ),
        ],
      ),
    ];
  }

  Future<void> _seedDefaultServicesToFirestore() async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final s in _getDefaultServicesList()) {
        final docRef = FirebaseFirestore.instance.collection('services').doc(s.id);
        batch.set(docRef, s.toMap(), SetOptions(merge: true));
      }
      await batch.commit();
      debugPrint('[AdminProvider] Seeded default services to Firestore');
    } catch (e) {
      debugPrint('[AdminProvider] Seed default services warning: $e');
    }
  }

  Future<void> addService(ServiceModel service) async {
    final idx = _services.indexWhere((s) => s.id == service.id);
    if (idx != -1) {
      _services[idx] = service;
    } else {
      _services.add(service);
    }
    notifyListeners();

    try {
      await FirebaseFirestore.instance
          .collection('services')
          .doc(service.id)
          .set(service.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('[AdminProvider] addService firestore error: $e');
    }
  }

  Future<void> updateService(ServiceModel service) async {
    final idx = _services.indexWhere((s) => s.id == service.id);
    if (idx != -1) {
      _services[idx] = service;
      notifyListeners();
    }
    try {
      await FirebaseFirestore.instance
          .collection('services')
          .doc(service.id)
          .set(service.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('[AdminProvider] updateService firestore error: $e');
    }
  }

  Future<void> deleteService(String serviceId) async {
    _services.removeWhere((s) => s.id == serviceId);
    notifyListeners();
    try {
      await FirebaseFirestore.instance
          .collection('services')
          .doc(serviceId)
          .delete();
    } catch (e) {
      debugPrint('[AdminProvider] deleteService firestore error: $e');
    }
  }

  Future<void> toggleServiceActive(String serviceId, bool isActive) async {
    final idx = _services.indexWhere((s) => s.id == serviceId);
    if (idx != -1) {
      _services[idx] = _services[idx].copyWith(isActive: isActive);
      notifyListeners();
      try {
        await FirebaseFirestore.instance
            .collection('services')
            .doc(serviceId)
            .update({'isActive': isActive});
      } catch (e) {
        debugPrint('[AdminProvider] toggleServiceActive error: $e');
      }
    }
  }

  Future<void> updateServicePrice(String serviceId, String tierId, double newPrice) async {
    final svcIdx = _services.indexWhere((s) => s.id == serviceId);
    if (svcIdx != -1) {
      final tierIdx = _services[svcIdx].tiers.indexWhere((t) => t.tierId == tierId);
      if (tierIdx != -1) {
        final updatedTiers = List<TierPricing>.from(_services[svcIdx].tiers);
        updatedTiers[tierIdx] = updatedTiers[tierIdx].copyWith(priceLKR: newPrice);
        final updatedService = _services[svcIdx].copyWith(tiers: updatedTiers);
        await updateService(updatedService);
      }
    }
  }

  Future<void> saveTier({
    required String serviceId,
    required TierPricing tier,
    bool isNew = false,
  }) async {
    final svcIdx = _services.indexWhere((s) => s.id == serviceId);
    if (svcIdx != -1) {
      final updatedTiers = List<TierPricing>.from(_services[svcIdx].tiers);
      if (isNew) {
        updatedTiers.add(tier);
      } else {
        final tIdx = updatedTiers.indexWhere((t) => t.tierId == tier.tierId);
        if (tIdx != -1) {
          updatedTiers[tIdx] = tier;
        } else {
          updatedTiers.add(tier);
        }
      }
      final updatedService = _services[svcIdx].copyWith(tiers: updatedTiers);
      await updateService(updatedService);
    }
  }

  Future<void> deleteTier({
    required String serviceId,
    required String tierId,
  }) async {
    final svcIdx = _services.indexWhere((s) => s.id == serviceId);
    if (svcIdx != -1) {
      final updatedTiers = List<TierPricing>.from(_services[svcIdx].tiers)
        ..removeWhere((t) => t.tierId == tierId);
      final updatedService = _services[svcIdx].copyWith(tiers: updatedTiers);
      await updateService(updatedService);
    }
  }

  // ===================== STORE INVENTORY =====================
  final List<MedicalItemModel> _medicalItems = [
    MedicalItemModel(
      id: 'med_01',
      nameEn: 'Electric 3-Function Hospital Bed',
      nameSi: 'Electric 3-Function Hospital Bed',
      category: 'equipment',
      buyPriceLKR: 185000,
      canRent: true,
      monthlyRentLKR: 14000,
      securityDepositLKR: 20000,
      stock: 5,
      imageUrls: ['https://images.unsplash.com/photo-1584515979956-d9f6e5d09982?auto=format&fit=crop&q=80&w=800'],
      description: 'Fully motorized electric home hospital bed with remote control, mattress, and side rails.',
    ),
    MedicalItemModel(
      id: 'med_02',
      nameEn: 'Philips EverFlo 5L Oxygen Concentrator',
      nameSi: 'Philips EverFlo 5L Oxygen Concentrator',
      category: 'equipment',
      buyPriceLKR: 245000,
      canRent: true,
      monthlyRentLKR: 22000,
      securityDepositLKR: 30000,
      stock: 3,
      imageUrls: ['https://images.unsplash.com/photo-1631815588090-d4bfec5b1ccb?auto=format&fit=crop&q=80&w=800'],
      description: 'Continuous medical oxygen delivery unit for respiratory patients.',
    ),
    MedicalItemModel(
      id: 'med_03',
      nameEn: 'Foldable Lightweight Wheelchair',
      nameSi: 'Foldable Lightweight Wheelchair',
      category: 'mobility',
      buyPriceLKR: 42000,
      canRent: true,
      monthlyRentLKR: 6500,
      securityDepositLKR: 10000,
      stock: 8,
      imageUrls: ['https://images.unsplash.com/photo-1576765608535-5f04d1e3f289?auto=format&fit=crop&q=80&w=800'],
      description: 'Durable chrome-plated foldable transit wheelchair with safety brakes and footrests.',
    ),
    MedicalItemModel(
      id: 'med_04',
      nameEn: 'Adult Diapers Care Pack (Pack of 10 - Large)',
      nameSi: 'Adult Diapers Care Pack (Pack of 10 - Large)',
      category: 'hygiene',
      buyPriceLKR: 2850,
      canRent: false,
      stock: 35,
      imageUrls: ['https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&q=80&w=800'],
      description: 'High-absorbency leakage-proof adult care diapers with wetness indicator.',
    ),
  ];

  List<MedicalItemModel> get medicalItems => _medicalItems;

  void addMedicalItem(MedicalItemModel item) {
    _medicalItems.add(item);
    notifyListeners();
  }

  void updateMedicalItem(MedicalItemModel item) {
    final idx = _medicalItems.indexWhere((m) => m.id == item.id);
    if (idx != -1) {
      _medicalItems[idx] = item;
      notifyListeners();
    }
  }

  void deleteMedicalItem(String itemId) {
    _medicalItems.removeWhere((m) => m.id == itemId);
    notifyListeners();
  }

  void updateItemStock(String itemId, int newStock) {
    final idx = _medicalItems.indexWhere((m) => m.id == itemId);
    if (idx != -1) {
      _medicalItems[idx] = _medicalItems[idx].copyWith(stock: newStock);
      notifyListeners();
    }
  }

  // ===================== REAL-TIME ORDERS & RENTALS =====================
  List<OrderModel> _orders = [];
  List<OrderModel> get orders => _orders;

  void approveBankTransfer(String orderId) {
    final idx = _orders.indexWhere((o) => o.id == orderId || o.orderCode == orderId);
    if (idx != -1) {
      final updated = _orders[idx].copyWith(
        paymentStatus: 'paid',
        orderStatus: 'dispatched',
      );
      _orders[idx] = updated;

      final docId = updated.id.isNotEmpty ? updated.id : updated.orderCode;
      try {
        FirebaseFirestore.instance
            .collection('orders')
            .doc(docId)
            .set({'paymentStatus': 'paid', 'orderStatus': 'dispatched'}, SetOptions(merge: true))
            .catchError((e) => debugPrint('[Firestore] approveBankTransfer error: $e'));
      } catch (e) {
        debugPrint('[Firestore] approveBankTransfer fallback: $e');
      }
      notifyListeners();
    }
  }

  void updateOrderStatus(String orderId, String newStatus) {
    final idx = _orders.indexWhere((o) => o.id == orderId || o.orderCode == orderId);
    if (idx != -1) {
      final updated = _orders[idx].copyWith(orderStatus: newStatus);
      _orders[idx] = updated;

      final docId = updated.id.isNotEmpty ? updated.id : updated.orderCode;
      try {
        FirebaseFirestore.instance
            .collection('orders')
            .doc(docId)
            .set({'orderStatus': newStatus}, SetOptions(merge: true))
            .catchError((e) => debugPrint('[Firestore] updateOrderStatus error: $e'));
      } catch (e) {
        debugPrint('[Firestore] updateOrderStatus fallback: $e');
      }

      notifyListeners();
    }
  }

  void updateOrderPaymentStatus(String orderId, String newStatus) {
    final idx = _orders.indexWhere((o) => o.id == orderId || o.orderCode == orderId);
    if (idx != -1) {
      final updated = _orders[idx].copyWith(paymentStatus: newStatus);
      _orders[idx] = updated;

      final docId = updated.id.isNotEmpty ? updated.id : updated.orderCode;
      try {
        FirebaseFirestore.instance
            .collection('orders')
            .doc(docId)
            .set({'paymentStatus': newStatus}, SetOptions(merge: true))
            .catchError((e) => debugPrint('[Firestore] updateOrderPaymentStatus error: $e'));
      } catch (e) {
        debugPrint('[Firestore] updateOrderPaymentStatus fallback: $e');
      }

      notifyListeners();
    }
  }

  // ===================== CLINICAL LOGS =====================
  final List<ClinicalLogModel> _clinicalLogs = [
    ClinicalLogModel(
      id: 'cl_01',
      bookingCode: 'PLC-2026-1024',
      patientName: 'Mrs. Jayasinghe (Nugegoda)',
      caregiverName: 'Sister K. Chamila',
      recordedAt: 'Today, 08:00 AM',
      bloodPressure: '128/82 mmHg',
      bloodSugar: '112 mg/dL',
      pulseRate: 72,
      spO2: 98,
      temperature: '98.4 °F',
      bedsoreTurnDone: true,
      medicationGiven: true,
      clinicalNotes: 'Breakfast taken well (oats & boiled egg). Vitals stable. Medication given at 08:30 AM.',
      isSupervisorReviewed: true,
    ),
    ClinicalLogModel(
      id: 'cl_02',
      bookingCode: 'PLC-2026-2048',
      patientName: 'Mr. Dharmadasa (Kelaniya)',
      caregiverName: 'Mr. Sunimal Perera',
      recordedAt: 'Today, 09:30 AM',
      bloodPressure: '135/88 mmHg',
      bloodSugar: '142 mg/dL',
      pulseRate: 78,
      spO2: 96,
      temperature: '98.6 °F',
      bedsoreTurnDone: true,
      medicationGiven: true,
      clinicalNotes: 'Catheter bag emptied (450ml, clear yellow). Passive range of motion exercises performed on left hemiplegic side.',
      isSupervisorReviewed: true,
    ),
    ClinicalLogModel(
      id: 'cl_03',
      bookingCode: 'PLC-2026-1024',
      patientName: 'Mrs. Jayasinghe (Nugegoda)',
      caregiverName: 'Sister K. Chamila',
      recordedAt: 'Today, 01:00 PM',
      bloodPressure: '120/80 mmHg',
      bloodSugar: '128 mg/dL',
      pulseRate: 74,
      spO2: 98,
      temperature: '98.2 °F',
      bedsoreTurnDone: true,
      medicationGiven: true,
      clinicalNotes: 'Sponge bath and fresh linen change done. Patient rested quietly for 1.5 hours.',
      isSupervisorReviewed: false,
    ),
  ];

  List<ClinicalLogModel> get clinicalLogs => _clinicalLogs;

  void reviewClinicalLog(String logId) {
    final idx = _clinicalLogs.indexWhere((l) => l.id == logId);
    if (idx != -1) {
      _clinicalLogs[idx] = _clinicalLogs[idx].copyWith(isSupervisorReviewed: true);
      notifyListeners();
    }
  }

  void addClinicalLog(ClinicalLogModel log) {
    _clinicalLogs.insert(0, log);
    notifyListeners();
  }

  // ===================== METRICS GETTERS =====================
  double get totalRevenueLKR {
    double total = 0;
    for (var b in _bookings) {
      if (b.paymentStatus == 'fully_paid') total += b.totalCostLKR;
      if (b.paymentStatus == 'advance_paid') total += (b.totalCostLKR * 0.5);
    }
    for (var o in _orders) {
      if (o.paymentStatus == 'paid') total += o.totalAmountLKR;
    }
    return total;
  }

  int get activeShiftsCount => _caregivers.where((c) => c.status == 'on_duty').length;
  int get pendingDispatchesCount => _bookings.where((b) => b.status == 'pending_review').length;
  int get pendingOrdersCount => _orders.where((o) => o.paymentStatus == 'pending_verification' || o.orderStatus == 'pending').length;
  int get lowStockItemsCount => _medicalItems.where((m) => m.stock <= 5).length;
  int get activeRentalsCount => _orders.where((o) => o.isRental && o.orderStatus != 'cancelled').length;

  @override
  void dispose() {
    _bookingsSubscription?.cancel();
    _ordersSubscription?.cancel();
    _usersSubscription?.cancel();
    _statsSubscription?.cancel();
    _deletedBookingsSubscription?.cancel();
    _caregiversSubscription?.cancel();
    _servicesSubscription?.cancel();
    super.dispose();
  }
}
