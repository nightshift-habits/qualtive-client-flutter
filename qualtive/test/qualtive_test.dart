import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:qualtive/qualtive.dart';
import 'package:qualtive/qualtive_platform.dart';
import 'package:qualtive/src/entry_content_encoder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    QualtivePlatform.instance = MethodChannelQualtive();
  });

  test('$MethodChannelQualtive is the default instance', () {
    expect(QualtivePlatform.instance, isA<MethodChannelQualtive>());
  });

  test('Qualtive.fetchEnquiry uses faked platform map', () async {
    QualtivePlatform.instance = _FakeQualtivePlatform(
      payload: <Object?, Object?>{
        'id': 1,
        'slug': 'demo',
        'name': 'Demo',
        'pages': <Object?>[],
        'submittedPages': <Object?>[],
        'theme': <Object?, Object?>{
          'cornerStyle': 'rounded',
          'background': <Object?, Object?>{
            'type': 'predefined',
            'value': 'plain',
          },
          'font': <Object?, Object?>{
            'type': 'predefined',
            'value': 'default',
          },
          'isBackgroundAttachmentVisibleInResponses': true,
          'isBackgroundColorVisibleInResponses': true,
        },
        'container': <Object?, Object?>{
          'id': 'ci-test',
          'isWhiteLabel': false,
          'customLogos': <Object?>[],
          'visibilityMode': 'private',
        },
      },
    );

    final enquiry = await Qualtive(containerId: 'ci-test').fetchEnquiry('demo');

    expect(enquiry.id, 1);
    expect(enquiry.slug, 'demo');
    expect(enquiry.name, 'Demo');
    expect(enquiry.container.id, 'ci-test');
  });

  test('MethodChannelQualtive maps platform errors', () async {
    const channel = MethodChannel('io.qualtive.qualtive');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          throw PlatformException(code: 'notFound', message: 'Missing');
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    expect(
      () => MethodChannelQualtive().fetchEnquiry(
        containerId: 'c',
        enquiryId: 'e',
        locale: 'en',
      ),
      throwsA(isA<QualtiveNotFoundException>()),
    );
  });

  test('MethodChannelQualtive returns a map from the channel', () async {
    const channel = MethodChannel('io.qualtive.qualtive');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'fetchEnquiry');
          expect(call.arguments, <String, Object?>{
            'containerId': 'ci-test',
            'enquiryId': 'web',
            'locale': 'en-US',
            'previewToken': 'tok',
          });
          return <String, Object?>{'ok': true};
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    final payload = await MethodChannelQualtive().fetchEnquiry(
      containerId: 'ci-test',
      enquiryId: 'web',
      locale: 'en-US',
      previewToken: 'tok',
    );
    expect(payload, <Object?, Object?>{'ok': true});
  });

  test('blank enquiryId throws ArgumentError', () async {
    expect(
      () => Qualtive(containerId: 'c').fetchEnquiry('  '),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('Qualtive.post uses faked platform id', () async {
    QualtivePlatform.instance = _FakeQualtivePlatform(
      payload: <Object?, Object?>{'id': 42},
    );

    final entry = await Qualtive(containerId: 'ci-test').post(
      'demo',
      content: [
        EntryScore(value: 75),
        const EntryText(value: 'Hello'),
      ],
      user: const User(id: 'u1', name: 'Ada', email: 'ada@example.com'),
      customAttributes: const {'age': 22},
      options: const PostOptions(
        metadataCollection: MetadataCollection.none,
        userTrackingConsent: UserTrackingConsent.denied,
      ),
    );

    expect(entry.id, 42);
    expect(entry.content, hasLength(2));
  });

  test('Qualtive.uploadAttachmentBytes uses faked platform id', () async {
    QualtivePlatform.instance = _FakeQualtivePlatform(
      payload: <Object?, Object?>{'id': 99},
    );

    final attachment = await Qualtive(containerId: 'ci-test')
        .uploadAttachmentBytes(
          Uint8List.fromList(const [1, 2, 3]),
          contentType: AttachmentContentType.imagePng,
        );

    expect(attachment.id, 99);
  });

  test('MethodChannelQualtive.post sends channel args', () async {
    const channel = MethodChannel('io.qualtive.qualtive');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'post');
          expect(call.arguments, <String, Object?>{
            'containerId': 'ci-test',
            'enquiryId': 'web',
            'locale': 'en-US',
            'content': <Object?>[
              <String, Object?>{
                'type': 'text',
                'value': 'Hello',
                'storageTarget': null,
              },
            ],
            'user': <String, Object?>{
              'id': 'u1',
              'name': null,
              'email': null,
            },
            'customAttributes': <String, Object>{'age': 22},
            'options': <String, Object?>{
              'metadataCollection': 'none',
              'userTrackingConsent': 'denied',
            },
          });
          return <String, Object?>{'id': 7};
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    final payload = await MethodChannelQualtive().post(
      containerId: 'ci-test',
      enquiryId: 'web',
      locale: 'en-US',
      content: encodeEntryContent([
        const EntryText(value: 'Hello'),
      ]),
      user: encodeUser(const User(id: 'u1')),
      customAttributes: const {'age': 22},
      options: encodePostOptions(
        const PostOptions(
          metadataCollection: MetadataCollection.none,
          userTrackingConsent: UserTrackingConsent.denied,
        ),
      ),
    );
    expect(payload, <Object?, Object?>{'id': 7});
  });

  test('MethodChannelQualtive.uploadAttachment sends bytes', () async {
    const channel = MethodChannel('io.qualtive.qualtive');
    final bytes = Uint8List.fromList(const [9, 8, 7]);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'uploadAttachment');
          expect(call.arguments, <String, Object?>{
            'containerId': 'ci-test',
            'locale': 'en',
            'contentType': 'image/png',
            'bytes': bytes,
            'path': null,
          });
          return <String, Object?>{'id': 3};
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    final payload = await MethodChannelQualtive().uploadAttachment(
      containerId: 'ci-test',
      locale: 'en',
      contentType: 'image/png',
      bytes: bytes,
    );
    expect(payload, <Object?, Object?>{'id': 3});
  });

  test('blank post enquiryId throws ArgumentError', () {
    expect(
      () => Qualtive(containerId: 'c').post('  ', content: const []),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('invalid custom attribute type throws ArgumentError', () {
    expect(
      () => Qualtive(containerId: 'c').post(
        'e',
        content: const [],
        customAttributes: {'age': <int>[1]},
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('out of range score throws ArgumentError', () {
    expect(() => EntryScore(value: 101), throwsA(isA<ArgumentError>()));
  });
}

class _FakeQualtivePlatform extends QualtivePlatform
    with MockPlatformInterfaceMixin {
  _FakeQualtivePlatform({required this.payload});

  final Map<Object?, Object?> payload;

  @override
  Future<Map<Object?, Object?>> fetchEnquiry({
    required String containerId,
    required String enquiryId,
    required String locale,
    String? previewToken,
  }) async => payload;

  @override
  Future<Map<Object?, Object?>> post({
    required String containerId,
    required String enquiryId,
    required String locale,
    required List<Map<String, Object?>> content,
    Map<String, Object?>? user,
    Map<String, Object> customAttributes = const {},
    Map<String, Object?> options = const {},
  }) async => payload;

  @override
  Future<Map<Object?, Object?>> uploadAttachment({
    required String containerId,
    required String locale,
    required String contentType,
    Uint8List? bytes,
    String? path,
  }) async => payload;
}
