import 'package:flutter_test/flutter_test.dart';
import 'package:person_app/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Săn Sale Tết'), findsOneWidget);
  });
}
