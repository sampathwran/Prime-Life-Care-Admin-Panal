import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/admin_provider.dart';
import '../theme/app_theme.dart';

class TopAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TopAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final nowFormatted = DateFormat('EEE, d MMM yyyy').format(DateTime.now());

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppTheme.slate200, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Global Search Box
          Expanded(
            child: Container(
              height: 32,
              constraints: const BoxConstraints(maxWidth: 380),
              decoration: BoxDecoration(
                color: AppTheme.slate50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.slate200),
              ),
              child: TextField(
                onChanged: (val) => provider.setSearchQuery(val),
                style: const TextStyle(fontSize: 11.5),
                decoration: const InputDecoration(
                  hintText: 'Search patients, caregivers, order codes...',
                  hintStyle: TextStyle(color: AppTheme.slate400, fontSize: 11.5),
                  prefixIcon: Icon(Icons.search_rounded, color: AppTheme.slate400, size: 16),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Right Badges (Horizontally scrollable if screen is compact)
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Live Dispatch Islandwide Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: AppTheme.emerald100,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.emerald500.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppTheme.emerald500,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          '25 Districts Active',
                          style: TextStyle(
                            color: AppTheme.emerald800,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Firebase Real-time Cloud Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: provider.isFirebaseConnected ? const Color(0xFFEFF6FF) : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: provider.isFirebaseConnected
                            ? const Color(0xFF93C5FD)
                            : const Color(0xFFFDE68A),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          provider.isFirebaseConnected ? Icons.cloud_done_rounded : Icons.cloud_sync_rounded,
                          size: 12,
                          color: provider.isFirebaseConnected ? const Color(0xFF2563EB) : const Color(0xFFD97706),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          provider.isFirebaseConnected ? 'Cloud Sync' : 'Standby',
                          style: TextStyle(
                            color: provider.isFirebaseConnected ? const Color(0xFF1E40AF) : const Color(0xFF92400E),
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Date & Time
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: AppTheme.slate100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time_rounded, size: 12, color: AppTheme.slate600),
                        const SizedBox(width: 5),
                        Text(
                          nowFormatted,
                          style: const TextStyle(
                            color: AppTheme.slate700,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Careline Phone Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: AppTheme.blueLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.phone_in_talk_rounded, size: 12, color: AppTheme.primaryBlue),
                        SizedBox(width: 5),
                        Text(
                          '011 234 5678',
                          style: TextStyle(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
