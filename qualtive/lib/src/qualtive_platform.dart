import 'package:flutter/services.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'qualtive_exception.dart';

abstract class QualtivePlatform extends PlatformInterface {
  QualtivePlatform() : super(token: _token);

  static final Object _token = Object();

  static QualtivePlatform _instance = MethodChannelQualtive();

  static QualtivePlatform get instance => _instance;

  static set instance(QualtivePlatform instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }

  /// Fetches an enquiry as a [StandardMessageCodec] map.
  Future<Map<Object?, Object?>> fetchEnquiry({
    required String containerId,
    required String enquiryId,
    required String locale,
    String? previewToken,
  }) {
    throw UnimplementedError('fetchEnquiry() has not been implemented.');
  }
}

class MethodChannelQualtive extends QualtivePlatform {
  MethodChannelQualtive({
    MethodChannel? methodChannel,
  }) : methodChannel =
           methodChannel ?? const MethodChannel('io.qualtive.qualtive');

  final MethodChannel methodChannel;

  @override
  Future<Map<Object?, Object?>> fetchEnquiry({
    required String containerId,
    required String enquiryId,
    required String locale,
    String? previewToken,
  }) async {
    try {
      final result = await methodChannel.invokeMapMethod<Object?, Object?>(
        'fetchEnquiry',
        <String, Object?>{
          'containerId': containerId,
          'enquiryId': enquiryId,
          'locale': locale,
          'previewToken': previewToken,
        },
      );
      if (result == null) {
        throw const QualtiveUnexpectedException(
          'Native fetchEnquiry returned null',
        );
      }
      return result;
    } on PlatformException catch (error) {
      throw _mapPlatformException(error);
    }
  }
}

QualtiveException _mapPlatformException(PlatformException error) {
  switch (error.code) {
    case 'notFound':
      return QualtiveNotFoundException(error.message, error);
    case 'connection':
      return QualtiveConnectionException(error.message, error);
    case 'remoteMaintenance':
      return QualtiveRemoteMaintenanceException(error.message, error);
    case 'unexpected':
      return QualtiveUnexpectedException(error.message, error);
    default:
      return QualtiveUnexpectedException(
        error.message ?? 'Unexpected platform error',
        error,
      );
  }
}
