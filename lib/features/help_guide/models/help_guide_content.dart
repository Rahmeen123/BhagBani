class HelpGuideEntry {
  const HelpGuideEntry({
    required this.title,
    required this.body,
    required this.icon,
    required this.accent,
    required this.tint,
  });

  factory HelpGuideEntry.fromJson(Map<String, dynamic> json) {
    return HelpGuideEntry(
      title: json['title'] as String,
      body: json['body'] as String,
      icon: json['icon'] as String,
      accent: json['accent'] as String,
      tint: json['tint'] as String,
    );
  }

  final String title;
  final String body;
  final String icon;
  final String accent;
  final String tint;
}

class HelpGuideContent {
  const HelpGuideContent({
    required this.heroTitle,
    required this.heroSubtitle,
    required this.guidesTitle,
    required this.guidesSubtitle,
    required this.guides,
    required this.faqTitle,
    required this.faqSubtitle,
    required this.faqs,
    this.supportTitle,
    this.supportBody,
  });

  factory HelpGuideContent.fromJson(Map<String, dynamic> json) {
    return HelpGuideContent(
      heroTitle: json['heroTitle'] as String,
      heroSubtitle: json['heroSubtitle'] as String,
      guidesTitle: json['guidesTitle'] as String,
      guidesSubtitle: json['guidesSubtitle'] as String,
      guides: (json['guides'] as List<dynamic>)
          .map(
              (entry) => HelpGuideEntry.fromJson(entry as Map<String, dynamic>))
          .toList(),
      faqTitle: json['faqTitle'] as String,
      faqSubtitle: json['faqSubtitle'] as String,
      faqs: (json['faqs'] as List<dynamic>)
          .map(
              (entry) => HelpGuideEntry.fromJson(entry as Map<String, dynamic>))
          .toList(),
      supportTitle: json['supportTitle'] as String?,
      supportBody: json['supportBody'] as String?,
    );
  }

  final String heroTitle;
  final String heroSubtitle;
  final String guidesTitle;
  final String guidesSubtitle;
  final List<HelpGuideEntry> guides;
  final String faqTitle;
  final String faqSubtitle;
  final List<HelpGuideEntry> faqs;
  final String? supportTitle;
  final String? supportBody;
}
