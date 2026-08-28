import 'dart:typed_data';
import 'dart:ui' show Locale, PlatformDispatcher;

import 'entry_content_encoder.dart';
import 'enquiry_parser.dart';
import 'models/attachment_content_type.dart';
import 'models/enquiry.dart';
import 'models/entry.dart';
import 'models/post_options.dart';
import 'models/user.dart';
import 'qualtive_exception.dart';
import 'qualtive_platform.dart';

/// Qualtive client for a single container.
///
/// Create an instance with [Qualtive] and inject it in your app. Tests can fake
/// `QualtivePlatform.instance` via `package:qualtive/qualtive_platform.dart`.
class Qualtive {
  Qualtive({required this.containerId, this.workspaceId, Locale? locale})
    : locale = locale ?? PlatformDispatcher.instance.locale;

  /// Container id this client talks to.
  final String containerId;

  /// Optional workspace slug sent as `X-Workspace`.
  ///
  /// When omitted, the user API uses the container's default workspace.
  final String? workspaceId;

  /// Locale used for localizable enquiry fields (`Accept-Language`).
  final Locale locale;

  /// Fetches an enquiry definition.
  ///
  /// [enquiryId] may be a slug or numeric id as a string.
  /// [previewToken] is optional for unpublished enquiry drafts.
  Future<Enquiry> fetchEnquiry(String enquiryId, {String? previewToken}) async {
    _requireEnquiryId(enquiryId);

    final payload = await QualtivePlatform.instance.fetchEnquiry(
      containerId: containerId,
      workspaceId: workspaceId,
      enquiryId: enquiryId,
      locale: _localeToLanguageTag(locale),
      previewToken: previewToken,
    );
    return parseEnquiry(payload);
  }

  /// Posts a feedback entry for [enquiryId].
  ///
  /// Text sections whose enquiry definition uses an attribute storage target
  /// are sent as attributes, not as text content.
  ///
  /// [customAttributes] values must be [String], [bool], or [num].
  Future<Entry> post(
    String enquiryId, {
    required List<EntryContent> content,
    User? user,
    Map<String, Object> customAttributes = const {},
    PostOptions options = const PostOptions(),
  }) async {
    _requireEnquiryId(enquiryId);
    _validateCustomAttributes(customAttributes);

    final payload = await QualtivePlatform.instance.post(
      containerId: containerId,
      workspaceId: workspaceId,
      enquiryId: enquiryId,
      locale: _localeToLanguageTag(locale),
      content: encodeEntryContent(content),
      user: encodeUser(user),
      customAttributes: customAttributes,
      options: encodePostOptions(options),
    );
    return Entry(id: _requireId(payload), content: content);
  }

  /// Uploads an attachment from bytes already in memory.
  ///
  /// Prefer [uploadAttachmentFile] for photos and especially video.
  Future<AttachmentReference> uploadAttachmentBytes(
    Uint8List bytes, {
    required AttachmentContentType contentType,
  }) async {
    final payload = await QualtivePlatform.instance.uploadAttachment(
      containerId: containerId,
      workspaceId: workspaceId,
      locale: _localeToLanguageTag(locale),
      contentType: contentType.mimeType,
      bytes: bytes,
    );
    return AttachmentReference(id: _requireId(payload));
  }

  /// Uploads an attachment by streaming a local file.
  ///
  /// [path] is a filesystem path, `file://` URL, or (on Android) a `content://`
  /// URI.
  Future<AttachmentReference> uploadAttachmentFile(
    String path, {
    required AttachmentContentType contentType,
  }) async {
    if (path.trim().isEmpty) {
      throw ArgumentError.value(path, 'path', 'must not be blank');
    }

    final payload = await QualtivePlatform.instance.uploadAttachment(
      containerId: containerId,
      workspaceId: workspaceId,
      locale: _localeToLanguageTag(locale),
      contentType: contentType.mimeType,
      path: path,
    );
    return AttachmentReference(id: _requireId(payload));
  }
}

void _requireEnquiryId(String enquiryId) {
  if (enquiryId.trim().isEmpty) {
    throw ArgumentError.value(enquiryId, 'enquiryId', 'must not be blank');
  }
}

void _validateCustomAttributes(Map<String, Object> attributes) {
  for (final entry in attributes.entries) {
    if (entry.key.trim().isEmpty) {
      throw ArgumentError.value(
        entry.key,
        'customAttributes',
        'attribute name must not be blank',
      );
    }
    final value = entry.value;
    if (value is String || value is bool || value is num) {
      continue;
    }
    throw ArgumentError.value(
      value,
      'customAttributes["${entry.key}"]',
      'must be String, bool, or num',
    );
  }
}

int _requireId(Map<Object?, Object?> payload) {
  final value = payload['id'];
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  throw const QualtiveUnexpectedException('Native result missing id');
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
