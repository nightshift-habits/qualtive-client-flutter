import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:qualtive/qualtive.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('fetches ci-test/flutter', (tester) async {
    final enquiry = await Qualtive(containerId: 'ci-test')
        .fetchEnquiry('flutter');
    expect(enquiry.slug, 'flutter');
    expect(enquiry.container.id, 'ci-test');
    expect(enquiry.pages, isNotEmpty);
  });

  testWidgets('fetches ci-test/flutter-2 with a workspace', (tester) async {
    final enquiry = await Qualtive(
      containerId: 'ci-test',
      workspaceId: 'ci-test-2',
    ).fetchEnquiry('flutter-2');
    expect(enquiry.slug, 'flutter-2');
    expect(enquiry.container.id, 'ci-test');
    expect(enquiry.pages, isNotEmpty);
  });

  testWidgets('unknown enquiry is not found', (tester) async {
    expect(
      () =>
          Qualtive(containerId: 'ci-test')
              .fetchEnquiry('does-not-exist-flutter'),
      throwsA(isA<QualtiveNotFoundException>()),
    );
  });
}
