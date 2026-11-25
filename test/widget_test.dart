import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_studio/main.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ConfigurationPage()));
    expect(find.byType(ConfigurationPage), findsOneWidget);
  });
}
