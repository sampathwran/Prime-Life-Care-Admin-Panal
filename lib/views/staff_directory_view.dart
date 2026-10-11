import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../models/caregiver_model.dart';
import '../theme/app_theme.dart';
import '../widgets/whatsapp_button.dart';
import '../widgets/charts/district_staff_chart.dart';

class StaffDirectoryView extends StatefulWidget {
  const StaffDirectoryView({super.key});

  @override
  State<StaffDirectoryView> createState() => _StaffDirectoryViewState();
}

class _StaffDirectoryViewState extends State<StaffDirectoryView> {
  String _filterStatus = 'all';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final caregivers = provider.caregivers.where((c) {
      if (_filterStatus == 'available' && c.status != 'available') return false;
      if (_filterStatus == 'on_duty' && c.status != 'on_duty') return false;
      if (_filterStatus == 'doctor' && c.tier != 'doctor') return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return c.name.toLowerCase().contains(q) ||
            c.district.toLowerCase().contains(q) ||
            c.tierLabel.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Caregiver & Clinical Staff Directory',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.slate900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Vetted staff with Sri Lanka Police clearance, NVQ certification, and CPR training.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _openAddCaregiverDialog(context),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: const Text('Register Caregiver'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // KPI Metric Tiles
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: 'Total Care Staff',
                  value: '${provider.caregivers.length}',
                  icon: Icons.people_outline,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildMetricTile(
                  title: 'Currently On Duty',
                  value: '${provider.activeShiftsCount}',
                  icon: Icons.access_time_filled,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildMetricTile(
                  title: 'Ready for Immediate Dispatch',
                  value: '${provider.caregivers.where((c) => c.status == 'available').length}',
                  icon: Icons.check_circle_outline,
                  color: AppTheme.emeraldGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Islandwide Caregiver Capacity Chart
          const DistrictStaffChart(),

          const SizedBox(height: 20),

          // Filters & Search
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All Staff', 'all', provider.caregivers.length),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Available Now',
                        'available',
                        provider.caregivers.where((c) => c.status == 'available').length,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'On Duty',
                        'on_duty',
                        provider.caregivers.where((c) => c.status == 'on_duty').length,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Doctors (SLMC)',
                        'doctor',
                        provider.caregivers.where((c) => c.tier == 'doctor').length,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 250,
                height: 40,
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search staff by name or city...',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                    prefixIcon: const Icon(Icons.search, size: 18),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Caregivers Grid
          caregivers.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40.0),
                  child: Center(
                    child: Text(
                      'No caregivers found with this filter.',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 18,
                    mainAxisSpacing: 18,
                    childAspectRatio: 1.25,
                  ),
                  itemCount: caregivers.length,
                  itemBuilder: (context, index) {
                    final cg = caregivers[index];
                    return _buildCaregiverCard(context, cg);
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.slate900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String key, int count) {
    final isSelected = _filterStatus == key;
    return InkWell(
      onTap: () => setState(() => _filterStatus = key),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.slate900 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.slate900 : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : AppTheme.slate800,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.2) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaregiverCard(BuildContext context, CaregiverModel cg) {
    final isOnDuty = cg.status == 'on_duty';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOnDuty ? AppTheme.primaryBlue.withOpacity(0.4) : Colors.grey.shade200,
          width: isOnDuty ? 1.5 : 1,
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
          // Header with Avatar & Status
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.primaryBlue.withOpacity(0.12),
                child: Text(
                  cg.name.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join(),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cg.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.slate900),
                    ),
                    Text(
                      '${cg.district} District • ${cg.completedShifts} Shifts',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isOnDuty ? Colors.blue.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isOnDuty ? 'ON DUTY' : 'AVAILABLE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isOnDuty ? AppTheme.primaryBlue : AppTheme.emeraldGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Qualification Tier Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified, size: 12, color: AppTheme.primaryBlue),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    cg.tierLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.slate800),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Active Patient or Rating
          if (isOnDuty && cg.activeAssignedPatient != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.home_outlined, size: 14, color: AppTheme.primaryBlue),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Assigned: ${cg.activeAssignedPatient}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryBlue),
                    ),
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  '${cg.rating} / 5.0 Clinical Rating',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
                ),
              ],
            ),

          const Spacer(),

          // Compliance Verification Badges
          Row(
            children: [
              _buildBadge('Police', cg.isPoliceVerified),
              const SizedBox(width: 4),
              _buildBadge('Medical', cg.isMedicalCleared),
              const SizedBox(width: 4),
              _buildBadge('CPR', cg.isCprCertified),
              const Spacer(),
              WhatsAppButton(
                phoneNumber: cg.phone,
                customMessage: 'Hello ${cg.name}, this is Prime Life Care Operations regarding your shift assignment.',
                label: 'Chat',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, bool verified) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: verified ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            verified ? Icons.check : Icons.close,
            size: 10,
            color: verified ? Colors.green.shade800 : Colors.red.shade800,
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              color: verified ? Colors.green.shade800 : Colors.red.shade800,
            ),
          ),
        ],
      ),
    );
  }

  void _openAddCaregiverDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: '+94 77 ');
    final districtCtrl = TextEditingController(text: 'Colombo');
    String tier = 'nvq_4_caregiver';
    String tierLabel = 'NVQ Level 4 Certified Caregiver';
    bool police = true;
    bool medical = true;
    bool cpr = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Register Caregiver / Nurse'),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        hintText: 'e.g. Sister Manel Kumari',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Contact Phone (WhatsApp)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: tier,
                      decoration: const InputDecoration(
                        labelText: 'Caregiver Qualification Tier',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'basic_aide', child: Text('Basic Companion Aide')),
                        DropdownMenuItem(value: 'nurse_assistant', child: Text('Nurse Assistant')),
                        DropdownMenuItem(value: 'nvq_4_caregiver', child: Text('NVQ Level 4 Certified Caregiver')),
                        DropdownMenuItem(value: 'nvq_5_nurse', child: Text('NVQ Level 5 Senior Clinical Nurse')),
                        DropdownMenuItem(value: 'doctor', child: Text('Doctor (MBBS / SLMC Registered)')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            tier = val;
                            if (val == 'basic_aide') tierLabel = 'Basic Companion Aide';
                            if (val == 'nurse_assistant') tierLabel = 'Nurse Assistant';
                            if (val == 'nvq_4_caregiver') tierLabel = 'NVQ Level 4 Certified Aide';
                            if (val == 'nvq_5_nurse') tierLabel = 'NVQ Level 5 Senior Clinical Nurse';
                            if (val == 'doctor') tierLabel = 'SLMC Registered Medical Officer';
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: districtCtrl,
                      decoration: const InputDecoration(
                        labelText: 'District Coverage',
                        hintText: 'Colombo / Gampaha / Kandy',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      title: const Text('Police Background Check Cleared'),
                      value: police,
                      onChanged: (v) => setDialogState(() => police = v ?? false),
                    ),
                    CheckboxListTile(
                      title: const Text('Medical Fitness Cleared'),
                      value: medical,
                      onChanged: (v) => setDialogState(() => medical = v ?? false),
                    ),
                    CheckboxListTile(
                      title: const Text('CPR & First Aid Certified'),
                      value: cpr,
                      onChanged: (v) => setDialogState(() => cpr = v ?? false),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  if (nameCtrl.text.trim().isEmpty) return;
                  final newCg = CaregiverModel(
                    id: 'cg_${DateTime.now().millisecondsSinceEpoch}',
                    name: nameCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    tier: tier,
                    tierLabel: tierLabel,
                    district: districtCtrl.text.trim(),
                    isPoliceVerified: police,
                    isMedicalCleared: medical,
                    isCprCertified: cpr,
                    status: 'available',
                    rating: 5.0,
                    completedShifts: 0,
                  );
                  context.read<AdminProvider>().addCaregiver(newCg);
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save & Register'),
              ),
            ],
          );
        },
      ),
    );
  }
}
