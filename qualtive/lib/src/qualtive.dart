import 'dart:ui' show Locale, PlatformDispatcher;

import 'enquiry_parser.dart';
import 'models/enquiry.dart';
import 'qualtive_platform.dart';

/// Qualtive client for a single container.
///
/// Create an instance with [Qualtive] and inject it in your app. Tests can fake
/// `QualtivePlatform.instance` via `package:qualtive/qualtive_platform.dart`.
class Qualtive {
  Qualtive({
    required this.containerId,
    Locale? locale,
  }) : locale = locale ?? PlatformDispatcher.instance.locale;

  /// Container (workspace) id this client talks to.
  final String containerId;

  /// Locale used for localizable enquiry fields (`Accept-Language`).
  final Locale locale;

  /// Fetches an enquiry definition.
  ///
  /// [enquiryId] may be a slug or numeric id as a string.
  /// [previewToken] is optional for unpublished enquiry drafts.
  Future<Enquiry> fetchEnquiry(
    String enquiryId, {
    String? previewToken,
  }) async {
    if (enquiryId.trim().isEmpty) {
      throw ArgumentError.value(enquiryId, 'enquiryId', 'must not be blank');
    }

    final payload = await QualtivePlatform.instance.fetchEnquiry(
      containerId: containerId,
      enquiryId: enquiryId,
      locale: _localeToLanguageTag(locale),
      previewToken: previewToken,
    );
    return parseEnquiry(payload);
  }
}

String _localeToLanguageTag(Locale locale) {
  final language = locale.languageCode;
  final script = locale.scriptCode;
  final country = locale.countryCode;
  if (script != null &&
      script.isNotEmpty &&
      country != null &&
      country.isNotEmpty) {
    return '$language-$script-$country';
  }
  if (script != null && script.isNotEmpty) {
    return '$language-$script';
  }
  if (country != null && country.isNotEmpty) {
    return '$language-$country';
  }
  return language;
}
