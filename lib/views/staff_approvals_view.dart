import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../models/caregiver_model.dart';
import '../theme/app_theme.dart';
import '../widgets/whatsapp_button.dart';
import '../utils/web_file_utils.dart';
import '../widgets/image_cropper_dialog.dart';
import '../widgets/caregiver_profile_management_dialog.dart';

class StaffApprovalsView extends StatefulWidget {
  const StaffApprovalsView({super.key});

  @override
  State<StaffApprovalsView> createState() => _StaffApprovalsViewState();
}

class _StaffApprovalsViewState extends State<StaffApprovalsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedDistrict = 'all';

  // Default rejection reasons
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
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final allStaff = provider.caregivers;

    // Filter staff by search & district
    final filteredStaff = allStaff.where((c) {
      if (_selectedDistrict != 'all' && c.district.toLowerCase() != _selectedDistrict.toLowerCase()) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return c.name.toLowerCase().contains(q) ||
            c.membershipNumber.toLowerCase().contains(q) ||
            c.phone.toLowerCase().contains(q) ||
            (c.nic ?? '').toLowerCase().contains(q) ||
            c.district.toLowerCase().contains(q) ||
            c.tierLabel.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    // 1. New Registrations: pending initial verification (not yet fully approved)
    final newRegistrations = filteredStaff.where((c) {
      return !c.isVerifiedMember && c.approvalStatus != 'approved';
    }).toList();

    // 2. Qualification Upgrades: already verified/approved members who submitted a new qualification cert for a level-up
    final qualificationUpgrades = filteredStaff.where((c) {
      return (c.isVerifiedMember || c.approvalStatus == 'approved') && c.hasPendingQualificationUpgrade;
    }).toList();

    // 3. Approved Members: verified, active caregivers
    final approvedMembers = filteredStaff.where((c) {
      return c.isVerifiedMember || c.approvalStatus == 'approved';
    }).toList();

    final districts = {'all', ...allStaff.map((c) => c.district).where((d) => d.isNotEmpty)};

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Wrap to prevent screen clipping
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.blueLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.verified_user_rounded, color: AppTheme.primaryBlue, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Staff Applications & Approvals',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.slate900,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Caregiver applications, credential verification, and qualification level upgrades',
                        style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ),
              // Search & Filter controls
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // District Dropdown
                  Container(
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedDistrict,
                        style: const TextStyle(fontSize: 11.5, color: AppTheme.slate900, fontWeight: FontWeight.w600),
                        items: districts.map((d) {
                          return DropdownMenuItem<String>(
                            value: d,
                            child: Text(d == 'all' ? 'All Districts' : '📍 $d'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedDistrict = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Search Box
                  SizedBox(
                    width: 190,
                    height: 34,
                    child: TextField(
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'Search name, ID, phone...',
                        hintStyle: TextStyle(fontSize: 11.5, color: Colors.grey.shade400),
                        prefixIcon: const Icon(Icons.search_rounded, size: 16),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Tab Bar with Counters
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 1)),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryBlue,
              unselectedLabelColor: AppTheme.slate600,
              indicatorColor: AppTheme.primaryBlue,
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person_add_rounded, size: 15),
                      const SizedBox(width: 6),
                      const Text('New Registrations'),
                      const SizedBox(width: 6),
                      _buildTabBadge(newRegistrations.length, isWarning: newRegistrations.isNotEmpty),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.upgrade_rounded, size: 16),
                      const SizedBox(width: 6),
                      const Text('Qualification Upgrades'),
                      const SizedBox(width: 6),
                      _buildTabBadge(qualificationUpgrades.length, isSuccess: qualificationUpgrades.isNotEmpty),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.verified_rounded, size: 15),
                      const SizedBox(width: 6),
                      const Text('Approved Members'),
                      const SizedBox(width: 6),
                      _buildTabBadge(approvedMembers.length),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Tab Contents
          AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              if (_tabController.index == 0) {
                return _buildNewRegistrationsTab(context, newRegistrations, provider);
              } else if (_tabController.index == 1) {
                return _buildQualificationUpgradesTab(context, qualificationUpgrades, provider);
              } else {
                return _buildApprovedMembersTab(context, approvedMembers, provider);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabBadge(int count, {bool isWarning = false, bool isSuccess = false}) {
    Color bg = AppTheme.slate100;
    Color fg = AppTheme.slate700;
    if (isWarning && count > 0) {
      bg = AppTheme.amber100;
      fg = AppTheme.amber800;
    } else if (isSuccess && count > 0) {
      bg = AppTheme.emerald100;
      fg = AppTheme.emerald800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(
        '$count',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  // ==================== TAB 1: NEW REGISTRATIONS ====================
  Widget _buildNewRegistrationsTab(BuildContext context, List<CaregiverModel> items, AdminProvider provider) {
    if (items.isEmpty) {
      return _buildEmptyState(
        icon: Icons.check_circle_outline_rounded,
        title: 'No Pending New Registrations',
        subtitle: 'All newly applied caregivers have been reviewed and processed.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppTheme.amber50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.amber200),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppTheme.amber800, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'These caregivers registered via the Staff App or Admin and are waiting for document approval. Complete all 6 verification items to activate them.',
                  style: TextStyle(fontSize: 12, color: AppTheme.amber900, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, idx) {
            final cg = items[idx];
            return _buildNewRegistrationCard(context, cg, provider);
          },
        ),
      ],
    );
  }

  Widget _buildNewRegistrationCard(BuildContext context, CaregiverModel cg, AdminProvider provider) {
    final progress = cg.approvedVerificationCount;
    final total = cg.totalVerificationCount;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 1)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile Photo
          _buildAvatar(cg),
          const SizedBox(width: 12),

          // Name & Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      cg.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.slate900),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppTheme.slate100,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        cg.membershipNumber,
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppTheme.slate700),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppTheme.blueLight,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        cg.tierLabel,
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppTheme.primaryBlue),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 10,
                  runSpacing: 2,
                  children: [
                    Text('📞 ${cg.phone}', style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700)),
                    Text('📍 District: ${cg.district}', style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700)),
                    if (cg.nic != null && cg.nic!.isNotEmpty)
                      Text('🪪 NIC: ${cg.nic}', style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700)),
                  ],
                ),
                const SizedBox(height: 8),

                // Verification Items Checklist
                Wrap(
                  spacing: 5,
                  runSpacing: 3,
                  children: [
                    _buildChecklistBadge('Profile Photo', cg.profileImageStatus),
                    _buildChecklistBadge('NIC Front', cg.nicFrontStatus),
                    _buildChecklistBadge('NIC Back', cg.nicBackStatus),
                    _buildChecklistBadge('Police Report', cg.policeReportStatus),
                    _buildChecklistBadge('Qualification', cg.qualificationCertStatus),
                    _buildChecklistBadge('Face Verification', cg.faceVerificationStatus),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Progress and Actions
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: progress == 6 ? AppTheme.emerald50 : AppTheme.amber50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: progress == 6 ? AppTheme.emerald200 : AppTheme.amber200),
                ),
                child: Text(
                  '$progress / $total Approved',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: progress == 6 ? AppTheme.emerald800 : AppTheme.amber800,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  WhatsAppButton(
                    phone: cg.phone,
                    isCompact: true,
                    message: 'Hello ${cg.name}, regarding your Prime Life Care staff registration (${cg.membershipNumber})...',
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton.icon(
                    onPressed: () => _showCaregiverCredentialsReviewDialog(context, cg),
                    icon: const Icon(Icons.rate_review_rounded, size: 14),
                    label: const Text('Review Credentials'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistBadge(String label, String status) {
    Color bg;
    Color fg;
    IconData icon;
    if (status == 'approved') {
      bg = AppTheme.emerald50;
      fg = AppTheme.emerald800;
      icon = Icons.check_circle_rounded;
    } else if (status == 'pending') {
      bg = AppTheme.amber50;
      fg = AppTheme.amber800;
      icon = Icons.hourglass_top_rounded;
    } else if (status == 'rejected') {
      bg = AppTheme.rose50;
      fg = AppTheme.rose800;
      icon = Icons.cancel_rounded;
    } else {
      bg = Colors.grey.shade100;
      fg = Colors.grey.shade600;
      icon = Icons.radio_button_unchecked_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: fg),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: fg)),
        ],
      ),
    );
  }

  // ==================== TAB 2: QUALIFICATION UPGRADES (LEVEL UP) ====================
  Widget _buildQualificationUpgradesTab(BuildContext context, List<CaregiverModel> items, AdminProvider provider) {
    if (items.isEmpty) {
      return _buildEmptyState(
        icon: Icons.workspace_premium_rounded,
        title: 'No Pending Qualification Upgrades',
        subtitle: 'No verified members have uploaded new certificates for level upgrades at this moment.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Crucial policy reminder banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF), // soft blue
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            children: [
              const Icon(Icons.shield_rounded, color: Color(0xFF2563EB), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Verified Member Continuity Policy',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                    ),
                    SizedBox(height: 1),
                    Text(
                      'Verified caregivers remain active and available when submitting new qualification documents. Approving promotes them to a higher tier.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF1E3A8A)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, idx) {
            final cg = items[idx];
            return _buildQualificationUpgradeCard(context, cg, provider);
          },
        ),
      ],
    );
  }

  Widget _buildQualificationUpgradeCard(BuildContext context, CaregiverModel cg, AdminProvider provider) {
    final certItem = cg.verificationItems['qualification_cert'] is Map
        ? cg.verificationItems['qualification_cert'] as Map
        : null;

    final certTitle = certItem?['certTitle'] ?? certItem?['title'] ?? 'Qualification Certificate';
    final certInstitute = certItem?['institute'] ?? 'Accredited Institute';
    final certYear = certItem?['issueYear'] ?? '';
    final certUrl = cg.qualificationCertUrl ?? certItem?['url'];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF93C5FD), width: 1.2),
        boxShadow: [
          BoxShadow(color: Colors.blue.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(cg),
          const SizedBox(width: 12),

          // Member & Upgrade Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      cg.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.slate900),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppTheme.slate100,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        cg.membershipNumber,
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppTheme.slate700),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppTheme.emerald50,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: AppTheme.emerald200),
                      ),
                      child: const Text(
                        '✓ Verified Member (Active)',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.emerald800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Current Tier vs Submitted Upgrade
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.slate50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.slate200),
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Current Tier:', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.blueLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              cg.tierLabel,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.blueAccent, size: 16),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Submitted Upgrade Document:', style: TextStyle(fontSize: 10, color: Colors.grey)),
                            const SizedBox(height: 2),
                            Text(
                              '$certTitle • $certInstitute ${certYear.isNotEmpty ? "($certYear)" : ""}',
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.slate900),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Certificate Preview Thumbnail & Action
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (certUrl != null && certUrl.isNotEmpty)
                InkWell(
                  onTap: () => _showDocumentImagePreviewDialog(
                    context: context,
                    title: 'Qualification Certificate - ${cg.name}',
                    url: certUrl,
                  ),
                  child: Container(
                    width: 55,
                    height: 42,
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: _buildThumbnailImage(certUrl),
                    ),
                  ),
                ),
              ElevatedButton.icon(
                onPressed: () => _showLevelUpUpgradeDialog(context, cg, provider),
                icon: const Icon(Icons.upgrade_rounded, size: 15),
                label: const Text('Review & Upgrade Level'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== TAB 3: APPROVED MEMBERS ====================
  Widget _buildApprovedMembersTab(BuildContext context, List<CaregiverModel> items, AdminProvider provider) {
    if (items.isEmpty) {
      return _buildEmptyState(
        icon: Icons.people_outline_rounded,
        title: 'No Approved Members Found',
        subtitle: 'No members match the current search or filter criteria.',
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, idx) {
        final cg = items[idx];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              _buildAvatar(cg),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          cg.name,
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppTheme.slate900),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: AppTheme.slate100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            cg.membershipNumber,
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppTheme.slate700),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: AppTheme.emerald50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppTheme.emerald100),
                          ),
                          child: const Text(
                            '✓ Verified',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.emerald800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${cg.tierLabel} • 📍 ${cg.district} • ⭐ ${cg.rating} (${cg.completedShifts} shifts completed)',
                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
              WhatsAppButton(phone: cg.phone, isCompact: true),
              const SizedBox(width: 6),
              OutlinedButton.icon(
                onPressed: () => _showCaregiverCredentialsReviewDialog(context, cg),
                icon: const Icon(Icons.folder_shared_rounded, size: 14),
                label: const Text('View Credentials'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==================== LEVEL UP UPGRADE DIALOG ====================
  void _showLevelUpUpgradeDialog(BuildContext context, CaregiverModel cg, AdminProvider provider) {
    final certItem = cg.verificationItems['qualification_cert'] is Map
        ? cg.verificationItems['qualification_cert'] as Map
        : null;

    final certTitle = certItem?['certTitle'] ?? certItem?['title'] ?? 'Qualification Certificate';
    final certInstitute = certItem?['institute'] ?? 'Accredited Institute';
    final certYear = certItem?['issueYear'] ?? '';
    final certUrl = cg.qualificationCertUrl ?? certItem?['url'];

    // Possible tiers
    const tiers = [
      {'key': 'basic_aide', 'label': 'Companion Aide'},
      {'key': 'nurse_assistant', 'label': 'Nurse Assistant'},
      {'key': 'nvq_4_caregiver', 'label': 'NVQ Level 4 Certified Caregiver'},
      {'key': 'nvq_5_nurse', 'label': 'NVQ Level 5 Senior Nurse'},
      {'key': 'doctor', 'label': 'SLMC Registered Doctor'},
    ];

    String selectedTier = cg.tier;
    // Default promote to next logical tier
    if (cg.tier == 'basic_aide') {
      selectedTier = 'nurse_assistant';
    } else if (cg.tier == 'nurse_assistant') {
      selectedTier = 'nvq_4_caregiver';
    } else if (cg.tier == 'nvq_4_caregiver') {
      selectedTier = 'nvq_5_nurse';
    } else if (cg.tier == 'nvq_5_nurse') {
      selectedTier = 'doctor';
    }

    final remarksCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final targetTierLabel = tiers.firstWhere((t) => t['key'] == selectedTier)['label']!;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppTheme.blueLight, shape: BoxShape.circle),
                  child: const Icon(Icons.upgrade_rounded, color: AppTheme.primaryBlue, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Review Qualification & Level Up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('${cg.name} • ${cg.membershipNumber}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 580,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Member Active Status Guarantee Notice
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.emerald50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.emerald200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: AppTheme.emerald800, size: 18),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Verified Member Guarantee: Approving will promote this member\'s rank. Their active verified status remains intact.',
                              style: TextStyle(fontSize: 11.5, color: AppTheme.emerald900, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Submitted Document Info
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.slate50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.slate200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Submitted Certificate Details:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text('📜 Title: $certTitle', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          Text('🏛️ Institute: $certInstitute ${certYear.isNotEmpty ? "($certYear)" : ""}', style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
                          const SizedBox(height: 10),
                          if (certUrl != null && certUrl.isNotEmpty)
                            Row(
                              children: [
                                InkWell(
                                  onTap: () => _showDocumentImagePreviewDialog(
                                    context: context,
                                    title: certTitle,
                                    url: certUrl,
                                  ),
                                  child: Container(
                                    width: 100,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: _buildThumbnailImage(certUrl),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextButton.icon(
                                    onPressed: () => _showDocumentImagePreviewDialog(
                                      context: context,
                                      title: certTitle,
                                      url: certUrl,
                                    ),
                                    icon: const Icon(Icons.zoom_in_rounded, size: 18),
                                    label: const Text('Open High-Resolution Zoom Preview'),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tier Upgrade Selection
                    const Text('Select New Upgraded Clinical Tier:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.primaryBlue, width: 1.5),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedTier,
                          items: tiers.map((t) {
                            return DropdownMenuItem<String>(
                              value: t['key'],
                              child: Text(t['label']!, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => selectedTier = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Remarks
                    const Text('Admin Remarks / Notes (Optional):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: remarksCtrl,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 12.5),
                      decoration: InputDecoration(
                        hintText: 'e.g. Verified through TVEC Sri Lanka portal. Approved for NVQ Level 5.',
                        hintStyle: TextStyle(fontSize: 11.5, color: Colors.grey.shade400),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.all(10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _openRejectionDialog(context, cg, provider, 'qualification_cert');
                },
                style: OutlinedButton.styleFrom(foregroundColor: AppTheme.rose600),
                child: const Text('Reject Certificate'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await provider.upgradeCaregiverLevel(
                    caregiverId: cg.membershipNumber.isNotEmpty ? cg.membershipNumber : cg.id,
                    newTier: selectedTier,
                    newTierLabel: targetTierLabel,
                    remarks: remarksCtrl.text.trim(),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('🎉 ${cg.name}\'s rank was successfully upgraded to $targetTierLabel!'),
                        backgroundColor: AppTheme.emerald800,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.check_circle_rounded, size: 18),
                label: const Text('Approve & Upgrade Level'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.emerald800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==================== CREDENTIALS & PROFILE MANAGEMENT DIALOG ====================
  void _showCaregiverCredentialsReviewDialog(BuildContext context, CaregiverModel cg) {
    CaregiverProfileManagementDialog.show(context, cg);
    return;
    // ignore: dead_code
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final provider = context.read<AdminProvider>();
          final isAppr = cg.isApproved;
          final isRej = cg.isRejected;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppTheme.blueLight, shape: BoxShape.circle),
                  child: const Icon(Icons.verified_user_rounded, color: AppTheme.primaryBlue, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Credentials & Documents Review', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      Text('${cg.name} • ${cg.membershipNumber}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 580,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Member Profile Summary Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.slate50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.slate200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Tier: ${cg.tierLabel}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  Text('Contact: ${cg.phone} • District: ${cg.district}', style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700)),
                                  if (cg.nic != null && cg.nic!.isNotEmpty)
                                    Text('NIC: ${cg.nic}', style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700)),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isAppr
                                      ? Colors.green.shade50
                                      : isRej
                                          ? Colors.red.shade50
                                          : Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isAppr
                                        ? Colors.green.shade300
                                        : isRej
                                            ? Colors.red.shade300
                                            : Colors.amber.shade300,
                                  ),
                                ),
                                child: Text(
                                  isAppr
                                      ? 'APPROVED & VERIFIED'
                                      : isRej
                                          ? 'REJECTED'
                                          : 'PENDING APPROVAL',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isAppr
                                        ? Colors.green.shade800
                                        : isRej
                                            ? Colors.red.shade800
                                            : Colors.amber.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: cg.verificationProgress,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              cg.isVerifiedMember ? AppTheme.emerald800 : AppTheme.primaryBlue,
                            ),
                            minHeight: 5,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${cg.approvedVerificationCount} of ${cg.totalVerificationCount} Requirements Approved',
                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppTheme.slate600),
                              ),
                              Text(
                                cg.isVerifiedMember ? 'Member Active & Unlocked' : 'Locked until verified',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: cg.isVerifiedMember ? AppTheme.emerald800 : AppTheme.rose600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Text('Verification Pipeline Requirements:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),

                    // 1. Profile Image
                    _buildAdminVerificationItemCard(
                      context: context,
                      itemKey: 'profile_image',
                      title: 'Profile Photo',
                      status: cg.profileImageStatus,
                      url: cg.profileImageUrl,
                      cg: cg,
                      provider: provider,
                      icon: Icons.person_pin_rounded,
                      onRefresh: () => setModalState(() {}),
                    ),
                    const SizedBox(height: 8),

                    // 2. NIC Front
                    _buildAdminVerificationItemCard(
                      context: context,
                      itemKey: 'nic_front',
                      title: 'National Identity Card - Front',
                      status: cg.nicFrontStatus,
                      url: cg.nicFrontUrl,
                      cg: cg,
                      provider: provider,
                      icon: Icons.badge_rounded,
                      onRefresh: () => setModalState(() {}),
                    ),
                    const SizedBox(height: 8),

                    // 3. NIC Back
                    _buildAdminVerificationItemCard(
                      context: context,
                      itemKey: 'nic_back',
                      title: 'National Identity Card - Back',
                      status: cg.nicBackStatus,
                      url: cg.nicBackUrl,
                      cg: cg,
                      provider: provider,
                      icon: Icons.badge_outlined,
                      onRefresh: () => setModalState(() {}),
                    ),
                    const SizedBox(height: 8),

                    // 4. Police Report
                    _buildAdminVerificationItemCard(
                      context: context,
                      itemKey: 'police_report',
                      title: 'Police Clearance Report',
                      status: cg.policeReportStatus,
                      url: cg.policeReportUrl,
                      cg: cg,
                      provider: provider,
                      icon: Icons.local_police_rounded,
                      onRefresh: () => setModalState(() {}),
                    ),
                    const SizedBox(height: 8),

                    // 5. Qualification Cert
                    _buildAdminVerificationItemCard(
                      context: context,
                      itemKey: 'qualification_cert',
                      title: 'Basic Qualification Certificate',
                      status: cg.qualificationCertStatus,
                      url: cg.qualificationCertUrl,
                      cg: cg,
                      provider: provider,
                      icon: Icons.school_rounded,
                      onRefresh: () => setModalState(() {}),
                    ),
                    const SizedBox(height: 8),

                    // 6. Face Verification
                    _buildAdminVerificationItemCard(
                      context: context,
                      itemKey: 'face_verification',
                      title: 'Live Face Verification',
                      status: cg.faceVerificationStatus,
                      url: cg.faceVerificationSnapshotUrl,
                      cg: cg,
                      provider: provider,
                      icon: Icons.face_retouching_natural_rounded,
                      onRefresh: () => setModalState(() {}),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _openRejectionDialog(context, cg, provider, null);
                },
                style: OutlinedButton.styleFrom(foregroundColor: AppTheme.rose600),
                child: const Text('Reject Application'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await provider.approveAllVerificationItems(cg.membershipNumber.isNotEmpty ? cg.membershipNumber : cg.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('🎉 ${cg.name} has been verified and fully approved!'),
                        backgroundColor: AppTheme.emerald800,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.check_circle_rounded, size: 18),
                label: const Text('Approve All & Verify Member'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.emerald800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Verification Item Row Card
  // ===================== PROFILE PHOTO CROP & PC UPLOAD TOOLS =====================
  void _openCropDialog({
    required BuildContext context,
    required CaregiverModel cg,
    required String imageSource,
    String? fileName,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => ImageCropperDialog(
        imageSource: imageSource,
        title: 'Crop & Frame Profile Photo - ${cg.name}',
        fileName: fileName ?? '${cg.membershipNumber.isNotEmpty ? cg.membershipNumber : cg.id}-profile.jpg',
        onSave: (croppedBase64) {
          context.read<AdminProvider>().updateCaregiverProfileImage(
                caregiverId: cg.membershipNumber.isNotEmpty ? cg.membershipNumber : cg.id,
                imageBase64: croppedBase64,
                autoApprove: true,
              );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Profile photo cropped, framed & saved for ${cg.name}!'),
              backgroundColor: AppTheme.emeraldGreen,
            ),
          );
        },
      ),
    );
  }

  void _pickAndUploadPhotoFromPC(BuildContext context, CaregiverModel cg) {
    pickImageFileFromPC(
      onPicked: (base64Data, fileName) {
        _openCropDialog(
          context: context,
          cg: cg,
          imageSource: base64Data,
          fileName: fileName,
        );
      },
    );
  }

  Widget _buildAdminVerificationItemCard({
    required BuildContext context,
    required String itemKey,
    required String title,
    required String status,
    required String? url,
    required CaregiverModel cg,
    required AdminProvider provider,
    required IconData icon,
    required VoidCallback onRefresh,
  }) {
    Color bg;
    Color border;
    Color fg;
    String statusLabel;

    if (status == 'approved') {
      bg = AppTheme.emerald50;
      border = AppTheme.emerald200;
      fg = AppTheme.emerald800;
      statusLabel = 'Approved ✓';
    } else if (status == 'pending') {
      bg = AppTheme.amber50;
      border = AppTheme.amber200;
      fg = AppTheme.amber800;
      statusLabel = 'Pending Review ⏳';
    } else if (status == 'rejected') {
      bg = AppTheme.rose50;
      border = AppTheme.rose200;
      fg = AppTheme.rose800;
      statusLabel = 'Rejected ✕';
    } else {
      bg = Colors.grey.shade50;
      border = Colors.grey.shade200;
      fg = Colors.grey.shade600;
      statusLabel = 'Not Uploaded ⚠️';
    }

    final hasImage = url != null && url.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: fg),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.slate900)),
                    Text(statusLabel, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: fg)),
                  ],
                ),
              ),
              if (hasImage) ...[
                InkWell(
                  onTap: () => _showDocumentImagePreviewDialog(
                    context: context,
                    title: title,
                    url: url,
                    onApprove: () async {
                      await provider.updateVerificationItemStatus(
                        cg.membershipNumber.isNotEmpty ? cg.membershipNumber : cg.id,
                        itemKey,
                        'approved',
                      );
                      onRefresh();
                    },
                    onReject: () {
                      _openRejectionDialog(context, cg, provider, itemKey);
                    },
                    onCrop: itemKey == 'profile_image'
                        ? () => _openCropDialog(context: context, cg: cg, imageSource: url)
                        : null,
                  ),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: _buildThumbnailImage(url),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (status != 'approved')
                IconButton(
                  icon: const Icon(Icons.check_circle_rounded, color: AppTheme.emerald800, size: 22),
                  tooltip: 'Approve $title',
                  onPressed: () async {
                    await provider.updateVerificationItemStatus(
                      cg.membershipNumber.isNotEmpty ? cg.membershipNumber : cg.id,
                      itemKey,
                      'approved',
                    );
                    onRefresh();
                  },
                ),
              if (status != 'rejected')
                IconButton(
                  icon: const Icon(Icons.cancel_rounded, color: AppTheme.rose600, size: 22),
                  tooltip: 'Reject $title',
                  onPressed: () {
                    _openRejectionDialog(context, cg, provider, itemKey);
                  },
                ),
            ],
          ),

          // Dedicated Admin Profile Photo Tools (Crop, Download, Upload from PC)
          if (itemKey == 'profile_image') ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('Admin Photo Tools:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.slate700)),
                  OutlinedButton.icon(
                    onPressed: () => _pickAndUploadPhotoFromPC(context, cg),
                    icon: const Icon(Icons.upload_file_rounded, size: 14),
                    label: const Text('Upload from PC', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  if (url != null && url.isNotEmpty) ...[
                    ElevatedButton.icon(
                      onPressed: () => _openCropDialog(context: context, cg: cg, imageSource: url),
                      icon: const Icon(Icons.crop_rotate_rounded, size: 14),
                      label: const Text('Crop & Frame', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        downloadWebFile(
                          dataOrUrl: url,
                          fileName: '${cg.membershipNumber.isNotEmpty ? cg.membershipNumber : cg.id}-profile.jpg',
                        );
                      },
                      icon: const Icon(Icons.download_rounded, size: 14),
                      label: const Text('Download', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Document Zoom Preview Dialog
  void _showDocumentImagePreviewDialog({
    required BuildContext context,
    required String title,
    required String url,
    VoidCallback? onApprove,
    VoidCallback? onReject,
    VoidCallback? onCrop,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          width: 800,
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
                              const Text('High-Resolution Inspection • Pinch or scroll to zoom', style: TextStyle(fontSize: 11, color: Colors.grey)),
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
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),

              // Interactive Image Preview
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
                      minScale: 0.5,
                      maxScale: 5.0,
                      child: Center(
                        child: _buildFullInspectionImage(url),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left side actions: Download & Crop
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          downloadWebFile(
                            dataOrUrl: url,
                            fileName: '${title.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}.jpg',
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Downloading image to your PC...'),
                              backgroundColor: AppTheme.emeraldGreen,
                            ),
                          );
                        },
                        icon: const Icon(Icons.download_rounded, size: 15),
                        label: const Text('Download Image'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      if (onCrop != null) ...[
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            onCrop();
                          },
                          icon: const Icon(Icons.crop_rotate_rounded, size: 15),
                          label: const Text('Crop & Adjust'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Right side actions: Close, Reject, Approve
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Close'),
                      ),
                      if (onReject != null) ...[
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            onReject();
                          },
                          icon: const Icon(Icons.cancel_rounded, size: 16),
                          label: const Text('Reject Document'),
                          style: OutlinedButton.styleFrom(foregroundColor: AppTheme.rose600),
                        ),
                      ],
                      if (onApprove != null) ...[
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            onApprove();
                          },
                          icon: const Icon(Icons.check_circle_rounded, size: 16),
                          label: const Text('Approve Document'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.emerald800,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
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

  // Rejection Dialog with Default Reasons
  void _openRejectionDialog(BuildContext context, CaregiverModel cg, AdminProvider provider, String? itemKey) {
    String selectedReason = defaultRejectionReasons[0]['detail']!;
    final customCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppTheme.rose600),
              const SizedBox(width: 8),
              Text(
                itemKey != null ? 'Reject Document' : 'Reject Application',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Standard Rejection Reason:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedReason,
                      items: defaultRejectionReasons.map((r) {
                        return DropdownMenuItem<String>(
                          value: r['detail'],
                          child: Text(r['title']!, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedReason = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Custom Message / Additional Note:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: customCtrl,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Add details here if needed...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final reason = customCtrl.text.trim().isNotEmpty
                    ? '$selectedReason - Note: ${customCtrl.text.trim()}'
                    : selectedReason;

                Navigator.pop(ctx);
                final docId = cg.membershipNumber.isNotEmpty ? cg.membershipNumber : cg.id;
                if (itemKey != null) {
                  await provider.updateVerificationItemStatus(docId, itemKey, 'rejected', rejectionReason: reason);
                } else {
                  await provider.updateCaregiverApproval(docId, 'rejected', rejectionReason: reason);
                }

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Document rejected and notification sent to ${cg.name}.'),
                      backgroundColor: AppTheme.rose600,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.rose600, foregroundColor: Colors.white),
              child: const Text('Confirm Rejection'),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== AVATAR & IMAGE HELPERS ====================
  Widget _buildAvatar(CaregiverModel cg) {
    final hasImg = cg.profileImageUrl != null && cg.profileImageUrl!.isNotEmpty;

    return Stack(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
          child: ClipOval(
            child: hasImg
                ? _buildThumbnailImage(cg.profileImageUrl!)
                : Text(
                    cg.name.isNotEmpty ? cg.name[0].toUpperCase() : 'C',
                    style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
          ),
        ),
        if (cg.isVerifiedMember)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(1.5),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded, color: AppTheme.emerald800, size: 11),
            ),
          ),
      ],
    );
  }

  Widget _buildThumbnailImage(String url) {
    if (url.startsWith('data:image')) {
      try {
        final b64 = url.split(',').last;
        return Image.memory(base64Decode(b64), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image));
      } catch (_) {
        return const Icon(Icons.broken_image);
      }
    }
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image));
    }
    return const Icon(Icons.description_rounded, color: AppTheme.primaryBlue);
  }

  Widget _buildFullInspectionImage(String url) {
    if (url.startsWith('data:image')) {
      try {
        final b64 = url.split(',').last;
        return Image.memory(base64Decode(b64), fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 64));
      } catch (_) {
        return const Icon(Icons.broken_image, size: 64);
      }
    }
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(url, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 64));
    }
    return const Icon(Icons.description_rounded, color: AppTheme.primaryBlue, size: 64);
  }

  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.slate800)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
