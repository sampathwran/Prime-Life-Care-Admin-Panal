import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/booking_model.dart';
import '../models/caregiver_model.dart';
import '../providers/admin_provider.dart';
import '../theme/app_theme.dart';
import '../utils/web_file_utils.dart';
import 'image_cropper_dialog.dart';
import 'whatsapp_button.dart';

/// Comprehensive 5-Tab Profile Management Dialog for Staff Members
class CaregiverProfileManagementDialog extends StatefulWidget {
  final CaregiverModel caregiver;

  const CaregiverProfileManagementDialog({
    super.key,
    required this.caregiver,
  });

  static Future<void> show(BuildContext context, CaregiverModel caregiver) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => CaregiverProfileManagementDialog(caregiver: caregiver),
    );
  }

  @override
  State<CaregiverProfileManagementDialog> createState() => _CaregiverProfileManagementDialogState();
}

class _CaregiverProfileManagementDialogState extends State<CaregiverProfileManagementDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late CaregiverModel _cg;

  // Tab 1: Personal Details Form Controllers
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _nicCtrl;
  late TextEditingController _ageCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _emergencyNameCtrl;
  late TextEditingController _emergencyPhoneCtrl;
  late TextEditingController _bioCtrl;
  late String _selectedGender;
  late String _selectedDistrict;
  late String _currentStatus;

  // Tab 2: Qualifications & Verifications Form Controllers
  late String _selectedTier;
  late TextEditingController _tierLabelCtrl;
  late TextEditingController _experienceCtrl;
  late bool _isPoliceVerified;
  late bool _isMedicalCleared;
  late bool _isCprCertified;

  // Tab 3: Language & Clinical Skills
  late List<Map<String, dynamic>> _languages;
  late List<String> _clinicalSkills;
  final TextEditingController _customSkillCtrl = TextEditingController();
  final TextEditingController _customLangCtrl = TextEditingController();

  // Tab 5: Earnings & Bank Finance Form Controllers
  late TextEditingController _dailyRateCtrl;
  late TextEditingController _hourlyRateCtrl;
  late TextEditingController _totalEarningsCtrl;
  late TextEditingController _pendingPayoutCtrl;
  late String _bankName;
  late TextEditingController _customBankCtrl;
  late TextEditingController _branchCtrl;
  late TextEditingController _accNumCtrl;
  late TextEditingController _accHolderCtrl;
  late String _payoutCycle;
  late bool _bankIsVerified;

  bool _isSaving = false;

  static const List<String> sriLankanDistricts = [
    'Colombo',
    'Gampaha',
    'Kalutara',
    'Kandy',
    'Matale',
    'Nuwara Eliya',
    'Galle',
    'Matara',
    'Hambantota',
    'Jaffna',
    'Kilinochchi',
    'Mannar',
    'Vavuniya',
    'Mullaitivu',
    'Batticaloa',
    'Ampara',
    'Trincomalee',
    'Kurunegala',
    'Puttalam',
    'Anuradhapura',
    'Polonnaruwa',
    'Badulla',
    'Monaragala',
    'Ratnapura',
    'Kegalle',
  ];

  static const List<Map<String, String>> sriLankanBanks = [
    {'code': 'commercial', 'name': 'Commercial Bank of Ceylon'},
    {'code': 'boc', 'name': 'Bank of Ceylon (BOC)'},
    {'code': 'peoples', 'name': "People's Bank"},
    {'code': 'sampath', 'name': 'Sampath Bank'},
    {'code': 'hnb', 'name': 'Hatton National Bank (HNB)'},
    {'code': 'seylan', 'name': 'Seylan Bank'},
    {'code': 'ntb', 'name': 'Nations Trust Bank (NTB)'},
    {'code': 'dfcc', 'name': 'DFCC Bank'},
    {'code': 'ndb', 'name': 'National Development Bank (NDB)'},
    {'code': 'pan_asia', 'name': 'Pan Asia Bank'},
    {'code': 'union', 'name': 'Union Bank of Colombo'},
    {'code': 'amana', 'name': 'Amana Bank'},
    {'code': 'other', 'name': 'Other / Cooperative Bank'},
  ];

  static const List<String> allPresetClinicalSkills = [
    'Elderly Bedside Assistance',
    'Bed Turning & Bedsore Prevention',
    'BP & Sugar Vitals Monitoring',
    'Medication Timing Routine',
    'Assisted Sponge Bathing & Hygiene',
    'Catheter & Ryles Tube Care',
    'Aseptic Surgical Dressings',
    'Tracheostomy & Oxygen Titration',
    'Dementia & Alzheimer\'s Calming',
    'Infant & Post-Natal Mother Care',
    'Palliative & End-of-Life Care',
    'Wheelchair & Mobility Transfer',
    'Feeding Tube & Clinical Nutrition',
    'IV Cannula & Infusion Observation',
    'Post-Surgical Mobilization',
  ];

  static const List<Map<String, String>> defaultRejectionReasons = [
    {
      'title': 'Document image is blurry or illegible',
      'detail': 'Document image is blurry or illegible. Please upload a high-resolution, clear copy.',
    },
    {
      'title': 'Certificate has expired',
      'detail': 'Certificate has expired past validity date. Please provide a valid active certificate.',
    },
    {
      'title': 'Name or NIC does not match registration',
      'detail': 'Name or NIC on document does not match your registered profile details.',
    },
    {
      'title': 'Issuing institute is not accredited (TVEC / SLMC / NAITA)',
      'detail': 'Issuing institute is not an accredited TVEC / SLMC / NAITA training body.',
    },
    {
      'title': 'Incomplete document (Missing pages / back side)',
      'detail': 'Incomplete document. Please upload all pages including reverse side.',
    },
    {
      'title': 'Police clearance is older than 6 months',
      'detail': 'Police clearance report is older than 6 months. A recent report is required.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _cg = widget.caregiver;
    _initFieldsFromCaregiver(_cg);
  }

  void _initFieldsFromCaregiver(CaregiverModel cg) {
    _cg = cg;
    // Tab 1
    _nameCtrl = TextEditingController(text: cg.name);
    _phoneCtrl = TextEditingController(text: cg.phone);
    _emailCtrl = TextEditingController(text: cg.email);
    _nicCtrl = TextEditingController(text: cg.nic ?? '');
    _ageCtrl = TextEditingController(text: cg.age.toString());
    _addressCtrl = TextEditingController(text: cg.address ?? '');
    _emergencyNameCtrl = TextEditingController(text: cg.emergencyContactName);
    _emergencyPhoneCtrl = TextEditingController(text: cg.emergencyContactPhone);
    _bioCtrl = TextEditingController(text: cg.bio);
    _selectedGender = cg.gender.isNotEmpty ? cg.gender : 'Female';
    _selectedDistrict = sriLankanDistricts.contains(cg.district) ? cg.district : 'Colombo';
    _currentStatus = cg.status;

    // Tab 2
    _selectedTier = cg.tier;
    _tierLabelCtrl = TextEditingController(text: cg.tierLabel);
    _experienceCtrl = TextEditingController(text: cg.experienceYears);
    _isPoliceVerified = cg.isPoliceVerified;
    _isMedicalCleared = cg.isMedicalCleared;
    _isCprCertified = cg.isCprCertified;

    // Tab 3
    _languages = cg.languages.map((l) => Map<String, dynamic>.from(l)).toList();
    if (_languages.isEmpty) {
      _languages = [
        {'languageName': 'Sinhala', 'languageCode': 'si', 'speakingPercent': 100, 'writingPercent': 100, 'understandingPercent': 100},
        {'languageName': 'English', 'languageCode': 'en', 'speakingPercent': 80, 'writingPercent': 75, 'understandingPercent': 85},
        {'languageName': 'Tamil', 'languageCode': 'ta', 'speakingPercent': 60, 'writingPercent': 40, 'understandingPercent': 65},
      ];
    }
    _clinicalSkills = List<String>.from(cg.clinicalSkills);
    if (_clinicalSkills.isEmpty) {
      _clinicalSkills = [
        'Elderly Bedside Assistance',
        'Bed Turning & Bedsore Prevention',
        'BP & Sugar Vitals Monitoring',
        'Medication Timing Routine',
        'Assisted Sponge Bathing & Hygiene',
      ];
    }

    // Tab 5
    _dailyRateCtrl = TextEditingController(text: cg.dailyRateLKR.toStringAsFixed(0));
    _hourlyRateCtrl = TextEditingController(text: cg.hourlyRateLKR.toStringAsFixed(0));
    _totalEarningsCtrl = TextEditingController(text: cg.totalEarnings.toStringAsFixed(0));
    _pendingPayoutCtrl = TextEditingController(text: cg.pendingPayout.toStringAsFixed(0));

    final b = cg.bankDetails;
    final bNameRaw = (b['bankName'] ?? '').toString();
    final matchedBank = sriLankanBanks.any((x) => x['name'] == bNameRaw) ? bNameRaw : (bNameRaw.isEmpty ? 'Commercial Bank of Ceylon' : 'Other / Cooperative Bank');
    _bankName = matchedBank;
    _customBankCtrl = TextEditingController(text: matchedBank == 'Other / Cooperative Bank' ? bNameRaw : '');
    _branchCtrl = TextEditingController(text: (b['branchName'] ?? '').toString());
    _accNumCtrl = TextEditingController(text: (b['accountNumber'] ?? '').toString());
    _accHolderCtrl = TextEditingController(text: (b['accountHolderName'] ?? cg.name).toString());
    _payoutCycle = (b['payoutCycle'] ?? 'Weekly Every Monday').toString();
    _bankIsVerified = b['isVerified'] == true;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _nicCtrl.dispose();
    _ageCtrl.dispose();
    _addressCtrl.dispose();
    _emergencyNameCtrl.dispose();
    _emergencyPhoneCtrl.dispose();
    _bioCtrl.dispose();
    _tierLabelCtrl.dispose();
    _experienceCtrl.dispose();
    _customSkillCtrl.dispose();
    _customLangCtrl.dispose();
    _dailyRateCtrl.dispose();
    _hourlyRateCtrl.dispose();
    _totalEarningsCtrl.dispose();
    _pendingPayoutCtrl.dispose();
    _customBankCtrl.dispose();
    _branchCtrl.dispose();
    _accNumCtrl.dispose();
    _accHolderCtrl.dispose();
    super.dispose();
  }

  void _syncLatestFromProvider() {
    final provider = context.read<AdminProvider>();
    final idx = provider.caregivers.indexWhere((c) => c.id == _cg.id || c.membershipNumber == _cg.membershipNumber);
    if (idx != -1) {
      setState(() {
        _cg = provider.caregivers[idx];
      });
    }
  }

  // ===================== SAVE HANDLERS =====================

  Future<void> _savePersonalDetails() async {
    setState(() => _isSaving = true);
    final provider = context.read<AdminProvider>();
    final updated = _cg.copyWith(
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      nic: _nicCtrl.text.trim(),
      age: int.tryParse(_ageCtrl.text.trim()) ?? _cg.age,
      gender: _selectedGender,
      district: _selectedDistrict,
      address: _addressCtrl.text.trim(),
      emergencyContactName: _emergencyNameCtrl.text.trim(),
      emergencyContactPhone: _emergencyPhoneCtrl.text.trim(),
      bio: _bioCtrl.text.trim(),
      status: _currentStatus,
    );
    provider.updateCaregiver(updated);
    setState(() {
      _cg = updated;
      _isSaving = false;
    });
    _showToast('Personal details updated successfully!', AppTheme.emeraldGreen);
  }

  Future<void> _saveQualifications() async {
    setState(() => _isSaving = true);
    final provider = context.read<AdminProvider>();
    final updated = _cg.copyWith(
      tier: _selectedTier,
      tierLabel: _tierLabelCtrl.text.trim(),
      experienceYears: _experienceCtrl.text.trim(),
      isPoliceVerified: _isPoliceVerified,
      isMedicalCleared: _isMedicalCleared,
      isCprCertified: _isCprCertified,
    );
    provider.updateCaregiver(updated);
    setState(() {
      _cg = updated;
      _isSaving = false;
    });
    _showToast('Qualifications & verifications updated successfully!', AppTheme.emeraldGreen);
  }

  Future<void> _saveLanguagesAndSkills() async {
    setState(() => _isSaving = true);
    final provider = context.read<AdminProvider>();
    final updated = _cg.copyWith(
      languages: _languages,
      clinicalSkills: _clinicalSkills,
    );
    provider.updateCaregiver(updated);
    setState(() {
      _cg = updated;
      _isSaving = false;
    });
    _showToast('Language and clinical skills updated successfully!', AppTheme.emeraldGreen);
  }

  Future<void> _saveEarningsAndBank() async {
    setState(() => _isSaving = true);
    final provider = context.read<AdminProvider>();

    final finalBankName = _bankName == 'Other / Cooperative Bank'
        ? _customBankCtrl.text.trim()
        : _bankName;

    final bankMap = {
      'bankName': finalBankName,
      'branchName': _branchCtrl.text.trim(),
      'accountNumber': _accNumCtrl.text.trim(),
      'accountHolderName': _accHolderCtrl.text.trim(),
      'payoutCycle': _payoutCycle,
      'isVerified': _bankIsVerified,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    final updated = _cg.copyWith(
      dailyRateLKR: double.tryParse(_dailyRateCtrl.text.trim()) ?? _cg.dailyRateLKR,
      hourlyRateLKR: double.tryParse(_hourlyRateCtrl.text.trim()) ?? _cg.hourlyRateLKR,
      totalEarnings: double.tryParse(_totalEarningsCtrl.text.trim()) ?? _cg.totalEarnings,
      pendingPayout: double.tryParse(_pendingPayoutCtrl.text.trim()) ?? _cg.pendingPayout,
      bankDetails: bankMap,
    );
    provider.updateCaregiver(updated);
    setState(() {
      _cg = updated;
      _isSaving = false;
    });
    _showToast('Earnings and Sri Lankan bank details saved successfully!', AppTheme.emeraldGreen);
  }

  void _showToast(String message, Color bgColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ===================== PROFILE PHOTO CONTROLS =====================

  void _openCropDialog({required String imageSource, String? fileName}) {
    showDialog(
      context: context,
      builder: (ctx) => ImageCropperDialog(
        imageSource: imageSource,
        title: 'Crop & Frame Profile Photo - ${_cg.name}',
        fileName: fileName ?? '${_cg.membershipNumber}-profile.jpg',
        onSave: (croppedBase64) {
          context.read<AdminProvider>().updateCaregiverProfileImage(
                caregiverId: _cg.membershipNumber.isNotEmpty ? _cg.membershipNumber : _cg.id,
                imageBase64: croppedBase64,
                autoApprove: true,
              );
          _syncLatestFromProvider();
          _showToast('Profile photo cropped & saved successfully!', AppTheme.emeraldGreen);
        },
      ),
    );
  }

  void _pickAndUploadPhotoFromPC() {
    pickImageFileFromPC(
      onPicked: (base64Data, fileName) {
        _openCropDialog(imageSource: base64Data, fileName: fileName);
      },
    );
  }

  void _downloadProfilePhoto() {
    if (_cg.profileImageUrl != null && _cg.profileImageUrl!.isNotEmpty) {
      downloadWebFile(
        dataOrUrl: _cg.profileImageUrl!,
        fileName: '${_cg.membershipNumber}-profile.jpg',
      );
      _showToast('Download started for profile photo!', AppTheme.primaryBlue);
    }
  }

  // ===================== REJECTION REASON MODAL =====================

  void _promptRejectionReason({
    required String targetName,
    required Function(String reason) onSelected,
  }) {
    String selectedReason = defaultRejectionReasons.first['detail']!;
    final customCtrl = TextEditingController();
    bool isCustom = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setRejState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Row(
              children: [
                const Icon(Icons.rule_folder_rounded, color: Colors.redAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Reject: $targetName', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Choose a reason to notify the caregiver in Sinhala, English & Tamil:',
                      style: TextStyle(fontSize: 12, color: AppTheme.slate600),
                    ),
                    const SizedBox(height: 12),
                    ...defaultRejectionReasons.map((r) {
                      final isSelected = !isCustom && selectedReason == r['detail'];
                      return InkWell(
                        onTap: () {
                          setRejState(() {
                            isCustom = false;
                            selectedReason = r['detail']!;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.red.shade50 : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isSelected ? Colors.redAccent : Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                size: 16,
                                color: isSelected ? Colors.redAccent : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  r['title']!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? Colors.red.shade900 : AppTheme.slate800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    InkWell(
                      onTap: () => setRejState(() => isCustom = true),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isCustom ? Colors.red.shade50 : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isCustom ? Colors.redAccent : Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isCustom ? Icons.radio_button_checked : Icons.radio_button_off,
                              size: 16,
                              color: isCustom ? Colors.redAccent : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            const Text('Custom Rejection Note...', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                    if (isCustom) ...[
                      const SizedBox(height: 6),
                      TextField(
                        controller: customCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Enter specific reason for rejecting this document...',
                          hintStyle: const TextStyle(fontSize: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.all(10),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.send_rounded, size: 16),
                label: const Text('Confirm Rejection'),
                onPressed: () {
                  final finalReason = isCustom && customCtrl.text.trim().isNotEmpty
                      ? customCtrl.text.trim()
                      : selectedReason;
                  Navigator.pop(ctx);
                  onSelected(finalReason);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // ===================== FULL IMAGE ZOOM MODAL =====================

  void _showDocumentPreviewDialog({
    required String title,
    required String url,
    VoidCallback? onApprove,
    VoidCallback? onReject,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          width: 850,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppTheme.blueLight, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.document_scanner_rounded, color: AppTheme.primaryBlue, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const Text('High-Resolution Inspection • Scroll/Pinch to Zoom', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Flexible(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: InteractiveViewer(
                      panEnabled: true,
                      boundaryMargin: const EdgeInsets.all(20),
                      minScale: 0.8,
                      maxScale: 4.0,
                      child: Center(
                        child: _buildUniversalImage(url),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: const Text('Download Original'),
                    onPressed: () => downloadWebFile(dataOrUrl: url, fileName: '$title.jpg'),
                  ),
                  Row(
                    children: [
                      if (onReject != null) ...[
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent),
                          ),
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: const Text('Reject Document'),
                          onPressed: () {
                            Navigator.pop(ctx);
                            onReject();
                          },
                        ),
                        const SizedBox(width: 10),
                      ],
                      if (onApprove != null)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.emeraldGreen,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.check_circle_rounded, size: 16),
                          label: const Text('Approve Document'),
                          onPressed: () {
                            Navigator.pop(ctx);
                            onApprove();
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUniversalImage(String url) {
    if (url.startsWith('data:image')) {
      return Image.memory(
        base64Decode(url.split(',').last),
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded, size: 48, color: Colors.grey),
      );
    } else if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.contain,
        loadingBuilder: (_, child, p) => p == null ? child : const Center(child: CircularProgressIndicator()),
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded, size: 48, color: Colors.grey),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.file_present_rounded, size: 48, color: AppTheme.primaryBlue),
            const SizedBox(height: 8),
            Text(url, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      );
    }
  }

  // ===================== MAIN DIALOG BUILDER =====================

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    // Auto-update caregiver if matching ID found in live provider
    final liveIndex = provider.caregivers.indexWhere((c) => c.id == _cg.id || c.membershipNumber == _cg.membershipNumber);
    if (liveIndex != -1) {
      _cg = provider.caregivers[liveIndex];
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Container(
        width: 1140,
        height: MediaQuery.of(context).size.height * 0.92,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            // Top Master Header
            _buildTopMasterHeader(provider),

            // Tab Bar
            _buildTabBar(),

            // Tab Views Container
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildTab1PersonalDetails(),
                  _buildTab2QualificationsAndVerifications(provider),
                  _buildTab3LanguageAndClinicalSkills(),
                  _buildTab4CareDutyAndRosterHistory(provider),
                  _buildTab5EarningsAndBankFinance(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== HEADER =====================

  Widget _buildTopMasterHeader(AdminProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: AppTheme.slate900,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          // Circular Avatar with photo or fallback
          Stack(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.slate800,
                  border: Border.all(
                    color: _cg.isVerifiedMember ? AppTheme.emeraldGreen : AppTheme.slate700,
                    width: 2.5,
                  ),
                ),
                child: ClipOval(
                  child: _cg.profileImageUrl != null && _cg.profileImageUrl!.isNotEmpty
                      ? _buildUniversalImage(_cg.profileImageUrl!)
                      : Center(
                          child: Text(
                            _cg.name.isNotEmpty ? _cg.name[0].toUpperCase() : 'P',
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        ),
                ),
              ),
              if (_cg.isVerifiedMember)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: AppTheme.emeraldGreen, shape: BoxShape.circle),
                    child: const Icon(Icons.verified_rounded, size: 14, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),

          // Name, Membership, Tier & Approval Badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _cg.name,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.4)),
                      ),
                      child: Text(
                        _cg.membershipNumber,
                        style: const TextStyle(color: Color(0xFF93C5FD), fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _buildApprovalBadge(_cg.approvalStatus),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _cg.tierLabel,
                      style: const TextStyle(color: AppTheme.slate400, fontSize: 12),
                    ),
                    const Text(' • ', style: TextStyle(color: AppTheme.slate600)),
                    Text(
                      _cg.district,
                      style: const TextStyle(color: AppTheme.slate400, fontSize: 12),
                    ),
                    const Text(' • ', style: TextStyle(color: AppTheme.slate600)),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFBBF24)),
                        const SizedBox(width: 3),
                        Text(
                          _cg.rating.toStringAsFixed(1),
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Quick Shift Status Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.slate800,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.slate700),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _currentStatus,
                dropdownColor: AppTheme.slate800,
                style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                icon: const Icon(Icons.arrow_drop_down, color: AppTheme.slate400),
                items: const [
                  DropdownMenuItem(value: 'available', child: Text('🟢 Available for Dispatch')),
                  DropdownMenuItem(value: 'on_duty', child: Text('🔵 On Active Duty')),
                  DropdownMenuItem(value: 'on_leave', child: Text('🟡 On Approved Leave')),
                  DropdownMenuItem(value: 'inactive', child: Text('⚪ Inactive / Suspended')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _currentStatus = val);
                    provider.updateCaregiver(_cg.copyWith(status: val));
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Quick Master Member Approval Actions
          if (!_cg.isApproved) ...[
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emeraldGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.check_circle_rounded, size: 16),
              label: const Text('Approve Staff', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              onPressed: () {
                provider.approveAllVerificationItems(_cg.membershipNumber);
                _showToast('${_cg.name} approved and activated as verified staff!', AppTheme.emeraldGreen);
              },
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.rose500,
                side: const BorderSide(color: AppTheme.rose500),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.cancel_rounded, size: 16),
              label: const Text('Reject Staff', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              onPressed: () {
                _promptRejectionReason(
                  targetName: '${_cg.name} Registration',
                  onSelected: (reason) {
                    provider.updateCaregiver(_cg.copyWith(
                      approvalStatus: 'rejected',
                      rejectionReason: reason,
                    ));
                    _showToast('${_cg.name} registration marked as rejected.', AppTheme.rose500);
                  },
                );
              },
            ),
            const SizedBox(width: 12),
          ],

          // Close Dialog Icon Button
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppTheme.slate400),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Close Profile Dialog',
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalBadge(String status) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (status) {
      case 'approved':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF15803D);
        label = 'APPROVED';
        icon = Icons.check_circle_rounded;
        break;
      case 'rejected':
        bg = const Color(0xFFFFE4E6);
        fg = const Color(0xFFBE123C);
        label = 'REJECTED';
        icon = Icons.cancel_rounded;
        break;
      default:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        label = 'PENDING APPROVAL';
        icon = Icons.hourglass_top_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  // ===================== TAB BAR =====================

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.slate100,
        border: Border(bottom: BorderSide(color: AppTheme.slate200)),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryBlue,
        unselectedLabelColor: AppTheme.slate600,
        indicatorColor: AppTheme.primaryBlue,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        tabs: [
          const Tab(
            icon: Icon(Icons.person_rounded, size: 18),
            text: '1. Personal & Contact',
          ),
          Tab(
            icon: const Icon(Icons.school_rounded, size: 18),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('2. Qualifications'),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: _cg.approvedVerificationCount == 6 ? AppTheme.emerald500 : AppTheme.amber500,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_cg.approvedVerificationCount}/6',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Tab(
            icon: const Icon(Icons.translate_rounded, size: 18),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('3. Language & Skills'),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(color: AppTheme.primaryBlue, borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    '${_clinicalSkills.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const Tab(
            icon: Icon(Icons.calendar_month_rounded, size: 18),
            text: '4. Care Duty & Shifts',
          ),
          const Tab(
            icon: Icon(Icons.account_balance_rounded, size: 18),
            text: '5. Earnings & Bank Finance',
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 1: PERSONAL DETAILS & CONTACT
  // =========================================================================

  Widget _buildTab1PersonalDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: Profile Photo Management Toolbar Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.slate50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.slate200),
            ),
            child: Row(
              children: [
                // Circular Preview
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.slate200,
                    border: Border.all(color: AppTheme.primaryBlue, width: 2),
                  ),
                  child: ClipOval(
                    child: _cg.profileImageUrl != null && _cg.profileImageUrl!.isNotEmpty
                        ? _buildUniversalImage(_cg.profileImageUrl!)
                        : const Icon(Icons.person, size: 40, color: AppTheme.slate500),
                  ),
                ),
                const SizedBox(width: 18),

                // Info & Status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('Profile Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(width: 10),
                          _buildVerificationStatusChip(_cg.profileImageStatus),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'High-resolution profile picture used on staff badge, mobile app, and patient dispatch cards.',
                        style: TextStyle(fontSize: 12, color: AppTheme.slate600),
                      ),
                      const SizedBox(height: 10),

                      // Tool Buttons: Crop, Upload, Download, Approve, Reject
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            icon: const Icon(Icons.crop_rotate_rounded, size: 15),
                            label: const Text('Crop & Frame Photo', style: TextStyle(fontSize: 12)),
                            onPressed: () {
                              if (_cg.profileImageUrl != null && _cg.profileImageUrl!.isNotEmpty) {
                                _openCropDialog(imageSource: _cg.profileImageUrl!);
                              } else {
                                _pickAndUploadPhotoFromPC();
                              }
                            },
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            icon: const Icon(Icons.upload_file_rounded, size: 15),
                            label: const Text('Upload from PC', style: TextStyle(fontSize: 12)),
                            onPressed: _pickAndUploadPhotoFromPC,
                          ),
                          if (_cg.profileImageUrl != null && _cg.profileImageUrl!.isNotEmpty) ...[
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              icon: const Icon(Icons.download_rounded, size: 15),
                              label: const Text('Download', style: TextStyle(fontSize: 12)),
                              onPressed: _downloadProfilePhoto,
                            ),
                            if (_cg.profileImageStatus != 'approved')
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.emeraldGreen,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                icon: const Icon(Icons.check_rounded, size: 15),
                                label: const Text('Approve Photo', style: TextStyle(fontSize: 12)),
                                onPressed: () {
                                  context.read<AdminProvider>().updateVerificationItemStatus(
                                        _cg.membershipNumber,
                                        'profile_image',
                                        'approved',
                                      );
                                  _syncLatestFromProvider();
                                },
                              ),
                            if (_cg.profileImageStatus != 'rejected')
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.rose500,
                                  side: const BorderSide(color: AppTheme.rose500),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                icon: const Icon(Icons.close_rounded, size: 15),
                                label: const Text('Reject Photo', style: TextStyle(fontSize: 12)),
                                onPressed: () {
                                  _promptRejectionReason(
                                    targetName: 'Profile Photo',
                                    onSelected: (reason) {
                                      context.read<AdminProvider>().updateVerificationItemStatus(
                                            _cg.membershipNumber,
                                            'profile_image',
                                            'rejected',
                                            rejectionReason: reason,
                                          );
                                      _syncLatestFromProvider();
                                    },
                                  );
                                },
                              ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section 2: Personal Form Grid
          _buildFormSectionHeader('Personal Identity & Bio', Icons.badge_outlined),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildTextField('Full Name', _nameCtrl, Icons.person_outline),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildTextField('National Identity Card (NIC)', _nicCtrl, Icons.credit_card_outlined),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildGenderDropdown(),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildTextField('Age (Years)', _ageCtrl, Icons.cake_outlined, keyboardType: TextInputType.number),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Section 3: Contact & Geographical Location
          _buildFormSectionHeader('Contact & Operational Zone', Icons.location_on_outlined),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: _buildTextField('Mobile Phone', _phoneCtrl, Icons.phone_outlined)),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline, color: AppTheme.whatsappGreen),
                      tooltip: 'Message on WhatsApp',
                      onPressed: () {
                        WhatsAppHelper.launchWhatsApp(
                          context,
                          _phoneCtrl.text,
                          'Hello ${_nameCtrl.text}, contacting you from Prime Life Care administration regarding your staff account.',
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildTextField('Email Address', _emailCtrl, Icons.email_outlined),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildDistrictDropdown(),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildTextField('Permanent Residential Address', _addressCtrl, Icons.home_outlined, maxLines: 2),
          const SizedBox(height: 14),

          // Section 4: Emergency Contacts & Clinical Summary
          _buildFormSectionHeader('Emergency Contact & Professional Bio', Icons.health_and_safety_outlined),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField('Emergency Contact Name', _emergencyNameCtrl, Icons.contacts_outlined),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildTextField('Emergency Contact Phone', _emergencyPhoneCtrl, Icons.phone_in_talk_outlined),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildTextField('Professional Biography & Clinical Overview', _bioCtrl, Icons.description_outlined, maxLines: 3),
          const SizedBox(height: 24),

          // Save Button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emeraldGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: _isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save_rounded),
              label: const Text('Save Personal Details', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: _isSaving ? null : _savePersonalDetails,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 2: QUALIFICATIONS & VERIFICATIONS
  // =========================================================================

  Widget _buildTab2QualificationsAndVerifications(AdminProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Clinical Tier & Rank
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildTierDropdown(),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: _buildTextField('Qualification Title / Label', _tierLabelCtrl, Icons.badge_outlined),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildTextField('Experience Years', _experienceCtrl, Icons.timeline_rounded),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Row 2: Compliance Checklist Toggles
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.slate50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.slate200),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: SwitchListTile(
                      title: const Text('Police Clearance Verified', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Criminal record check on file', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      value: _isPoliceVerified,
                      activeColor: AppTheme.emeraldGreen,
                      onChanged: (val) => setState(() => _isPoliceVerified = val),
                    ),
                  ),
                ),
                const VerticalDivider(width: 24),
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: SwitchListTile(
                      title: const Text('Medical Fitness Cleared', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: const Text('TB & infectious disease screening', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      value: _isMedicalCleared,
                      activeColor: AppTheme.primaryBlue,
                      onChanged: (val) => setState(() => _isMedicalCleared = val),
                    ),
                  ),
                ),
                const VerticalDivider(width: 24),
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: SwitchListTile(
                      title: const Text('CPR / First Aid Certified', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: const Text('St. John or Red Cross compliant', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      value: _isCprCertified,
                      activeColor: AppTheme.amber500,
                      onChanged: (val) => setState(() => _isCprCertified = val),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section: 6-Item Verification Pipeline
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('6-Step Document Verification Pipeline', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    '${_cg.approvedVerificationCount} of 6 credentials verified & active (${(_cg.verificationProgress * 100).toInt()}%)',
                    style: const TextStyle(fontSize: 12, color: AppTheme.slate600),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.emeraldGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                icon: const Icon(Icons.verified_user_rounded, size: 16),
                label: const Text('Master Approve All 6 Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                onPressed: () {
                  provider.approveAllVerificationItems(_cg.membershipNumber);
                  _syncLatestFromProvider();
                  _showToast('All 6 documents verified & approved!', AppTheme.emeraldGreen);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _cg.verificationProgress,
              backgroundColor: AppTheme.slate200,
              valueColor: AlwaysStoppedAnimation<Color>(
                _cg.approvedVerificationCount == 6 ? AppTheme.emeraldGreen : AppTheme.primaryBlue,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),

          // Grid of 6 Verification Items
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.35,
            children: [
              _buildVerificationPipelineCard(
                title: '1. Profile Photo',
                itemKey: 'profile_image',
                status: _cg.profileImageStatus,
                url: _cg.profileImageUrl,
                icon: Icons.account_circle_rounded,
                provider: provider,
              ),
              _buildVerificationPipelineCard(
                title: '2. NIC Front Side',
                itemKey: 'nic_front',
                status: _cg.nicFrontStatus,
                url: _cg.nicFrontUrl,
                icon: Icons.badge_outlined,
                provider: provider,
              ),
              _buildVerificationPipelineCard(
                title: '3. NIC Back Side',
                itemKey: 'nic_back',
                status: _cg.nicBackStatus,
                url: _cg.nicBackUrl,
                icon: Icons.credit_card_outlined,
                provider: provider,
              ),
              _buildVerificationPipelineCard(
                title: '4. Police Clearance Report',
                itemKey: 'police_report',
                status: _cg.policeReportStatus,
                url: _cg.policeReportUrl,
                icon: Icons.policy_outlined,
                provider: provider,
              ),
              _buildVerificationPipelineCard(
                title: '5. NVQ / Nursing Certificate',
                itemKey: 'qualification_cert',
                status: _cg.qualificationCertStatus,
                url: _cg.qualificationCertUrl,
                icon: Icons.school_outlined,
                provider: provider,
                isQualificationCert: true,
              ),
              _buildVerificationPipelineCard(
                title: '6. Face Liveness Verification',
                itemKey: 'face_verification',
                status: _cg.faceVerificationStatus,
                url: _cg.faceVerificationSnapshotUrl,
                icon: Icons.face_retouching_natural_rounded,
                provider: provider,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Save Button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emeraldGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: _isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save_rounded),
              label: const Text('Save Qualification Settings', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: _isSaving ? null : _saveQualifications,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationPipelineCard({
    required String title,
    required String itemKey,
    required String status,
    required String? url,
    required IconData icon,
    required AdminProvider provider,
    bool isQualificationCert = false,
  }) {
    final bool hasDoc = url != null && url.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: status == 'approved'
              ? AppTheme.emerald200
              : (status == 'rejected' ? AppTheme.rose200 : AppTheme.slate200),
          width: status == 'approved' ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon + Title + Status Chip
          Row(
            children: [
              Icon(icon, size: 16, color: AppTheme.primaryBlue),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildVerificationStatusChip(status),
            ],
          ),
          const SizedBox(height: 8),

          // Middle: Thumbnail Preview or Placeholder
          Expanded(
            child: InkWell(
              onTap: hasDoc
                  ? () => _showDocumentPreviewDialog(
                        title: title,
                        url: url,
                        onApprove: () => provider.updateVerificationItemStatus(
                          _cg.membershipNumber,
                          itemKey,
                          'approved',
                        ),
                        onReject: () => _promptRejectionReason(
                          targetName: title,
                          onSelected: (reason) => provider.updateVerificationItemStatus(
                            _cg.membershipNumber,
                            itemKey,
                            'rejected',
                            rejectionReason: reason,
                          ),
                        ),
                      )
                  : null,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.slate50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.slate200),
                ),
                child: hasDoc
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _buildUniversalImage(url),
                            Container(
                              alignment: Alignment.bottomRight,
                              padding: const EdgeInsets.all(4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.zoom_in, color: Colors.white, size: 12),
                                    SizedBox(width: 3),
                                    Text('Inspect', style: TextStyle(color: Colors.white, fontSize: 10)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.upload_file_rounded, size: 24, color: AppTheme.slate400),
                            const SizedBox(height: 4),
                            Text('No file uploaded', style: TextStyle(fontSize: 10, color: AppTheme.slate500)),
                          ],
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Action Toolbar: Quick Approve / Reject / Upgrade
          Row(
            children: [
              if (status != 'approved')
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.emeraldGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    icon: const Icon(Icons.check, size: 14),
                    label: const Text('Approve', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      provider.updateVerificationItemStatus(
                        _cg.membershipNumber,
                        itemKey,
                        'approved',
                      );
                      _syncLatestFromProvider();
                    },
                  ),
                ),
              if (status != 'approved') const SizedBox(width: 6),
              if (status != 'rejected')
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.rose500,
                      side: const BorderSide(color: AppTheme.rose500),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    icon: const Icon(Icons.close, size: 14),
                    label: const Text('Reject', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      _promptRejectionReason(
                        targetName: title,
                        onSelected: (reason) {
                          provider.updateVerificationItemStatus(
                            _cg.membershipNumber,
                            itemKey,
                            'rejected',
                            rejectionReason: reason,
                          );
                          _syncLatestFromProvider();
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 3: LANGUAGE & CLINICAL SKILLS
  // =========================================================================

  Widget _buildTab3LanguageAndClinicalSkills() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: Language Proficiencies
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Language Proficiency Controls', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Set conversational, writing and comprehension capability for patient matching.', style: TextStyle(fontSize: 12, color: AppTheme.slate600)),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add Language', style: TextStyle(fontSize: 12)),
                onPressed: _showAddLanguageDialog,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // List of Languages
          ..._languages.asMap().entries.map((entry) {
            final idx = entry.key;
            final lang = entry.value;
            return _buildLanguageCard(lang, idx);
          }),
          const SizedBox(height: 24),

          // Section 2: Clinical Nursing Skills Checklist
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Specialized Clinical Nursing & Bedside Skills', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Check off authorized clinical competencies performed by this staff member.', style: TextStyle(fontSize: 12, color: AppTheme.slate600)),
                ],
              ),
              Row(
                children: [
                  SizedBox(
                    width: 220,
                    child: TextField(
                      controller: _customSkillCtrl,
                      decoration: InputDecoration(
                        hintText: 'Add custom skill...',
                        hintStyle: const TextStyle(fontSize: 12),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: AppTheme.primaryBlue),
                    tooltip: 'Add Custom Skill',
                    onPressed: () {
                      final text = _customSkillCtrl.text.trim();
                      if (text.isNotEmpty && !_clinicalSkills.contains(text)) {
                        setState(() {
                          _clinicalSkills.add(text);
                          _customSkillCtrl.clear();
                        });
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Chips Wrap
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.slate50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.slate200),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 10,
              children: <Widget>[
                ...allPresetClinicalSkills.map((skill) {
                  final isSelected = _clinicalSkills.contains(skill);
                  return FilterChip(
                    label: Text(skill, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryBlue.withOpacity(0.15),
                    checkmarkColor: AppTheme.primaryBlue,
                    backgroundColor: Colors.white,
                    side: BorderSide(color: isSelected ? AppTheme.primaryBlue : AppTheme.slate300),
                    onSelected: (checked) {
                      setState(() {
                        if (checked) {
                          _clinicalSkills.add(skill);
                        } else {
                          _clinicalSkills.remove(skill);
                        }
                      });
                    },
                  );
                }),
                ..._clinicalSkills.where((s) => !allPresetClinicalSkills.contains(s)).map((customSkill) {
                  return Chip(
                    label: Text(customSkill, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                    backgroundColor: AppTheme.blueLight,
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () => setState(() => _clinicalSkills.remove(customSkill)),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Save Button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emeraldGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: _isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save_rounded),
              label: const Text('Save Languages & Clinical Skills', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: _isSaving ? null : _saveLanguagesAndSkills,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageCard(Map<String, dynamic> lang, int index) {
    final name = (lang['languageName'] ?? 'Language').toString();
    int spk = (lang['speakingPercent'] as num?)?.toInt() ?? 80;
    int wrt = (lang['writingPercent'] as num?)?.toInt() ?? 70;
    int und = (lang['understandingPercent'] as num?)?.toInt() ?? 85;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.record_voice_over_rounded, size: 18, color: AppTheme.primaryBlue),
                  const SizedBox(width: 8),
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(width: 10),
                  _buildProficiencyBadge(spk),
                ],
              ),
              if (_languages.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.rose500),
                  tooltip: 'Remove Language',
                  onPressed: () {
                    setState(() => _languages.removeAt(index));
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Speaking Slider
              Expanded(
                child: _buildSkillSlider(
                  label: 'Speaking: $spk%',
                  value: spk.toDouble(),
                  onChanged: (val) {
                    setState(() {
                      lang['speakingPercent'] = val.toInt();
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),

              // Writing Slider
              Expanded(
                child: _buildSkillSlider(
                  label: 'Writing: $wrt%',
                  value: wrt.toDouble(),
                  onChanged: (val) {
                    setState(() {
                      lang['writingPercent'] = val.toInt();
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),

              // Understanding Slider
              Expanded(
                child: _buildSkillSlider(
                  label: 'Understanding: $und%',
                  value: und.toDouble(),
                  onChanged: (val) {
                    setState(() {
                      lang['understandingPercent'] = val.toInt();
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkillSlider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.slate700)),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            min: 0,
            max: 100,
            divisions: 20,
            activeColor: AppTheme.primaryBlue,
            inactiveColor: AppTheme.slate200,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildProficiencyBadge(int percent) {
    String label;
    Color color;
    if (percent >= 80) {
      label = 'Fluent / Native';
      color = AppTheme.emeraldGreen;
    } else if (percent >= 50) {
      label = 'Working Proficiency';
      color = AppTheme.primaryBlue;
    } else {
      label = 'Basic';
      color = AppTheme.slate500;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.bold)),
    );
  }

  void _showAddLanguageDialog() {
    _customLangCtrl.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Language', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: TextField(
          controller: _customLangCtrl,
          decoration: const InputDecoration(
            labelText: 'Language Name (e.g. German, Japanese, Arabic)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white),
            onPressed: () {
              final text = _customLangCtrl.text.trim();
              if (text.isNotEmpty) {
                setState(() {
                  _languages.add({
                    'languageName': text,
                    'languageCode': text.substring(0, text.length >= 2 ? 2 : text.length).toLowerCase(),
                    'speakingPercent': 80,
                    'writingPercent': 70,
                    'understandingPercent': 85,
                  });
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 4: CARE DUTY & ROSTER HISTORY
  // =========================================================================

  Widget _buildTab4CareDutyAndRosterHistory(AdminProvider provider) {
    // Filter actual bookings from provider matching this caregiver
    final staffBookings = provider.bookings.where((b) {
      return b.assignedCaregiverId == _cg.id ||
          b.assignedCaregiverId == _cg.membershipNumber ||
          b.assignedCaregiverName == _cg.name;
    }).toList();

    // Active duty booking if any
    final BookingModel? activeBooking = staffBookings.cast<BookingModel?>().firstWhere(
      (b) => b != null && (b.status == 'in_progress' || b.status == 'caregiver_assigned'),
      orElse: () => null,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Duty Status Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _cg.status == 'on_duty' ? const Color(0xFFEFF6FF) : AppTheme.slate50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _cg.status == 'on_duty' ? const Color(0xFFBFDBFE) : AppTheme.slate200,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _cg.status == 'on_duty' ? AppTheme.primaryBlue : AppTheme.slate400,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _cg.status == 'on_duty' ? Icons.medical_services_rounded : Icons.check_circle_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _cg.status == 'on_duty'
                                ? 'CURRENTLY ON ACTIVE BEDSIDE DUTY'
                                : 'CURRENT STATUS: ${_cg.status.toUpperCase()}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: _cg.status == 'on_duty' ? AppTheme.primaryBlue : AppTheme.slate800,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _cg.status == 'on_duty' ? const Color(0xFFDBEAFE) : AppTheme.slate200,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _cg.status == 'on_duty' ? 'DISPATCHED' : 'STANDBY',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _cg.status == 'on_duty' ? AppTheme.primaryBlue : AppTheme.slate700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (activeBooking != null) ...[
                        Text(
                          'Assigned to Patient: ${activeBooking.patientName} (${activeBooking.serviceName} • ${activeBooking.shiftType})',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppTheme.slate800),
                        ),
                        Text(
                          'Booking Ref: #${activeBooking.bookingCode.isNotEmpty ? activeBooking.bookingCode : activeBooking.id} • Location: ${activeBooking.address}',
                          style: const TextStyle(fontSize: 11.5, color: AppTheme.slate600),
                        ),
                      ] else ...[
                        Text(
                          _cg.status == 'available'
                              ? 'Staff member is ready and available for automated emergency or scheduled dispatch.'
                              : 'No active clinical booking currently assigned.',
                          style: const TextStyle(fontSize: 12, color: AppTheme.slate600),
                        ),
                      ],
                    ],
                  ),
                ),
                if (activeBooking != null) ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.rose500,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    icon: const Icon(Icons.person_remove_rounded, size: 16),
                    label: const Text('Unassign Duty', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      provider.unassignCaregiver(activeBooking.id);
                      _syncLatestFromProvider();
                      _showToast('Duty unassigned successfully.', AppTheme.primaryBlue);
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Real Bookings & Duty History Table
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Live Shift & Care Duty History (${staffBookings.length} Total)',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                'Completed Shifts: ${_cg.completedShifts}',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (staffBookings.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.slate200),
              ),
              child: const Column(
                children: [
                  Icon(Icons.event_busy_rounded, size: 48, color: AppTheme.slate400),
                  SizedBox(height: 10),
                  Text('No shift records found for this caregiver', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  SizedBox(height: 4),
                  Text(
                    'When bookings are dispatched to this staff member in Admin Bookings, shift timelines and patient vitals will automatically synchronize here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppTheme.slate500),
                  ),
                ],
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.slate200),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(AppTheme.slate50),
                  columns: const [
                    DataColumn(label: Text('Booking Ref', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('Patient / Family', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('Service Package', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('Shift Dates', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('Total LKR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  ],
                  rows: staffBookings.map((b) {
                    final ref = b.bookingCode.isNotEmpty ? b.bookingCode : b.id;
                    return DataRow(
                      cells: [
                        DataCell(Text('#$ref', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue))),
                        DataCell(Text(b.patientName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                        DataCell(Text('${b.serviceName} (${b.staffTierName})', style: const TextStyle(fontSize: 12))),
                        DataCell(Text('${b.startDate} (${b.durationDays}d)', style: const TextStyle(fontSize: 12))),
                        DataCell(_buildBookingStatusBadge(b.status)),
                        DataCell(Text('LKR ${NumberFormat('#,###').format(b.totalCostLKR)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBookingStatusBadge(String status) {
    Color bg;
    Color fg;
    String label = status.toUpperCase();

    switch (status.toLowerCase()) {
      case 'completed':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF15803D);
        break;
      case 'in_progress':
      case 'caregiver_assigned':
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF1D4ED8);
        label = 'ON DUTY';
        break;
      case 'cancelled':
        bg = const Color(0xFFFFE4E6);
        fg = const Color(0xFFBE123C);
        break;
      default:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  // =========================================================================
  // TAB 5: EARNINGS & BANK FINANCE
  // =========================================================================

  Widget _buildTab5EarningsAndBankFinance() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Shift Rates & Accumulated Totals
          Row(
            children: [
              Expanded(
                child: _buildTextField('Daily Shift Rate (LKR)', _dailyRateCtrl, Icons.payments_outlined, keyboardType: TextInputType.number),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildTextField('Hourly Overtime Rate (LKR)', _hourlyRateCtrl, Icons.timer_outlined, keyboardType: TextInputType.number),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildTextField('Total Accumulated Earnings (LKR)', _totalEarningsCtrl, Icons.account_balance_wallet_outlined, keyboardType: TextInputType.number),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildTextField('Pending Payout Balance (LKR)', _pendingPayoutCtrl, Icons.pending_actions_outlined, keyboardType: TextInputType.number),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Row 2: Sri Lankan Bank Account Information
          _buildFormSectionHeader('Sri Lankan Bank Account Details', Icons.account_balance_rounded),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.slate50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.slate200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildBankDropdown(),
                    ),
                    if (_bankName == 'Other / Cooperative Bank') ...[
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 2,
                        child: _buildTextField('Custom Bank Name', _customBankCtrl, Icons.account_balance_outlined),
                      ),
                    ],
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 2,
                      child: _buildTextField('Branch Name / Location', _branchCtrl, Icons.storefront_outlined),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildTextField('Bank Account Number', _accNumCtrl, Icons.numbers_outlined),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 2,
                      child: _buildTextField('Account Holder Name', _accHolderCtrl, Icons.badge_outlined),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 2,
                      child: _buildPayoutCycleDropdown(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Material(
                  color: Colors.transparent,
                  child: SwitchListTile(
                    title: const Text('Bank Account Verified by Operations Lead', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Direct deposits and weekly shift payouts are authorized for this account', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    value: _bankIsVerified,
                    activeColor: AppTheme.emeraldGreen,
                    onChanged: (val) => setState(() => _bankIsVerified = val),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Save Button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emeraldGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: _isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save_rounded),
              label: const Text('Save Earnings & Bank Details', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: _isSaving ? null : _saveEarningsAndBank,
            ),
          ),
        ],
      ),
    );
  }

  // ===================== FORM HELPERS & WIDGETS =====================

  Widget _buildFormSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryBlue),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.slate900)),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.slate700)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: AppTheme.slate400),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.slate300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.slate300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Gender', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.slate700)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _selectedGender,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.slate300)),
          ),
          items: const [
            DropdownMenuItem(value: 'Female', child: Text('Female', style: TextStyle(fontSize: 13))),
            DropdownMenuItem(value: 'Male', child: Text('Male', style: TextStyle(fontSize: 13))),
            DropdownMenuItem(value: 'Other', child: Text('Other', style: TextStyle(fontSize: 13))),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _selectedGender = val);
          },
        ),
      ],
    );
  }

  Widget _buildDistrictDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('District / Zone', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.slate700)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _selectedDistrict,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.slate300)),
          ),
          items: sriLankanDistricts.map((d) {
            return DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 13)));
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedDistrict = val);
          },
        ),
      ],
    );
  }

  Widget _buildTierDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Caregiver Clinical Tier', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.slate700)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _selectedTier,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.slate300)),
          ),
          items: const [
            DropdownMenuItem(value: 'basic_aide', child: Text('Basic Companion Aide', style: TextStyle(fontSize: 13))),
            DropdownMenuItem(value: 'nurse_assistant', child: Text('Nurse Assistant', style: TextStyle(fontSize: 13))),
            DropdownMenuItem(value: 'nvq_4_caregiver', child: Text('NVQ 4 Certified Caregiver', style: TextStyle(fontSize: 13))),
            DropdownMenuItem(value: 'nvq_5_nurse', child: Text('NVQ 5 Senior Clinical Nurse', style: TextStyle(fontSize: 13))),
            DropdownMenuItem(value: 'doctor', child: Text('SLMC Registered Medical Officer (Doctor)', style: TextStyle(fontSize: 13))),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedTier = val;
                switch (val) {
                  case 'basic_aide':
                    _tierLabelCtrl.text = 'Basic Companion Aide';
                    break;
                  case 'nurse_assistant':
                    _tierLabelCtrl.text = 'Nurse Assistant';
                    break;
                  case 'nvq_4_caregiver':
                    _tierLabelCtrl.text = 'NVQ 4 Certified Caregiver';
                    break;
                  case 'nvq_5_nurse':
                    _tierLabelCtrl.text = 'NVQ 5 Senior Clinical Nurse';
                    break;
                  case 'doctor':
                    _tierLabelCtrl.text = 'SLMC Registered Medical Officer';
                    break;
                }
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildBankDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Bank Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.slate700)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _bankName,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.slate300)),
          ),
          items: sriLankanBanks.map((b) {
            return DropdownMenuItem(value: b['name']!, child: Text(b['name']!, style: const TextStyle(fontSize: 13)));
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _bankName = val);
          },
        ),
      ],
    );
  }

  Widget _buildPayoutCycleDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Payout Cycle', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.slate700)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _payoutCycle,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.slate300)),
          ),
          items: const [
            DropdownMenuItem(value: 'Weekly Every Monday', child: Text('Weekly (Every Monday)', style: TextStyle(fontSize: 13))),
            DropdownMenuItem(value: 'Bi-Weekly (1st & 15th)', child: Text('Bi-Weekly (1st & 15th)', style: TextStyle(fontSize: 13))),
            DropdownMenuItem(value: 'Monthly (Last Day)', child: Text('Monthly (Last Working Day)', style: TextStyle(fontSize: 13))),
            DropdownMenuItem(value: 'Immediate on Completion', child: Text('Immediate on Shift Completion', style: TextStyle(fontSize: 13))),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _payoutCycle = val);
          },
        ),
      ],
    );
  }

  Widget _buildVerificationStatusChip(String status) {
    Color bg;
    Color fg;
    String label;
    switch (status) {
      case 'approved':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF15803D);
        label = 'Approved';
        break;
      case 'pending':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        label = 'Pending Review';
        break;
      case 'rejected':
        bg = const Color(0xFFFFE4E6);
        fg = const Color(0xFFBE123C);
        label = 'Rejected';
        break;
      default:
        bg = AppTheme.slate200;
        fg = AppTheme.slate600;
        label = 'Missing';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 10.5, fontWeight: FontWeight.bold)),
    );
  }
}
