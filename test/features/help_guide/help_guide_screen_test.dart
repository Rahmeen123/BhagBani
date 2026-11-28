import 'package:baghbani/features/help_guide/screens/help_guide_content_screen.dart';
import 'package:baghbani/features/help_guide/screens/help_guide_language_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('language cards open English and Urdu guide content',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: HelpGuideScreen()),
    );

    expect(find.text('Choose Language'), findsOneWidget);
    expect(find.text('English Guide'), findsOneWidget);
    expect(find.text('اردو رہنمائی'), findsOneWidget);

    await tester.tap(find.text('اردو رہنمائی'));
    await tester.pumpAndSettle();

    expect(find.byType(HelpGuideContentScreen), findsOneWidget);
    expect(find.text('مدد اور رہنمائی'), findsOneWidget);
    expect(find.text('فصلوں کی تجویز'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('فصلوں کی تجویز'))),
      TextDirection.rtl,
    );

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('English Guide'));
    await tester.pumpAndSettle();

    expect(find.text('Help & Guide'), findsOneWidget);
    expect(find.text('Getting started'), findsOneWidget);
    expect(find.text('Crop Recommendation Guide'), findsOneWidget);

    await tester.tap(find.text('How Baghbani Works'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Baghbani combines smart satellite land analysis, personalized crop & '
        'tree planning, direct nursery shopping, and grower community '
        'collaboration into a single, seamless platform. Simply select any '
        'service from your home dashboard to begin.',
      ),
      findsOneWidget,
    );
  });
}
