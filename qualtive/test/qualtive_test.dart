import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:qualtive/qualtive.dart';

void main() {
  final QualtivePlatform initialPlatform = QualtivePlatform.instance;

  test('$MethodChannelQualtive is the default instance', () {
    expect(initialPlatform, isA<MethodChannelQualtive>());
  });

  test('QualtivePlatform can be faked', () {
    QualtivePlatform.instance = _FakeQualtivePlatform();
    addTearDown(() {
      QualtivePlatform.instance = MethodChannelQualtive();
    });

    expect(QualtivePlatform.instance, isA<_FakeQualtivePlatform>());
    expect(Qualtive(), isNotNull);
  });
}

class _FakeQualtivePlatform extends QualtivePlatform
    with MockPlatformInterfaceMixin {}
