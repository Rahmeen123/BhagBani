import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'help_guide_content_screen.dart';

class HelpGuideScreen extends StatelessWidget {
  const HelpGuideScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          backgroundColor: AppColors.cream,
          title: const Text('Help & Guide'),
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const Text(
              'Choose Language',
              style: TextStyle(
                color: AppColors.dark,
                fontWeight: FontWeight.w700,
                fontSize: 19,
              ),
            ),
            const SizedBox(height: 12),
            _LanguageCard(
              flag: '🇬🇧',
              title: 'English Guide',
              onTap: () => _openGuide(context, isUrdu: false),
            ),
            _LanguageCard(
              flag: '🇵🇰',
              title: 'اردو رہنمائی',
              isUrdu: true,
              onTap: () => _openGuide(context, isUrdu: true),
            ),
          ],
        ),
      );

  void _openGuide(BuildContext context, {required bool isUrdu}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HelpGuideContentScreen(isUrdu: isUrdu),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.flag,
    required this.title,
    required this.onTap,
    this.isUrdu = false,
  });

  final String flag;
  final String title;
  final VoidCallback onTap;
  final bool isUrdu;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.borderLight),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Material(
          color: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppColors.borderLight),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Directionality(
              textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Row(
                  children: [
                    Text(flag, style: const TextStyle(fontSize: 26)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        title,
                        textAlign: isUrdu ? TextAlign.right : TextAlign.left,
                        style: const TextStyle(
                          color: AppColors.dark,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      isUrdu
                          ? Icons.chevron_left_rounded
                          : Icons.chevron_right_rounded,
                      color: AppColors.muted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
