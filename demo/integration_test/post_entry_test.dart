import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:qualtive/qualtive.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const options = PostOptions(
    metadataCollection: MetadataCollection.nonPersonal,
    userTrackingConsent: UserTrackingConsent.granted,
  );

  testWidgets('posts a sample entry to ci-test/flutter', (tester) async {
    final entry = await Qualtive(containerId: 'ci-test').post(
      'flutter',
      content: [
        EntryScore(value: 75),
        const EntryText(value: 'Hello world!'),
        const EntrySelect(value: 'Selected'),
        const EntryMultiselect(values: ['Multi 1', 'Multi 2']),
      ],
      user: const User(id: 'ci-flutter'),
      customAttributes: const {'Age': '23'},
      options: options,
    );

    expect(entry.id, isNotNull);
    expect(entry.id, greaterThan(0));
  });

  testWidgets('unknown enquiry post is not found', (tester) async {
    expect(
      () => Qualtive(containerId: 'ci-test').post(
        'does-not-exist-flutter',
        content: [const EntryText(value: 'Hello')],
        options: options,
      ),
      throwsA(isA<QualtiveNotFoundException>()),
    );
  });

  testWidgets('uploads png then posts with attachment', (tester) async {
    final client = Qualtive(containerId: 'ci-test');
    final attachment = await client.uploadAttachmentBytes(
      Uint8List.fromList(_samplePng),
      contentType: AttachmentContentType.imagePng,
    );
    expect(attachment.id, greaterThan(0));

    final entry = await client.post(
      'flutter',
      content: [
        const EntryText(value: 'Attachment upload integration'),
        EntryAttachments(attachments: [attachment]),
      ],
      user: const User(id: 'ci-flutter-attachment'),
      options: options,
    );

    expect(entry.id, isNotNull);
    expect(entry.id, greaterThan(0));
  });
}

/// 1x1 transparent PNG.
const _samplePng = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
];
