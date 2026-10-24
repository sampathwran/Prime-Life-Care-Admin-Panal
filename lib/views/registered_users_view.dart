import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/admin_provider.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import '../widgets/whatsapp_button.dart';

class RegisteredUsersView extends StatefulWidget {
  const RegisteredUsersView({super.key});

  @override
  State<RegisteredUsersView> createState() => _RegisteredUsersViewState();
}

class _RegisteredUsersViewState extends State<RegisteredUsersView> {
  String _search = '';
  String _selectedDistrict = 'All';
  final ScrollController _usersTableScrollController = ScrollController();

  @override
  void dispose() {
    _usersTableScrollController.dispose();
    super.dispose();
  }

  final List<String> _districts = [
    'All',
    'Colombo',
    'Gampaha',
    'Kalutara',
    'Kandy',
    'Kurunegala',
    'Galle',
    'Matara',
  ];

  void _showUserDetailsDialog(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          title: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.blueLight,
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue, fontSize: 14),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.slate900),
                    ),
                    Text(
                      'Registered Member ID: ${user.id}',
                      style: const TextStyle(fontSize: 10, color: AppTheme.slate500),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.slate500),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SelectionArea(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Divider(height: 12),

                    // Contact Info
                    _buildDetailRow(Icons.email_outlined, 'Email Address', user.email),
                    const SizedBox(height: 6),
                    _buildDetailRow(Icons.phone_outlined, 'Contact Number', user.phone),
                    const SizedBox(height: 6),
                    _buildDetailRow(Icons.location_on_outlined, 'District & City', '${user.city}, ${user.district}'),
                    const SizedBox(height: 6),
                    _buildDetailRow(Icons.home_outlined, 'Residential Address', user.address.isNotEmpty ? user.address : 'Not specified'),
                    const SizedBox(height: 6),
                    _buildDetailRow(Icons.calendar_today_outlined, 'Registered Date', _formatDate(user.createdAt)),

                    const SizedBox(height: 12),
                    const Text(
                      'Saved Family & Patient Profiles',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.slate800),
                    ),
                    const SizedBox(height: 6),

                    if (user.savedPatientsSummary != null && user.savedPatientsSummary!.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.slate50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.slate200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.favorite_rounded, color: AppTheme.rose500, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SelectableText(
                                user.savedPatientsSummary!,
                                style: const TextStyle(fontSize: 11, color: AppTheme.slate800, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.slate50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('No separate family patient profiles added yet.', style: TextStyle(fontSize: 10.5, color: AppTheme.slate500)),
                      ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            WhatsAppButton(
              phone: user.phone,
              message: 'Hello ${user.name}, this is Prime Life Care customer care. How can we assist with your healthcare needs today?',
              label: 'WhatsApp User',
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppTheme.slate400),
        const SizedBox(width: 6),
        SizedBox(
          width: 120,
          child: Text(label, style: const TextStyle(fontSize: 10.5, color: AppTheme.slate500, fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.slate900),
          ),
        ),
      ],
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

    final filteredUsers = provider.users.where((u) {
      if (_selectedDistrict != 'All' && !u.district.toLowerCase().contains(_selectedDistrict.toLowerCase())) {
        return false;
      }
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        final matches = u.name.toLowerCase().contains(q) ||
            u.email.toLowerCase().contains(q) ||
            u.phone.toLowerCase().contains(q) ||
            u.city.toLowerCase().contains(q) ||
            u.district.toLowerCase().contains(q) ||
            (u.savedPatientsSummary ?? '').toLowerCase().contains(q);
        if (!matches) return false;
      }
      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: SelectionArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Registered Users & Patient Families',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.slate900,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Direct directory of registered website members, family contacts, emails, and phone numbers.',
                        style: TextStyle(fontSize: 11, color: AppTheme.slate500),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.emerald100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_user_rounded, size: 12, color: AppTheme.emerald800),
                      const SizedBox(width: 4),
                      Text(
                        'Total: ${provider.users.length} Users',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 10.5, color: AppTheme.emerald800),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Search & District Filter Strip
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.slate200),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  // Search Input
                  SizedBox(
                    width: 280,
                    height: 32,
                    child: TextField(
                      style: const TextStyle(fontSize: 11),
                      decoration: InputDecoration(
                        hintText: 'Search by name, email, phone or city...',
                        hintStyle: const TextStyle(fontSize: 10.5, color: AppTheme.slate400),
                        prefixIcon: const Icon(Icons.search, size: 16, color: AppTheme.slate400),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                        isDense: true,
                        filled: true,
                        fillColor: AppTheme.slate50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppTheme.slate200)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppTheme.slate200)),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _search = val;
                        });
                      },
                    ),
                  ),

                  // District Filter
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('District: ', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.slate600)),
                      const SizedBox(width: 4),
                      Container(
                        height: 30,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.slate50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.slate200),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedDistrict,
                            style: const TextStyle(fontSize: 11, color: AppTheme.slate800, fontWeight: FontWeight.w600),
                            items: _districts.map((d) {
                              return DropdownMenuItem(value: d, child: Text(d));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedDistrict = val;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Registered Users Table
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.slate200),
              ),
              padding: const EdgeInsets.all(10),
              child: filteredUsers.isEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person_search_rounded, size: 36, color: AppTheme.slate400),
                          const SizedBox(height: 8),
                          SelectableText(
                            provider.users.isEmpty ? 'No Registered Users Yet' : 'No Matching Users Found',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.slate700),
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            provider.users.isEmpty
                                ? 'No accounts registered in the database yet. When visitors sign up on the website, their live verified accounts will automatically appear here.'
                                : 'Try adjusting your search criteria or district filter.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 11, color: AppTheme.slate500),
                          ),
                        ],
                      ),
                    )
                  : Scrollbar(
                      controller: _usersTableScrollController,
                      thumbVisibility: true,
                      trackVisibility: true,
                      child: SingleChildScrollView(
                        controller: _usersTableScrollController,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(bottom: 6),
                        child: DataTable(
                          columnSpacing: 10,
                          horizontalMargin: 8,
                          headingRowHeight: 32,
                          dataRowMinHeight: 46,
                          dataRowMaxHeight: 68,
                          headingRowColor: WidgetStateProperty.all(AppTheme.slate50),
                        columns: const [
                          DataColumn(label: Text('REGISTERED USER', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppTheme.slate500))),
                          DataColumn(label: Text('EMAIL ADDRESS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppTheme.slate500))),
                          DataColumn(label: Text('PHONE NUMBER', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppTheme.slate500))),
                          DataColumn(label: Text('LOCATION', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppTheme.slate500))),
                          DataColumn(label: Text('FAMILY / PATIENTS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppTheme.slate500))),
                          DataColumn(label: Text('BOOKINGS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppTheme.slate500))),
                          DataColumn(label: Text('STATUS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppTheme.slate500))),
                          DataColumn(label: Text('ACTIONS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppTheme.slate500))),
                        ],
                        rows: filteredUsers.map((u) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: AppTheme.blueLight,
                                      child: Text(
                                        u.name.isNotEmpty ? u.name[0].toUpperCase() : 'U',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue, fontSize: 11),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SelectableText(
                                          u.name,
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
                                        ),
                                        SelectableText(
                                          'Joined: ${_formatDate(u.createdAt).split(',').first}',
                                          style: const TextStyle(fontSize: 9, color: AppTheme.slate500),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.mail_outline_rounded, size: 12, color: AppTheme.slate400),
                                    const SizedBox(width: 4),
                                    SelectableText(
                                      u.email.isNotEmpty ? u.email : 'No email provided',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: u.email.isNotEmpty ? AppTheme.slate800 : AppTheme.slate400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.phone_outlined, size: 12, color: AppTheme.slate400),
                                    const SizedBox(width: 4),
                                    SelectableText(
                                      u.phone.isNotEmpty ? u.phone : 'Not provided',
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: AppTheme.primaryBlue),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SelectableText(u.city, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700)),
                                    SelectableText(u.district, style: const TextStyle(fontSize: 9, color: AppTheme.slate500)),
                                  ],
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: u.savedPatientsCount > 0 ? AppTheme.emerald100 : AppTheme.slate100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${u.savedPatientsCount} Patients',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: u.savedPatientsCount > 0 ? AppTheme.emerald800 : AppTheme.slate600,
                                        ),
                                      ),
                                    ),
                                    if (u.savedPatientsSummary != null && u.savedPatientsSummary!.isNotEmpty) ...[
                                      const SizedBox(width: 4),
                                      Tooltip(
                                        message: u.savedPatientsSummary!,
                                        child: const Icon(Icons.info_outline_rounded, size: 13, color: AppTheme.slate400),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.blueLight,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${u.totalBookingsCount} Bookings',
                                    style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: u.status == 'verified' ? AppTheme.blueLight : AppTheme.emerald100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    u.status.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.bold,
                                      color: u.status == 'verified' ? AppTheme.primaryBlue : AppTheme.emerald800,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    WhatsAppButton(
                                      phone: u.phone,
                                      message: 'Hello ${u.name}, this is Prime Life Care patient services.',
                                      isCompact: true,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.visibility_outlined, color: AppTheme.primaryBlue, size: 16),
                                      tooltip: 'View Full Profile & Patients',
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.all(2),
                                      constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                                      onPressed: () => _showUserDetailsDialog(context, u),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
