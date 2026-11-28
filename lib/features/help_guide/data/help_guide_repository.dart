import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/help_guide_content.dart';

class HelpGuideRepository {
  HelpGuideRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  Future<HelpGuideContent> load({required bool isUrdu}) async {
    final path = isUrdu
        ? 'assets/translations/help_ur.json'
        : 'assets/translations/help_en.json';
    final jsonText = await _bundle.loadString(path);
    final decoded = jsonDecode(jsonText) as Map<String, dynamic>;
    return HelpGuideContent.fromJson(decoded);
  }
}
