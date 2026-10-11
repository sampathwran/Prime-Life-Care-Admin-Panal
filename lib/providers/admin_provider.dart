import 'package:flutter/foundation.dart';
import '../models/booking_model.dart';
import '../models/service_model.dart';
import '../models/medical_item_model.dart';
import '../models/order_model.dart';
import '../models/caregiver_model.dart';
import '../models/clinical_log_model.dart';

class AdminProvider extends ChangeNotifier {
  int _selectedNavIndex = 0;
  int get selectedNavIndex => _selectedNavIndex;

  void setSelectedNavIndex(int index) {
    _selectedNavIndex = index;
    notifyListeners();
  }

  // Search filter query
  String _searchQuery = '';
  String get searchQuery => _searchQuery;
  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  // ===================== CAREGIVERS DIRECTORY =====================
  final List<CaregiverModel> _caregivers = [
    CaregiverModel(
      id: 'cg_01',
      name: 'Sister K. Chamila',
      phone: '+94 77 456 7890',
      tier: 'nvq_4_caregiver',
      tierLabel: 'NVQ Level 4 Certified Aide',
      district: 'Colombo',
      isPoliceVerified: true,
      isMedicalCleared: true,
      isCprCertified: true,
      status: 'on_duty',
      activeAssignedPatient: 'Mrs. Jayasinghe (Nugegoda)',
      rating: 4.95,
      completedShifts: 142,
    ),
    CaregiverModel(
      id: 'cg_02',
      name: 'Mr. Sunimal Perera',
      phone: '+94 71 890 1234',
      tier: 'nvq_5_nurse',
      tierLabel: 'NVQ Level 5 Senior Clinical Nurse',
      district: 'Gampaha',
      isPoliceVerified: true,
      isMedicalCleared: true,
      isCprCertified: true,
      status: 'on_duty',
      activeAssignedPatient: 'Mr. Dharmadasa (Kelaniya)',
      rating: 4.98,
      completedShifts: 210,
    ),
    CaregiverModel(
      id: 'cg_03',
      name: 'Nurse Dilrukshi Wickrama',
      phone: '+94 77 987 6543',
      tier: 'nvq_4_caregiver',
      tierLabel: 'Certified Maternity & Infant Nurse',
      district: 'Colombo',
      isPoliceVerified: true,
      isMedicalCleared: true,
      isCprCertified: true,
      status: 'available',
      rating: 4.90,
      completedShifts: 85,
    ),
    CaregiverModel(
      id: 'cg_04',
      name: 'Caregiver Nalaka Silva',
      phone: '+94 76 345 6789',
      tier: 'nvq_4_caregiver',
      tierLabel: 'NVQ 4 Geriatric & Stroke Caregiver',
      district: 'Galle',
      isPoliceVerified: true,
      isMedicalCleared: true,
      isCprCertified: true,
      status: 'available',
      rating: 4.88,
      completedShifts: 112,
    ),
    CaregiverModel(
      id: 'cg_05',
      name: 'Dr. Lasantha Mendis (MBBS)',
      phone: '+94 77 112 2334',
      tier: 'doctor',
      tierLabel: 'SLMC Registered Medical Officer',
      district: 'Colombo',
      isPoliceVerified: true,
      isMedicalCleared: true,
      isCprCertified: true,
      status: 'available',
      rating: 5.0,
      completedShifts: 64,
    ),
    CaregiverModel(
      id: 'cg_06',
      name: 'Aunty Sandamali Fernando',
      phone: '+94 75 223 3445',
      tier: 'nvq_4_caregiver',
      tierLabel: 'ECD Certified Child Caregiver',
      district: 'Colombo',
      isPoliceVerified: true,
      isMedicalCleared: true,
      isCprCertified: true,
      status: 'available',
      rating: 4.92,
      completedShifts: 94,
    ),
  ];

  List<CaregiverModel> get caregivers => _caregivers;

  void addCaregiver(CaregiverModel caregiver) {
    _caregivers.add(caregiver);
    notifyListeners();
  }

  void updateCaregiver(CaregiverModel caregiver) {
    final idx = _caregivers.indexWhere((c) => c.id == caregiver.id);
    if (idx != -1) {
      _caregivers[idx] = caregiver;
      notifyListeners();
    }
  }

