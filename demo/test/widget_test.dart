import 'package:flutter_test/flutter_test.dart';
import 'package:qualtive_demo/main.dart';

void main() {
  testWidgets('shows demo scaffolding', (WidgetTester tester) async {
    await tester.pumpWidget(const DemoApp());

    expect(find.text('Qualtive demo'), findsOneWidget);
    expect(
      find.text('Plugin scaffolding. Client API lands in a later release.'),
      findsOneWidget,
    );
  });
}
