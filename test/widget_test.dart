import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_final_project/main.dart';

void main() {
  testWidgets('SafeVision home screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const SafeVisionApp());
    await tester.pump();

    expect(find.text('SafeVision'), findsOneWidget);
  });
}
