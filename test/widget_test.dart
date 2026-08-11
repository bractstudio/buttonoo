import 'package:essential_key/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('EssentialKeyApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const EssentialKeyApp());
    expect(find.byType(EssentialKeyApp), findsOneWidget);
  });
}
