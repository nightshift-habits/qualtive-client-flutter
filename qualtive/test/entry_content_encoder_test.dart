import 'package:flutter_test/flutter_test.dart';
import 'package:qualtive/qualtive.dart';
import 'package:qualtive/src/entry_content_encoder.dart';

void main() {
  test('encodes all entry content types', () {
    final encoded = encodeEntryContent([
      const EntryTitle(text: 'Hello'),
      EntryScore(
        value: 75,
        definition: const PageScore(
          scoreType: ScoreType.stars5,
          leadingText: 'Bad',
          trailingText: 'Good',
        ),
      ),
      const EntryText(
        value: 'Hi',
        definition: PageText(
          storageTarget: TextStorageTargetAttribute(attribute: 'Age'),
        ),
      ),
      const EntrySelect(value: 'A'),
      const EntryMultiselect(values: ['X', 'Y']),
      const EntryAttachments(
        attachments: [AttachmentReference(id: 99)],
      ),
    ]);

    expect(encoded, [
      {'type': 'title', 'text': 'Hello'},
      {
        'type': 'score',
        'value': 75,
        'scoreType': 'stars5',
        'leadingText': 'Bad',
        'trailingText': 'Good',
      },
      {
        'type': 'text',
        'value': 'Hi',
        'storageTarget': {'type': 'attribute', 'attribute': 'Age'},
      },
      {'type': 'select', 'value': 'A'},
      {
        'type': 'multiselect',
        'values': ['X', 'Y'],
      },
      {
        'type': 'attachments',
        'values': [
          {'id': 99},
        ],
      },
    ]);
  });

  test('omits definition fields when absent', () {
    final encoded = encodeEntryContent([
      EntryScore(value: 50),
      const EntryText(value: 'Hello'),
    ]);

    expect(encoded[0]['scoreType'], isNull);
    expect(encoded[1]['storageTarget'], isNull);
  });

  test('encodes user and post options', () {
    expect(
      encodeUser(const User(id: 'u1', name: 'Ada')),
      {'id': 'u1', 'name': 'Ada', 'email': null},
    );
    expect(encodeUser(null), isNull);
    expect(
      encodePostOptions(
        const PostOptions(
          metadataCollection: MetadataCollection.none,
          userTrackingConsent: UserTrackingConsent.denied,
        ),
      ),
      {
        'metadataCollection': 'none',
        'userTrackingConsent': 'denied',
      },
    );
  });
}
