import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_theme.dart';
import '../utils/direct_contact_launcher.dart';

/// Displays direct contact details (Name, Phone, WhatsApp, Address) with
/// immediate Call and WhatsApp action buttons matching the Baghbani theme.
class DirectContactCard extends StatelessWidget {
  const DirectContactCard({
    super.key,
    required this.roleLabel,
    required this.name,
    required this.phoneNumber,
    required this.whatsappNumber,
    required this.address,
    required this.callButtonLabel,
    required this.whatsAppButtonLabel,
    this.whatsAppMessage,
    this.accentColor = AppColors.primary,
    this.tintColor = AppColors.soft,
  });

  final String roleLabel;
  final String name;
  final String phoneNumber;
  final String whatsappNumber;
  final String address;
  final String callButtonLabel;
  final String whatsAppButtonLabel;
  final String? whatsAppMessage;
  final Color accentColor;
  final Color tintColor;

  @override
  Widget build(BuildContext context) {
    final effectiveWhatsApp =
        whatsappNumber.trim().isNotEmpty ? whatsappNumber.trim() : phoneNumber.trim();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: tintColor,
                child: Icon(
                  Icons.person_outline_rounded,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      roleLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name.isNotEmpty ? name : roleLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 12),
          _ContactRow(
            icon: Icons.phone_outlined,
            label: 'Phone Number',
            value: phoneNumber.trim().isNotEmpty ? phoneNumber.trim() : 'Not provided',
            accentColor: accentColor,
            canCopy: phoneNumber.trim().isNotEmpty,
          ),
          const SizedBox(height: 10),
          _ContactRow(
            icon: Icons.chat_outlined,
            label: 'WhatsApp Number',
            value: effectiveWhatsApp.isNotEmpty ? effectiveWhatsApp : 'Not provided',
            accentColor: const Color(0xFF1F7A4C),
            canCopy: effectiveWhatsApp.isNotEmpty,
          ),
          const SizedBox(height: 10),
          _ContactRow(
            icon: Icons.location_on_outlined,
            label: 'Address',
            value: address.trim().isNotEmpty ? address.trim() : 'Not provided',
            accentColor: accentColor,
            canCopy: false,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: phoneNumber.trim().isEmpty
                      ? null
                      : () => DirectContactLauncher.call(context, phoneNumber),
                  icon: const Icon(Icons.call_rounded, size: 18),
                  label: Text(
                    callButtonLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: effectiveWhatsApp.isEmpty
                      ? null
                      : () => DirectContactLauncher.whatsApp(
                            context,
                            effectiveWhatsApp,
                            message: whatsAppMessage,
                          ),
                  icon: const Icon(Icons.chat_rounded, size: 18),
                  label: Text(
                    whatsAppButtonLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1F7A4C),
                    side: const BorderSide(color: Color(0xFF1F7A4C)),
                    padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
    required this.canCopy,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;
  final bool canCopy;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: accentColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark,
                ),
              ),
            ],
          ),
        ),
        if (canCopy)
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.muted),
            tooltip: 'Copy',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$label copied')),
              );
            },
          ),
      ],
    );
  }
}
