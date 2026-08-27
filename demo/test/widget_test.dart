import 'package:flutter_test/flutter_test.dart';
import 'package:qualtive_demo/main.dart';

void main() {
  testWidgets('shows fetch enquiry form', (WidgetTester tester) async {
    await tester.pumpWidget(const DemoApp());

    expect(find.text('Qualtive demo'), findsOneWidget);
    expect(find.text('Fetch enquiry'), findsOneWidget);
    expect(find.text('Container id'), findsOneWidget);
    expect(find.text('Enquiry id / slug'), findsOneWidget);
  });
}
