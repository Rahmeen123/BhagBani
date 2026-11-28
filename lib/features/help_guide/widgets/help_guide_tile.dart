import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/help_guide_content.dart';

class HelpGuideTile extends StatelessWidget {
  const HelpGuideTile({
    required this.guide,
    required this.isUrdu,
    super.key,
  });

  final HelpGuideEntry guide;
  final bool isUrdu;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppColors.borderLight),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _guideColor(guide.tint),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _guideIcon(guide.icon),
                  color: _guideColor(guide.accent),
                  size: 22,
                ),
              ),
              title: Text(
                guide.title,
                textAlign: isUrdu ? TextAlign.right : TextAlign.left,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14.5,
                  color: AppColors.dark,
                ),
              ),
              childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
              children: [
                Align(
                  alignment:
                      isUrdu ? Alignment.centerRight : Alignment.centerLeft,
                  child: Text(
                    guide.body,
                    textAlign: isUrdu ? TextAlign.right : TextAlign.left,
                    style: const TextStyle(
                      height: 1.55,
                      color: AppColors.muted,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

IconData _guideIcon(String name) => switch (name) {
      'eco' => Icons.eco_rounded,
      'agriculture' => Icons.agriculture_rounded,
      'park' => Icons.park_rounded,
      'local_florist' => Icons.local_florist_rounded,
      'handshake' => Icons.handshake_rounded,
      'help' => Icons.help_outline_rounded,
      'yard' => Icons.yard_rounded,
      'person' => Icons.person_outline_rounded,
      'satellite' => Icons.satellite_alt_rounded,
      'health' => Icons.health_and_safety_rounded,
      'land' => Icons.landscape_rounded,
      'community' => Icons.groups_rounded,
      'support' => Icons.support_agent_rounded,
      _ => Icons.menu_book_rounded,
    };

Color _guideColor(String name) => switch (name) {
      'farmAccent' => AppColors.farmAccent,
      'farmTint' => AppColors.farmTint,
      'gardenAccent' => AppColors.gardenAccent,
      'gardenTint' => AppColors.gardenTint,
      'communityAccent' => AppColors.communityAccent,
      'communityTint' => AppColors.communityTint,
      _ => AppColors.primary,
    };
