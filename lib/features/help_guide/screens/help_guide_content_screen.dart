import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../data/help_guide_repository.dart';
import '../models/help_guide_content.dart';
import '../widgets/help_guide_tile.dart';

class HelpGuideContentScreen extends StatelessWidget {
  const HelpGuideContentScreen({required this.isUrdu, super.key});

  final bool isUrdu;

  @override
  Widget build(BuildContext context) {
    final contentFuture = HelpGuideRepository().load(isUrdu: isUrdu);
    final direction = isUrdu ? TextDirection.rtl : TextDirection.ltr;

    return Directionality(
      textDirection: direction,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          backgroundColor: AppColors.cream,
          title: Text(isUrdu ? 'مدد اور رہنمائی' : 'Help & Guide'),
          elevation: 0,
        ),
        body: FutureBuilder<HelpGuideContent>(
          future: contentFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    isUrdu
                        ? 'رہنمائی لوڈ نہیں ہو سکی۔ براہِ کرم دوبارہ کوشش کریں۔'
                        : 'Help content could not be loaded. Please try again.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            return _HelpGuideContent(
              content: snapshot.data!,
              isUrdu: isUrdu,
            );
          },
        ),
      ),
    );
  }
}

class _HelpGuideContent extends StatelessWidget {
  const _HelpGuideContent({required this.content, required this.isUrdu});

  final HelpGuideContent content;
  final bool isUrdu;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.menu_book_rounded,
                  color: AppColors.sageLight,
                  size: 42,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: isUrdu
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Text(
                        content.heroTitle,
                        textAlign: isUrdu ? TextAlign.right : TextAlign.left,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        content.heroSubtitle,
                        textAlign: isUrdu ? TextAlign.right : TextAlign.left,
                        style: const TextStyle(
                          color: AppColors.sageLight,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(
            title: content.guidesTitle,
            subtitle: content.guidesSubtitle,
            isUrdu: isUrdu,
          ),
          const SizedBox(height: 12),
          ...content.guides.map(
            (guide) => HelpGuideTile(guide: guide, isUrdu: isUrdu),
          ),
          const SizedBox(height: 24),
          _SectionHeader(
            title: content.faqTitle,
            subtitle: content.faqSubtitle,
            isUrdu: isUrdu,
          ),
          const SizedBox(height: 12),
          ...content.faqs.map(
            (faq) => HelpGuideTile(guide: faq, isUrdu: isUrdu),
          ),
          if (content.supportTitle != null && content.supportBody != null) ...[
            const SizedBox(height: 24),
            _SectionHeader(
              title: content.supportTitle!,
              subtitle: content.supportBody!,
              isUrdu: isUrdu,
            ),
          ],
        ],
      );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.isUrdu,
  });

  final String title;
  final String subtitle;
  final bool isUrdu;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment:
            isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            title,
            textAlign: isUrdu ? TextAlign.right : TextAlign.left,
            style: const TextStyle(
              color: AppColors.dark,
              fontWeight: FontWeight.w700,
              fontSize: 19,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: isUrdu ? TextAlign.right : TextAlign.left,
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
        ],
      );
}
