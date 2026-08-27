import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:qualtive/qualtive.dart';
import 'package:qualtive/qualtive_platform.dart';

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
}
