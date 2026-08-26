import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class QualtivePlatform extends PlatformInterface {
  QualtivePlatform() : super(token: _token);

  static final Object _token = Object();

  static QualtivePlatform _instance = MethodChannelQualtive();

  static QualtivePlatform get instance => _instance;

  static set instance(QualtivePlatform instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }
}

class MethodChannelQualtive extends QualtivePlatform {}