  void deleteCaregiver(String id) {
    _caregivers.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  // ===================== BOOKINGS =====================
  final List<BookingModel> _bookings = [
    BookingModel(
      id: 'bk_101',
      bookingCode: 'PLC-2026-1024',
      serviceName: '12-Hour Day Shift Care',
      staffTierName: 'NVQ Level 4 Certified Aide',
      shiftType: '12h_day',
      shiftHours: 12,
      pricePerDayLKR: 4500,
      patientName: 'Mrs. Jayasinghe (Mother)',
      patientAge: 78,
      patientGender: 'Female',
      mobility: 'partial',
      medicalConditions: 'Hypertension, Mild Arthritis',
      district: 'Colombo',
      city: 'Nugegoda',
      address: 'No 24, Chapel Road, Nugegoda',
      contactName: 'Rohan Jayasinghe',
      contactPhone: '+94 77 123 4567',
      startDate: '2026-10-12',
      durationDays: 14,
      totalCostLKR: 63000,
      status: 'in_progress',
      assignedCaregiverId: 'cg_01',
      assignedCaregiverName: 'Sister K. Chamila',
      assignedCaregiverPhone: '+94 77 456 7890',
      paymentStatus: 'fully_paid',
      createdAt: '2026-10-10 08:30 AM',
    ),
    BookingModel(
      id: 'bk_102',
      bookingCode: 'PLC-2026-2048',
      serviceName: '24-Hour Live-in Care',
      staffTierName: 'NVQ Level 5 Senior Nurse',
      shiftType: '24h_full',
      shiftHours: 24,
      pricePerDayLKR: 7000,
      patientName: 'Mr. Dharmadasa (Father-in-law)',
      patientAge: 82,
      patientGender: 'Male',
      mobility: 'bedridden',
      medicalConditions: 'Post-Stroke Recovery, Catheter care',
      district: 'Gampaha',
      city: 'Kelaniya',
      address: 'No 18/A, Station Road, Kelaniya',
      contactName: 'Rohan Jayasinghe',
      contactPhone: '+94 77 123 4567',
      startDate: '2026-10-11',
      durationDays: 30,
      totalCostLKR: 210000,
      status: 'in_progress',
      assignedCaregiverId: 'cg_02',
      assignedCaregiverName: 'Mr. Sunimal Perera',
      assignedCaregiverPhone: '+94 71 890 1234',
      paymentStatus: 'advance_paid',
      createdAt: '2026-10-09 02:15 PM',
    ),
    BookingModel(
      id: 'bk_103',
      bookingCode: 'PLC-2026-3011',
      serviceName: 'Newborn & Mother Post-Natal Care',
      staffTierName: 'Maternity Nurse NVQ 4',
      shiftType: '12h_day',
      shiftHours: 12,
      pricePerDayLKR: 4800,
      patientName: 'Baby of Chamari (Newborn, 2 weeks)',
      patientAge: 1,
      patientGender: 'Male',
      mobility: 'independent',
      medicalConditions: 'Post-Cesarean Mother care, Colic, Umbilical healing',
      district: 'Colombo',
      city: 'Havelock Town',
      address: 'No 12/4, Havelock Road, Colombo 05',
      contactName: 'Chamari Senaratne',
      contactPhone: '+94 77 889 9001',
      startDate: '2026-10-13',
      durationDays: 21,
      totalCostLKR: 100800,
      status: 'caregiver_assigned',
      assignedCaregiverId: 'cg_03',
      assignedCaregiverName: 'Nurse Dilrukshi Wickrama',
      assignedCaregiverPhone: '+94 77 987 6543',
      paymentStatus: 'advance_paid',
      createdAt: '2026-10-11 09:20 AM',
    ),
    BookingModel(
      id: 'bk_104',
      bookingCode: 'PLC-2026-4029',
      serviceName: '12-Hour Night Shift Care',
      staffTierName: 'NVQ 4 Certified',
      shiftType: '12h_night',
      shiftHours: 12,
      pricePerDayLKR: 5000,
      patientName: 'Mrs. Kusuma Dissanayake',
      patientAge: 81,
      patientGender: 'Female',
      mobility: 'partial',
      medicalConditions: 'Early Dementia, Disorientation at night',
      district: 'Kandy',
      city: 'Peradeniya',
      address: 'No 55, Galaha Road, Peradeniya',
      contactName: 'Dr. Priyantha Dissanayake (Melbourne)',
      contactPhone: '+61 412 345 678',
      startDate: '2026-10-14',
      durationDays: 30,
      totalCostLKR: 150000,
      status: 'pending_review',
      paymentStatus: 'unpaid',
      createdAt: '2026-10-11 11:45 AM',
    ),
  ];

  List<BookingModel> get bookings => _bookings;

  void assignCaregiver(String bookingId, CaregiverModel caregiver) {
    final idx = _bookings.indexWhere((b) => b.id == bookingId);
    if (idx != -1) {
      _bookings[idx] = _bookings[idx].copyWith(
        assignedCaregiverId: caregiver.id,
        assignedCaregiverName: caregiver.name,
        assignedCaregiverPhone: caregiver.phone,
        status: 'caregiver_assigned',
      );

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

  void updateBookingStatus(String bookingId, String newStatus) {
    final idx = _bookings.indexWhere((b) => b.id == bookingId);
    if (idx != -1) {
      _bookings[idx] = _bookings[idx].copyWith(status: newStatus);
      notifyListeners();
    }
  }

  void updateBookingPaymentStatus(String bookingId, String newStatus) {
    final idx = _bookings.indexWhere((b) => b.id == bookingId);
    if (idx != -1) {
      _bookings[idx] = _bookings[idx].copyWith(paymentStatus: newStatus);
      notifyListeners();
    }
  }

  // ===================== CARE SERVICES & STAFF TIERS =====================
  final List<ServiceModel> _services = [
    ServiceModel(
      id: 'svc_01',
      nameEn: '12-Hour Day Shift Care',
      nameSi: 'පැය 12 දිවා සාත්තු සේවය',
      category: 'elderly_care',
      hours: 12,
      defaultPriceLKR: 4500,
      pricingUnit: '/ day',
      shortDescription: '07:00 AM - 07:00 PM dedicated daytime care for bedridden or elderly needing daily assistance.',
      tiers: [
        TierPricing(tierId: 'basic_aide', tierName: 'Basic Companion Aide', priceLKR: 3000, duties: ['Conversation & companionship', 'Routine meal prep', 'Garden short walk']),
        TierPricing(tierId: 'nurse_assistant', tierName: 'Nurse Assistant', priceLKR: 3800, duties: ['Assisted sponge bathing', 'Feeding & medication reminding', 'Wheelchair transfer']),
        TierPricing(tierId: 'nvq_4_caregiver', tierName: 'NVQ 4 Certified Caregiver', priceLKR: 4500, duties: ['Bed turning every 2h', 'BP & Sugar vitals log', 'Dementia patient calming']),
        TierPricing(tierId: 'nvq_5_nurse', tierName: 'NVQ 5 Senior Clinical Nurse', priceLKR: 5800, duties: ['Aseptic surgical dressings', 'Catheter & Ryles tube', 'IV medication']),
      ],
    ),
    ServiceModel(
      id: 'svc_02',
      nameEn: '12-Hour Night Shift Care',
      nameSi: 'පැය 12 රාත්‍රී සාත්තු සේවය',
      category: 'elderly_care',
      hours: 12,
      defaultPriceLKR: 5000,
      pricingUnit: '/ night',
      shortDescription: '07:00 PM - 07:00 AM vigilant nighttime assistance ensuring safety, comfort, and peaceful sleep.',
      tiers: [
        TierPricing(tierId: 'basic_aide', tierName: 'Basic Night Aide', priceLKR: 3500, duties: ['Nighttime bathroom assistance', 'Hydration & comfort']),
        TierPricing(tierId: 'nurse_assistant', tierName: 'Nurse Assistant', priceLKR: 4200, duties: ['Overnight vital signs', 'Emergency notification']),
        TierPricing(tierId: 'nvq_4_caregiver', tierName: 'NVQ 4 Certified ⭐', priceLKR: 5000, duties: ['Bed turning every 2 hours', 'Calming disoriented wandering']),
        TierPricing(tierId: 'nvq_5_nurse', tierName: 'NVQ 5 Senior Nurse', priceLKR: 6200, duties: ['Ventilator/tracheostomy care', 'Oxygen titration']),
      ],
    ),
    ServiceModel(
      id: 'svc_03',
      nameEn: '24-Hour Full Live-In Care',
      nameSi: 'පැය 24 පූර්ණ නේවාසික සාත්තු සේවය',
      category: 'elderly_care',
      hours: 24,
      defaultPriceLKR: 7500,
      pricingUnit: '/ day',
      shortDescription: 'Round-the-clock live-in caregiver providing constant care, comfort, and emergency readiness.',
      tiers: [
        TierPricing(tierId: 'basic_aide', tierName: 'Live-In Companion', priceLKR: 5500, duties: ['Light cooking, companionship', 'Room tidying']),
        TierPricing(tierId: 'nurse_assistant', tierName: 'Live-in Nurse Aide', priceLKR: 6500, duties: ['Bathing, feeding, movement', 'Medication routine']),
        TierPricing(tierId: 'nvq_4_caregiver', tierName: 'NVQ 4 Live-in ⭐', priceLKR: 7500, duties: ['Total bedridden elder care', 'Daily vitals logbook']),
        TierPricing(tierId: 'nvq_5_nurse', tierName: 'NVQ 5 Live-in Nurse', priceLKR: 9500, duties: ['Complex medical cases', 'Specialist doctor liaison']),
      ],
    ),
    ServiceModel(
      id: 'svc_04',
      nameEn: 'Newborn & Mother Post-Natal Care',
      nameSi: 'ළදරු සහ මව්පිය පශ්චාත් ප්‍රසව සාත්තු සේවය',
      category: 'child_care',
      hours: 12,
      defaultPriceLKR: 4800,
      pricingUnit: '/ day',
      shortDescription: 'Dedicated postpartum assistance: umbilical cord care, lactation guidance, colic soothing.',
      tiers: [
        TierPricing(tierId: 'basic_aide', tierName: 'Infant Care Aide', priceLKR: 3500, duties: ['Bottle sterilizing', 'Gentle infant sponge bath']),
        TierPricing(tierId: 'nvq_4_caregiver', tierName: 'Maternity Nurse NVQ 4 ⭐', priceLKR: 4800, duties: ['Umbilical cord antiseptic care', 'Colic burping protocol', 'Lactation guidance']),
        TierPricing(tierId: 'nvq_5_nurse', tierName: 'Pediatric Clinical Nurse NVQ 5', priceLKR: 6200, duties: ['Premature infant care', 'Post-C-section surgical wound dressings']),
      ],
    ),
    ServiceModel(
      id: 'svc_05',
      nameEn: 'Toddler & Child Daytime Care (1-6 Yrs)',
      nameSi: 'දෛනික ළමා සාත්තු සහ පෙරපාසල් සහාය',
      category: 'child_care',
      hours: 12,
      defaultPriceLKR: 4200,
      pricingUnit: '/ day',
      shortDescription: 'Trustworthy child nanny for working parents: nutritious feeding, safe play, learning activities.',
      tiers: [
        TierPricing(tierId: 'basic_aide', tierName: 'Trained Child Nanny', priceLKR: 3200, duties: ['Active supervision', 'Nutritious meals serving', 'Play area tidying']),
        TierPricing(tierId: 'nvq_4_caregiver', tierName: 'ECD Certified Caregiver ⭐', priceLKR: 4200, duties: ['Early childhood sensory play', 'Speech & story reading', 'Child first aid certified']),
        TierPricing(tierId: 'nvq_5_nurse', tierName: 'Special Needs / Pediatric Nurse', priceLKR: 5500, duties: ['Autism & ADHD child handling', 'Nebulizer & seizure monitoring']),
      ],
    ),
    ServiceModel(
      id: 'svc_06',
      nameEn: 'Home Visit Medical Officer (Doctor)',
      nameSi: 'නිවසටම පැමිණෙන වෛද්‍ය සේවාව',
      category: 'short_visit',
      hours: 2,
      defaultPriceLKR: 6500,
      pricingUnit: '/ visit',
      shortDescription: 'SLMC registered medical doctor home visit for complete clinical evaluation and prescriptions.',
      tiers: [
        TierPricing(tierId: 'doctor', tierName: 'MBBS Medical Officer', priceLKR: 6500, duties: ['Comprehensive clinical diagnosis', 'Prescription renewal', 'Lab tests ordering']),
      ],
    ),
  ];

  List<ServiceModel> get services => _services;

  void addService(ServiceModel service) {
    _services.add(service);
    notifyListeners();
  }

  void updateService(ServiceModel service) {
    final idx = _services.indexWhere((s) => s.id == service.id);
    if (idx != -1) {
      _services[idx] = service;
      notifyListeners();
    }
  }

  void deleteService(String id) {
    _services.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  // ===================== MEDICAL EQUIPMENT STORE =====================
  final List<MedicalItemModel> _medicalItems = [
    MedicalItemModel(
      id: 'med_01',
      nameEn: 'Electric 3-Function Hospital Bed',
      nameSi: 'විදුලි මෝටර් සහිත රෝහල් ඇඳ (3-Function Electric Bed)',
      category: 'equipment',
      buyPriceLKR: 145000,
      canRent: true,
      monthlyRentLKR: 14000,
      securityDepositLKR: 20000,
      stock: 4,
      imageUrls: [
        'https://images.unsplash.com/photo-1586773860418-d37222d8fce3?auto=format&fit=crop&q=80&w=800',
        'https://images.unsplash.com/photo-1516549655169-df83a0774514?auto=format&fit=crop&q=80&w=800',
      ],
      description: 'Medical motorized adjustable head, foot, and overall height control with side safety guardrails and IV pole.',
    ),
    MedicalItemModel(
      id: 'med_02',
      nameEn: 'Anti-Bedsore Ripple Air Mattress & Pump',
      nameSi: 'ඇඳ තුවාල වළක්වන රිපල් එයාර් මෙට්ටය සහ නිහඬ පොම්පය',
      category: 'equipment',
      buyPriceLKR: 14500,
      canRent: true,
      monthlyRentLKR: 3500,
      securityDepositLKR: 5000,
      stock: 18,
      imageUrls: [
        'https://images.unsplash.com/photo-1584515979956-d9f6e5d09982?auto=format&fit=crop&q=80&w=800',
      ],
      description: 'Alternating air pressure cycle relief prevents skin breakdown and tissue necrosis in bedridden elders.',
    ),
    MedicalItemModel(
      id: 'med_03',
      nameEn: 'Deluxe Lightweight Folding Wheelchair',
      nameSi: 'නැවිය හැකි සැහැල්ලු රෝද පුටුව (Foldable Wheelchair)',
      category: 'mobility',
      buyPriceLKR: 32000,
      canRent: true,
      monthlyRentLKR: 4500,
      securityDepositLKR: 7000,
      stock: 9,
      imageUrls: [
        'https://images.unsplash.com/photo-1576765608535-5f04d1e3f289?auto=format&fit=crop&q=80&w=800',
      ],
      description: 'Chrome-plated durable steel frame with dual handbrakes, comfortable leatherette seat and folding footrests.',
    ),
    MedicalItemModel(
      id: 'med_04',
      nameEn: 'Adult Diapers Care Pack (Pack of 10 - Size L)',
      nameSi: 'වැඩිහිටි ඩයපර් පැකට්ටුව (Adult Diapers - Large)',
      category: 'hygiene',
      buyPriceLKR: 2850,
      canRent: false,
      stock: 65,
      imageUrls: [
        'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&q=80&w=800',
      ],
      description: 'High-absorbency antibacterial adult briefs with wetness indicator for leakproof overnight security.',
    ),
    MedicalItemModel(
      id: 'med_05',
      nameEn: 'Omron Digital Upper Arm BP Monitor',
      nameSi: 'ඩිජිටල් රුධිර පීඩන මාපකය (Digital BP Monitor)',
      category: 'monitoring',
      buyPriceLKR: 12500,
      canRent: false,
      stock: 14,
      imageUrls: [
        'https://images.unsplash.com/photo-1576091160550-2173dba999ef?auto=format&fit=crop&q=80&w=800',
      ],
      description: 'Accurate oscillometric blood pressure and pulse monitor with irregular heartbeat indicator.',
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

  void deleteMedicalItem(String id) {
    _medicalItems.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  // ===================== STORE ORDERS & RENTALS =====================
  final List<OrderModel> _orders = [
    OrderModel(
      id: 'ord_01',
      orderCode: 'ORD-2026-1049',
      customerName: 'Rohan Jayasinghe',
      customerPhone: '+94 77 123 4567',
      deliveryAddress: 'No 24, Chapel Road, Nugegoda',
      district: 'Colombo',
      items: [
        OrderItemEntry(
          itemId: 'med_02',
          itemName: 'Anti-Bedsore Ripple Air Mattress & Pump',
          quantity: 1,
          priceLKR: 14500,
          type: 'purchase',
        ),
      ],
      totalAmountLKR: 14500,
      paymentMethod: 'cod',
      paymentStatus: 'paid',
      orderStatus: 'delivered',
      createdAt: '2026-10-10 09:15 AM',
    ),
    OrderModel(
      id: 'ord_02',
      orderCode: 'RNT-2026-2004',
      customerName: 'D. M. Perera',
      customerPhone: '+94 71 334 4556',
      deliveryAddress: 'No 88, Galle Road, Dehiwala',
      district: 'Colombo',
      items: [
        OrderItemEntry(
          itemId: 'med_01',
          itemName: 'Electric 3-Function Hospital Bed (Monthly Rental)',
          quantity: 1,
          priceLKR: 14000,
          type: 'rental',
        ),
      ],
      totalAmountLKR: 34000, // 14,000 rent + 20,000 security deposit
      paymentMethod: 'bank_transfer',
      paymentStatus: 'pending_verification',
      bankSlipUrl: 'Commercial_Bank_Slip_Ref_8932.jpg',
      orderStatus: 'pending',
      isRental: true,
      rentalStartDate: '2026-10-11',
      rentalEndDate: '2026-11-11',
      securityDepositLKR: 20000,
      createdAt: '2026-10-11 10:00 AM',
    ),
    OrderModel(
      id: 'ord_03',
      orderCode: 'ORD-2026-3021',
      customerName: 'Kanchana Wickramasinghe',
      customerPhone: '+94 75 223 3445',
      deliveryAddress: 'No 15/B, Jayanthi Mawatha, Battaramulla',
      district: 'Colombo',
      items: [
        OrderItemEntry(
          itemId: 'med_04',
          itemName: 'Adult Diapers Care Pack (Pack of 10 - Large)',
          quantity: 4,
          priceLKR: 11400,
          type: 'purchase',
        ),
      ],
      totalAmountLKR: 11400,
      paymentMethod: 'cod',
      paymentStatus: 'cod_pending',
      orderStatus: 'dispatched',
      createdAt: '2026-10-11 11:30 AM',
    ),
  ];

  List<OrderModel> get orders => _orders;

  void approveBankTransfer(String orderId) {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      _orders[idx] = _orders[idx].copyWith(
        paymentStatus: 'paid',
        orderStatus: 'dispatched',
      );
      notifyListeners();
    }
  }

  void updateOrderStatus(String orderId, String newStatus) {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      _orders[idx] = _orders[idx].copyWith(orderStatus: newStatus);
      notifyListeners();
    }
  }

  // ===================== CLINICAL VITALS LOGBOOK =====================
  final List<ClinicalLogModel> _clinicalLogs = [
    ClinicalLogModel(
      id: 'cl_01',
      bookingCode: 'PLC-2026-1024',
      patientName: 'Mrs. Jayasinghe (Nugegoda)',
      caregiverName: 'Sister K. Chamila',
      recordedAt: 'Today, 08:30 AM',
      bloodPressure: '124/82 mmHg',
      bloodSugar: '114 mg/dL',
      pulseRate: 72,
      spO2: 98,
      temperature: '98.4 °F',
      bedsoreTurnDone: true,
      medicationGiven: true,
      clinicalNotes: 'Breakfast porridge finished smoothly. Morning Losartan 50mg given. Skin intact over sacrum.',
      isSupervisorReviewed: true,
    ),
    ClinicalLogModel(
      id: 'cl_02',
      bookingCode: 'PLC-2026-2048',
      patientName: 'Mr. Dharmadasa (Kelaniya)',
      caregiverName: 'Mr. Sunimal Perera',
      recordedAt: 'Today, 10:15 AM',
      bloodPressure: '136/88 mmHg',
      bloodSugar: '142 mg/dL',
      pulseRate: 78,
      spO2: 97,
      temperature: '98.6 °F',
      bedsoreTurnDone: true,
      medicationGiven: true,
      clinicalNotes: 'Catheter bag emptied (450ml clear urine). Right-side hemiplegia passive range-of-motion completed.',
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
}
