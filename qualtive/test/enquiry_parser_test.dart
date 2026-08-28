import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:qualtive/qualtive.dart';
import 'package:qualtive/src/enquiry_parser.dart';

void main() {
  group('parseEnquiry', () {
    test('parses full enquiry payload', () {
      final enquiry = parseEnquiry(jsonDecode(_fullPayload));

      expect(enquiry.id, 6290486614556672);
      expect(enquiry.slug, 'web');
      expect(enquiry.name, 'Web?');
      expect(enquiry.isUserContactDetailsRequired, isTrue);
      expect(enquiry.pages, hasLength(1));
      expect(enquiry.pages[0].content, hasLength(9));

      final score = enquiry.pages[0].content[0] as PageScore;
      expect(score.scoreType, ScoreType.stars5);
      expect(score.leadingText, 'Bad');
      expect(score.trailingText, 'Good');

      final text = enquiry.pages[0].content[4] as PageText;
      expect(
        text.storageTarget,
        const TextStorageTargetAttribute(attribute: 'Age'),
      );

      final select = enquiry.pages[0].content[5] as PageSelect;
      expect(select.allowsCustomInput, isTrue);

      expect(enquiry.submittedPages, hasLength(1));
      expect(enquiry.submittedPages[0].conditions, hasLength(1));
      final condition =
          enquiry.submittedPages[0].conditions[0] as SubmittedScoreCondition;
      expect(condition.ranges[0].lower, 0);
      expect(condition.ranges[0].upper, 50);
      expect(enquiry.submittedPages[0].content, hasLength(6));

      expect(enquiry.theme.cornerStyle, ThemeCornerStyle.rounded);
      expect(enquiry.theme.isBackgroundColorVisibleInResponses, isFalse);
      expect(enquiry.container.visibilityMode, EnquiryVisibility.private);
    });

    test('entryContentTemplate flattens input types', () {
      final enquiry = parseEnquiry(jsonDecode(_fullPayload));
      final template = enquiry.entryContentTemplate();

      expect(template, hasLength(6));
      expect(template[0], isA<EntryScore>());
      expect(template[1], isA<EntryTitle>());
      expect(template[2], isA<EntryText>());
      expect(template[3], isA<EntrySelect>());
      expect(template[4], isA<EntryMultiselect>());
      expect(template[5], isA<EntryAttachments>());

      final score = template[0] as EntryScore;
      expect(score.value, isNull);
      expect(score.definition?.scoreType, ScoreType.stars5);

      final text = template[2] as EntryText;
      expect(
        text.definition?.storageTarget,
        const TextStorageTargetAttribute(attribute: 'Age'),
      );
    });

    test('skips unknown score type and keeps other content', () {
      final enquiry = parseEnquiry(jsonDecode(_unknownScorePayload));

      expect(enquiry.pages[0].content, hasLength(1));
      expect(enquiry.pages[0].content[0], isA<PageTitle>());
      expect(enquiry.theme.cornerStyle, ThemeCornerStyle.square);
      expect(enquiry.theme.font, isA<ThemeFontCustom>());
      expect(enquiry.container.isWhiteLabel, isTrue);
      expect(enquiry.container.visibilityMode, EnquiryVisibility.public);
      expect(enquiry.container.customLogos, hasLength(1));
    });

    test('throws on invalid root', () {
      expect(
        () => parseEnquiry(<Object?>[1, 2, 3]),
        throwsA(isA<QualtiveUnexpectedException>()),
      );
    });
  });
}

const _fullPayload = r'''
{
  "id": 6290486614556672,
  "slug": "web",
  "name": "Web?",
  "isUserContactDetailsRequired": true,
  "pages": [
    {
      "content": [
        {
          "type": "score",
          "scoreType": "stars5",
          "leadingText": "Bad",
          "trailingText": "Good"
        },
        {
          "type": "title",
          "text": "Hello"
        },
        {
          "type": "body",
          "text": "Body text"
        },
        {
          "type": "image",
          "attachment": { "url": "https://example.com/a.png" }
        },
        {
          "type": "text",
          "placeholder": "Write…",
          "storageTarget": { "type": "attribute", "attribute": "Age" }
        },
        {
          "type": "select",
          "options": ["A", "B"],
          "allowsCustomInput": true
        },
        {
          "type": "multiselect",
          "options": ["X", "Y"]
        },
        { "type": "attachments" },
        {
          "type": "contactDetails",
          "title": "Email",
          "placeholder": "you@example.com"
        },
        { "type": "futureThing", "foo": 1 }
      ]
    }
  ],
  "submittedPages": [
    {
      "conditions": [
        {
          "type": "score",
          "ranges": [{ "lower": 0, "upper": 50 }]
        },
        { "type": "futureCondition" }
      ],
      "content": [
        { "type": "confirmationText", "text": "Thanks!" },
        { "type": "name" },
        { "type": "userInput" },
        { "type": "userInputScore" },
        { "type": "link", "text": "Site", "url": "https://example.com" },
        {
          "type": "reviewLinks",
          "links": [
            {
              "title": "Google",
              "url": "https://google.com",
              "logo": null,
              "icon": null
            }
          ]
        },
        { "type": "futureSubmitted" }
      ]
    }
  ],
  "theme": {
    "cornerStyle": "rounded",
    "background": { "type": "predefined", "value": "plain" },
    "font": { "type": "predefined", "value": "default" },
    "isBackgroundAttachmentVisibleInResponses": true,
    "isBackgroundColorVisibleInResponses": false
  },
  "container": {
    "id": "ci-test",
    "isWhiteLabel": false,
    "logo": null,
    "customLogos": [],
    "version": "qualtive",
    "visibilityMode": "private"
  }
}
''';

const _unknownScorePayload = r'''
{
  "id": 1,
  "slug": "x",
  "name": "X",
  "pages": [
    {
      "content": [
        {
          "type": "score",
          "scoreType": "emoji99",
          "leadingText": null,
          "trailingText": null
        },
        { "type": "title", "text": "Keep me" }
      ]
    }
  ],
  "submittedPages": [],
  "theme": {
    "cornerStyle": "square",
    "background": { "type": "predefined", "value": "sponda" },
    "font": { "type": "custom", "url": "https://fonts.example/a.woff2" },
    "isBackgroundAttachmentVisibleInResponses": true,
    "isBackgroundColorVisibleInResponses": true
  },
  "container": {
    "id": "c",
    "isWhiteLabel": true,
    "logo": { "urlVector": "https://a.svg", "urlVectorDark": null },
    "customLogos": [
      {
        "size": "wide",
        "intendedBackground": "light",
        "primaryColor": "#fff",
        "urlVector": "https://logo.svg"
      }
    ],
    "version": "qualtive",
    "visibilityMode": "public"
  }
}
''';
