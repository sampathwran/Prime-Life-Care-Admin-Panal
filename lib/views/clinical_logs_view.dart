import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/admin_provider.dart';
import '../models/clinical_log_model.dart';
import '../theme/app_theme.dart';
import '../widgets/charts/patient_vitals_trend_chart.dart';

class ClinicalLogsView extends StatefulWidget {
  const ClinicalLogsView({super.key});

  @override
  State<ClinicalLogsView> createState() => _ClinicalLogsViewState();
}

class _ClinicalLogsViewState extends State<ClinicalLogsView> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final logs = provider.clinicalLogs.where((l) {
      if (_filter == 'pending_review') return !l.isSupervisorReviewed;
      if (_filter == 'reviewed') return l.isSupervisorReviewed;
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
                    'Clinical Vitals Logbook & Supervisor Audit',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.slate900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Real-time bedside vitals (BP, Sugar, SpO2, Pulse) and 2-hour bedsore turning compliance.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _openAddLogDialog(context),
                icon: const Icon(Icons.add_chart_rounded, size: 18),
                label: const Text('Add Vitals Entry'),
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

          // Vitals Summary Metrics
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: 'Today Vitals Entries',
                  value: '${provider.clinicalLogs.length}',
                  icon: Icons.monitor_heart_outlined,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildMetricTile(
                  title: 'Pending Supervisor Sign-Off',
                  value: '${provider.clinicalLogs.where((l) => !l.isSupervisorReviewed).length}',
                  icon: Icons.assignment_late_outlined,
                  color: Colors.amber.shade800,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildMetricTile(
                  title: '2-Hour Bed Turning Compliance',
                  value: '100% Intact',
                  icon: Icons.shield_outlined,
                  color: AppTheme.emeraldGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 24-Hour Patient Vitals Progression Curve
          const PatientVitalsTrendChart(),

          const SizedBox(height: 20),

          // Filters
          Row(
            children: [
              _buildFilterBtn('All Logs', 'all', provider.clinicalLogs.length),
              const SizedBox(width: 8),
              _buildFilterBtn(
                'Needs Review',
                'pending_review',
                provider.clinicalLogs.where((l) => !l.isSupervisorReviewed).length,
                highlight: true,
              ),
              const SizedBox(width: 8),
              _buildFilterBtn(
                'Reviewed & Cleared',
                'reviewed',
                provider.clinicalLogs.where((l) => l.isSupervisorReviewed).length,
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Clinical Logs List
          logs.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40.0),
                  child: Center(
                    child: Text(
                      'No clinical records found.',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: logs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return _buildLogCard(context, log);
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

  Widget _buildFilterBtn(String label, String key, int count, {bool highlight = false}) {
    final isSelected = _filter == key;
    return InkWell(
      onTap: () => setState(() => _filter = key),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.slate900 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: highlight && !isSelected ? Colors.amber.shade600 : (isSelected ? AppTheme.slate900 : Colors.grey.shade300),
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
                color: highlight ? Colors.amber.shade100 : (isSelected ? Colors.white.withOpacity(0.2) : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: highlight ? Colors.amber.shade900 : (isSelected ? Colors.white : Colors.grey.shade700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogCard(BuildContext context, ClinicalLogModel log) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
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
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.person_pin, color: AppTheme.primaryBlue, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            log.patientName,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.slate900),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            log.bookingCode,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      Text(
                        'Caregiver: ${log.caregiverName} • Recorded: ${log.recordedAt}',
                        style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ),

              // Supervisor Review Status
              if (log.isSupervisorReviewed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified, size: 14, color: AppTheme.emeraldGreen),
                      const SizedBox(width: 4),
                      Text(
                        'Nursing Supervisor Cleared',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                      ),
                    ],
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<AdminProvider>().reviewClinicalLog(log.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Vitals audit confirmed for ${log.patientName}'),
                        backgroundColor: AppTheme.emeraldGreen,
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('Sign Off as Supervisor'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Vitals Metrics Chips Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildVitalMetric('Blood Pressure', log.bloodPressure, Icons.speed),
                _buildDivider(),
                _buildVitalMetric('Blood Sugar', log.bloodSugar, Icons.water_drop_outlined),
                _buildDivider(),
                _buildVitalMetric('Heart Pulse', '${log.pulseRate} bpm', Icons.favorite_border),
                _buildDivider(),
                _buildVitalMetric('Oxygen (SpO2)', '${log.spO2}%', Icons.air),
                _buildDivider(),
                _buildVitalMetric('Temperature', log.temperature, Icons.thermostat_outlined),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Bed turning & Medication checklist + Clinical notes
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    _buildCheckChip('2-Hour Bed Turning', log.bedsoreTurnDone),
                    const SizedBox(width: 8),
                    _buildCheckChip('Medication Administered', log.medicationGiven),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.notes, size: 16, color: AppTheme.primaryBlue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          log.clinicalNotes,
                          style: const TextStyle(fontSize: 12, color: AppTheme.slate800),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 30, width: 1, color: Colors.grey.shade300);
  }

  Widget _buildVitalMetric(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: AppTheme.primaryBlue),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppTheme.slate900),
        ),
      ],
    );
  }

  Widget _buildCheckChip(String label, bool isDone) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDone ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isDone ? Colors.green.shade200 : Colors.red.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isDone ? Icons.check_circle : Icons.cancel, size: 14, color: isDone ? AppTheme.emeraldGreen : Colors.red),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDone ? Colors.green.shade900 : Colors.red.shade900,
            ),
          ),
        ],
      ),
    );
  }

  void _openAddLogDialog(BuildContext context) {
    final patientCtrl = TextEditingController(text: 'Mrs. Jayasinghe (Nugegoda)');
    final codeCtrl = TextEditingController(text: 'PLC-2026-1024');
    final cgCtrl = TextEditingController(text: 'Sister K. Chamila');
    final bpCtrl = TextEditingController(text: '122/80 mmHg');
    final sugarCtrl = TextEditingController(text: '118 mg/dL');
    final pulseCtrl = TextEditingController(text: '72');
    final spo2Ctrl = TextEditingController(text: '98');
    final tempCtrl = TextEditingController(text: '98.4 °F');
    final notesCtrl = TextEditingController(text: 'Afternoon tea and light walking with support. Patient stable.');
    bool bedTurning = true;
    bool meds = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add Clinical Vitals Entry'),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: patientCtrl,
                      decoration: const InputDecoration(labelText: 'Patient Name', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: codeCtrl,
                            decoration: const InputDecoration(labelText: 'Booking Code', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: cgCtrl,
                            decoration: const InputDecoration(labelText: 'Caregiver Name', border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: bpCtrl,
                            decoration: const InputDecoration(labelText: 'Blood Pressure', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: sugarCtrl,
                            decoration: const InputDecoration(labelText: 'Blood Sugar', border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: pulseCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Pulse (bpm)', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: spo2Ctrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'SpO2 (%)', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: tempCtrl,
                            decoration: const InputDecoration(labelText: 'Temp (°F)', border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      title: const Text('2-Hour Bed Sore Turn Completed'),
                      value: bedTurning,
                      onChanged: (v) => setDialogState(() => bedTurning = v ?? false),
                    ),
                    CheckboxListTile(
                      title: const Text('Prescription Medication Administered'),
                      value: meds,
                      onChanged: (v) => setDialogState(() => meds = v ?? false),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Clinical Observations / Notes', border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  final newLog = ClinicalLogModel(
                    id: 'cl_${DateTime.now().millisecondsSinceEpoch}',
                    bookingCode: codeCtrl.text.trim(),
                    patientName: patientCtrl.text.trim(),
                    caregiverName: cgCtrl.text.trim(),
                    recordedAt: 'Today, ${DateFormat('hh:mm a').format(DateTime.now())}',
                    bloodPressure: bpCtrl.text.trim(),
                    bloodSugar: sugarCtrl.text.trim(),
                    pulseRate: int.tryParse(pulseCtrl.text.trim()) ?? 72,
                    spO2: int.tryParse(spo2Ctrl.text.trim()) ?? 98,
                    temperature: tempCtrl.text.trim(),
                    bedsoreTurnDone: bedTurning,
                    medicationGiven: meds,
                    clinicalNotes: notesCtrl.text.trim(),
                    isSupervisorReviewed: true,
                  );
                  context.read<AdminProvider>().addClinicalLog(newLog);
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white),
                child: const Text('Save Entry'),
              ),
            ],
          );
        },
      ),
    );
  }
}
