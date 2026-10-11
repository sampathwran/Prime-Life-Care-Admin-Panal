import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class WhatsAppHelper {
  static String formatPhone(String rawPhone) {
    // Strip all non-digits
    String digits = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) {
      digits = '94${digits.substring(1)}';
    } else if (digits.startsWith('94')) {
      // already good
    } else if (!digits.startsWith('+') && digits.length == 9) {
      digits = '94$digits';
    }
    return digits;
  }

  static Future<void> launchWhatsApp(BuildContext context, String phone, String message) async {
    final cleanPhone = formatPhone(phone);
    final encodedMsg = Uri.encodeComponent(message);
    final uri = Uri.parse('https://wa.me/$cleanPhone?text=$encodedMsg');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open WhatsApp for $cleanPhone: $e'),
            backgroundColor: AppTheme.rose500,
          ),
        );
      }
    }
  }
}

class WhatsAppButton extends StatelessWidget {
  final String phone;
  final String message;
  final String label;
  final bool isCompact;

  WhatsAppButton({
    super.key,
    String? phone,
    String? phoneNumber,
    String? message,
    String? customMessage,
    this.label = 'Send WhatsApp',
    this.isCompact = false,
  })  : phone = phone ?? phoneNumber ?? '',
        message = message ?? customMessage ?? '';

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return IconButton(
        icon: const Icon(Icons.chat_bubble_rounded, color: AppTheme.whatsappGreen, size: 20),
        tooltip: '$label ($phone)',
        onPressed: () => WhatsAppHelper.launchWhatsApp(context, phone, message),
      );
    }

    return ElevatedButton.icon(
      icon: const Icon(Icons.chat_bubble_rounded, size: 16, color: Colors.white),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.whatsappGreen,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
      onPressed: () => WhatsAppHelper.launchWhatsApp(context, phone, message),
    );
  }
}
