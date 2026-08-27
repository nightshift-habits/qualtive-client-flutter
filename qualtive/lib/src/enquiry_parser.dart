import 'dart:developer' as developer;

import 'models/attachment.dart';
import 'models/container.dart';
import 'models/enquiry.dart';
import 'models/page.dart';
import 'models/score_type.dart';
import 'models/submitted_page.dart';
import 'models/theme.dart';
import 'qualtive_exception.dart';

/// Parses an enquiry map from the method channel (or decoded API JSON).
///
/// Unknown content types and score types are skipped with a log hint, matching
/// the Android/Swift SDKs.
Enquiry parseEnquiry(Object? value) {
  final map = _asStringKeyedMap(value);
  if (map == null) {
    throw const QualtiveUnexpectedException('Invalid enquiry payload');
  }

  try {
    return Enquiry(
      id: _requireInt(map, 'id'),
      slug: _requireString(map, 'slug'),
      name: _requireString(map, 'name'),
      pages: _parsePages(map['pages']),
      submittedPages: _parseSubmittedPages(map['submittedPages']),
      theme: _parseTheme(map['theme']),
      container: _parseContainer(map['container']),
      isUserContactDetailsRequired:
          map['isUserContactDetailsRequired'] as bool? ?? false,
    );
  } on QualtiveException {
    rethrow;
  } on Object catch (error) {
    throw QualtiveUnexpectedException('Invalid enquiry payload', error);
  }
}

List<EnquiryPage> _parsePages(Object? raw) {
  final list = _asList(raw);
  if (raw != null && list == null) {
    _hintNewVersion('pages list');
    return const [];
  }
  if (list == null) {
    return const [];
  }
  return [
    for (final page in list)
      if (_asStringKeyedMap(page) case final map?)
        EnquiryPage(content: _parsePageContentList(map['content'])),
  ];
}

List<PageContent> _parsePageContentList(Object? raw) {
  final list = _asList(raw);
  if (raw != null && list == null) {
    _hintNewVersion('page content list');
    return const [];
  }
  if (list == null) {
    return const [];
  }

  final result = <PageContent>[];
  for (final item in list) {
    final content = _parsePageContent(item);
    if (content != null) {
      result.add(content);
    }
  }
  return result;
}

PageContent? _parsePageContent(Object? raw) {
  final map = _asStringKeyedMap(raw);
  if (map == null) {
    _hintNewVersion('page content');
    return null;
  }

  final type = map['type'];
  if (type is! String) {
    _hintNewVersion('page content');
    return null;
  }

  try {
    switch (type) {
      case 'title':
        return PageTitle(text: _requireString(map, 'text'));
      case 'body':
        return PageBody(text: _requireString(map, 'text'));
      case 'image':
        return PageImage(attachment: _parseAttachment(map['attachment']));
      case 'score':
        final scoreTypeRaw = _requireString(map, 'scoreType');
        final scoreType = _scoreTypeFromApi(scoreTypeRaw);
        if (scoreType == null) {
          _hintNewVersion('scoreType=$scoreTypeRaw');
          return null;
        }
        return PageScore(
          scoreType: scoreType,
          leadingText: map['leadingText'] as String?,
          trailingText: map['trailingText'] as String?,
        );
      case 'text':
        return PageText(
          placeholder: map['placeholder'] as String?,
          storageTarget: _parseStorageTarget(map['storageTarget']),
        );
      case 'select':
        return PageSelect(
          options: _parseStringList(map['options']),
          allowsCustomInput: map['allowsCustomInput'] as bool? ?? false,
        );
      case 'multiselect':
        return PageMultiselect(options: _parseStringList(map['options']));
      case 'attachments':
        return const PageAttachments();
      case 'contactDetails':
        return PageContactDetails(
          title: _requireString(map, 'title'),
          placeholder: map['placeholder'] as String?,
        );
      default:
        _hintNewVersion('page content type=$type');
        return null;
    }
  } on Object catch (error) {
    _hintNewVersion('page content type=$type ($error)');
    return null;
  }
}

TextStorageTarget _parseStorageTarget(Object? raw) {
  if (raw == null) {
    return const TextStorageTargetText();
  }
  final map = _asStringKeyedMap(raw);
  if (map == null) {
    throw const FormatException('Invalid storageTarget');
  }
  final type = map['type'];
  switch (type) {
    case 'text':
      return const TextStorageTargetText();
    case 'attribute':
      return TextStorageTargetAttribute(
        attribute: _requireString(map, 'attribute'),
      );
    default:
      throw FormatException('Unknown storageTarget type: $type');
  }
}

List<SubmittedPage> _parseSubmittedPages(Object? raw) {
  final list = _asList(raw);
  if (raw != null && list == null) {
    _hintNewVersion('submittedPages list');
    return const [];
  }
  if (list == null) {
    return const [];
  }
  return [
    for (final page in list)
      if (_asStringKeyedMap(page) case final map?)
        SubmittedPage(
          content: _parseSubmittedContentList(map['content']),
          conditions: _parseConditionList(map['conditions']),
        ),
  ];
}

List<SubmittedContent> _parseSubmittedContentList(Object? raw) {
  final list = _asList(raw);
  if (raw != null && list == null) {
    _hintNewVersion('submitted content list');
    return const [];
  }
  if (list == null) {
    return const [];
  }

  final result = <SubmittedContent>[];
  for (final item in list) {
    final content = _parseSubmittedContent(item);
    if (content != null) {
      result.add(content);
    }
  }
  return result;
}

SubmittedContent? _parseSubmittedContent(Object? raw) {
  final map = _asStringKeyedMap(raw);
  if (map == null) {
    _hintNewVersion('submitted content');
    return null;
  }

  final type = map['type'];
  if (type is! String) {
    _hintNewVersion('submitted content');
    return null;
  }

  try {
    switch (type) {
      case 'title':
        return SubmittedTitle(text: _requireString(map, 'text'));
      case 'body':
        return SubmittedBody(text: _requireString(map, 'text'));
      case 'image':
        return SubmittedImage(
          attachment: _parseAttachment(map['attachment']),
          linkUrl: (map['linkURL'] ?? map['linkUrl']) as String?,
        );
      case 'confirmationText':
        return SubmittedConfirmationText(text: _requireString(map, 'text'));
      case 'name':
        return const SubmittedName();
      case 'userInput':
        return const SubmittedUserInput();
      case 'userInputScore':
        return const SubmittedUserInputScore();
      case 'link':
        return SubmittedLink(
          text: _requireString(map, 'text'),
          url: _requireString(map, 'url'),
        );
      case 'reviewLinks':
        return SubmittedReviewLinks(links: _parseReviewLinks(map['links']));
      default:
        _hintNewVersion('submitted content type=$type');
        return null;
    }
  } on Object catch (error) {
    _hintNewVersion('submitted content type=$type ($error)');
    return null;
  }
}

List<ReviewLink> _parseReviewLinks(Object? raw) {
  final list = _asList(raw);
  if (list == null) {
    return const [];
  }
  return [
    for (final item in list)
      if (_asStringKeyedMap(item) case final map?)
        ReviewLink(
          title: _requireString(map, 'title'),
          url: _requireString(map, 'url'),
          logo: _parseReviewLinkLogo(map['logo']),
          icon: _parseReviewLinkIcon(map['icon']),
        ),
  ];
}

ReviewLinkLogo? _parseReviewLinkLogo(Object? raw) {
  final map = _asStringKeyedMap(raw);
  if (map == null) {
    return null;
  }
  return ReviewLinkLogo(
    urlVector: _requireString(map, 'urlVector'),
    urlVectorDark: _requireString(map, 'urlVectorDark'),
  );
}

ReviewLinkIcon? _parseReviewLinkIcon(Object? raw) {
  final map = _asStringKeyedMap(raw);
  if (map == null) {
    return null;
  }
  return ReviewLinkIcon(
    urlRaster: _requireString(map, 'urlRaster'),
    urlRasterDark: _requireString(map, 'urlRasterDark'),
  );
}

List<SubmittedCondition> _parseConditionList(Object? raw) {
  final list = _asList(raw);
  if (raw != null && list == null) {
    _hintNewVersion('condition list');
    return const [];
  }
  if (list == null) {
    return const [];
  }

  final result = <SubmittedCondition>[];
  for (final item in list) {
    final condition = _parseCondition(item);
    if (condition != null) {
      result.add(condition);
    }
  }
  return result;
}

SubmittedCondition? _parseCondition(Object? raw) {
  final map = _asStringKeyedMap(raw);
  if (map == null) {
    _hintNewVersion('condition');
    return null;
  }

  final type = map['type'];
  if (type is! String) {
    _hintNewVersion('condition');
    return null;
  }

  try {
    switch (type) {
      case 'score':
        return SubmittedScoreCondition(ranges: _parseScoreRanges(map['ranges']));
      default:
        _hintNewVersion('condition type=$type');
        return null;
    }
  } on Object catch (error) {
    _hintNewVersion('condition type=$type ($error)');
    return null;
  }
}

List<ScoreRange> _parseScoreRanges(Object? raw) {
  final list = _asList(raw);
  if (list == null) {
    return const [];
  }
  return [
    for (final item in list)
      if (_asStringKeyedMap(item) case final map?)
        ScoreRange(
          lower: _optionalInt(map['lower']),
          upper: _optionalInt(map['upper']),
        ),
  ];
}

EnquiryTheme _parseTheme(Object? raw) {
  final map = _asStringKeyedMap(raw);
  if (map == null) {
    throw const FormatException('Missing theme');
  }

  final cornerStyleRaw = _requireString(map, 'cornerStyle');
  final ThemeCornerStyle cornerStyle;
  switch (cornerStyleRaw) {
    case 'rounded':
      cornerStyle = ThemeCornerStyle.rounded;
    case 'square':
      cornerStyle = ThemeCornerStyle.square;
    default:
      _hintNewVersion('cornerStyle=$cornerStyleRaw');
      cornerStyle = ThemeCornerStyle.rounded;
  }

  return EnquiryTheme(
    background: _parseBackground(map['background']),
    font: _parseFont(map['font']),
    cornerStyle: cornerStyle,
    isBackgroundAttachmentVisibleInResponses:
        map['isBackgroundAttachmentVisibleInResponses'] as bool? ?? true,
    isBackgroundColorVisibleInResponses:
        map['isBackgroundColorVisibleInResponses'] as bool? ?? true,
  );
}

ThemeBackground _parseBackground(Object? raw) {
  final map = _asStringKeyedMap(raw);
  if (map == null) {
    throw const FormatException('Missing theme.background');
  }

  final type = _requireString(map, 'type');
  switch (type) {
    case 'predefined':
      final valueRaw = _requireString(map, 'value');
      final ThemeBackgroundPredefinedValue value;
      switch (valueRaw) {
        case 'plain':
          value = ThemeBackgroundPredefinedValue.plain;
        case 'sponda':
          value = ThemeBackgroundPredefinedValue.sponda;
        default:
          _hintNewVersion('background value=$valueRaw');
          value = ThemeBackgroundPredefinedValue.plain;
      }
      return ThemeBackgroundPredefined(value: value);
    case 'custom':
      final colorMap = _asStringKeyedMap(map['color']) ?? const {};
      return ThemeBackgroundCustom(
        attachment: _parseCustomBackgroundAttachment(map['attachment']),
        color: ThemeBackgroundCustomColor(
          value: _requireString(colorMap, 'value'),
        ),
      );
    default:
      throw FormatException('Unknown background type: $type');
  }
}

ThemeBackgroundCustomAttachment? _parseCustomBackgroundAttachment(Object? raw) {
  final map = _asStringKeyedMap(raw);
  if (map == null) {
    return null;
  }
  return ThemeBackgroundCustomAttachment(
    id: _requireInt(map, 'id'),
    contentType: _requireString(map, 'contentType'),
    url: _requireString(map, 'url'),
  );
}

ThemeFont _parseFont(Object? raw) {
  final map = _asStringKeyedMap(raw);
  if (map == null) {
    throw const FormatException('Missing theme.font');
  }
  final type = _requireString(map, 'type');
  switch (type) {
    case 'predefined':
      return ThemeFontPredefined(value: _requireString(map, 'value'));
    case 'custom':
      return ThemeFontCustom(url: _requireString(map, 'url'));
    default:
      throw FormatException('Unknown font type: $type');
  }
}

EnquiryContainer _parseContainer(Object? raw) {
  final map = _asStringKeyedMap(raw);
  if (map == null) {
    throw const FormatException('Missing container');
  }

  final visibilityRaw = _requireString(map, 'visibilityMode');
  final EnquiryVisibility visibilityMode;
  switch (visibilityRaw) {
    case 'public':
      visibilityMode = EnquiryVisibility.public;
    case 'private':
      visibilityMode = EnquiryVisibility.private;
    default:
      _hintNewVersion('visibilityMode=$visibilityRaw');
      visibilityMode = EnquiryVisibility.private;
  }

  return EnquiryContainer(
    id: _requireString(map, 'id'),
    isWhiteLabel: map['isWhiteLabel'] as bool? ?? false,
    customLogos: _parseCustomLogos(map['customLogos']),
    visibilityMode: visibilityMode,
  );
}

List<CustomLogo> _parseCustomLogos(Object? raw) {
  final list = _asList(raw);
  if (list == null) {
    return const [];
  }

  final result = <CustomLogo>[];
  for (final item in list) {
    final logo = _parseCustomLogo(item);
    if (logo != null) {
      result.add(logo);
    }
  }
  return result;
}

CustomLogo? _parseCustomLogo(Object? raw) {
  final map = _asStringKeyedMap(raw);
  if (map == null) {
    return null;
  }

  final size = switch (map['size']) {
    'wide' => CustomLogoSize.wide,
    'square' => CustomLogoSize.square,
    _ => null,
  };
  final intendedBackground = switch (map['intendedBackground']) {
    'light' => CustomLogoIntendedBackground.light,
    'dark' => CustomLogoIntendedBackground.dark,
    _ => null,
  };
  if (size == null || intendedBackground == null) {
    return null;
  }

  return CustomLogo(
    size: size,
    intendedBackground: intendedBackground,
    primaryColor: _requireString(map, 'primaryColor'),
    urlVector: _requireString(map, 'urlVector'),
  );
}

Attachment _parseAttachment(Object? raw) {
  final map = _asStringKeyedMap(raw);
  if (map == null) {
    throw const FormatException('Missing attachment');
  }
  return Attachment(url: _requireString(map, 'url'));
}

List<String> _parseStringList(Object? raw) {
  final list = _asList(raw);
  if (list == null) {
    return const [];
  }
  return [for (final item in list) if (item is String) item];
}

Map<String, Object?>? _asStringKeyedMap(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }
  if (value is Map) {
    return <String, Object?>{
      for (final entry in value.entries)
        if (entry.key is String) entry.key as String: entry.value,
    };
  }
  return null;
}

List<Object?>? _asList(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is List<Object?>) {
    return value;
  }
  if (value is List) {
    return List<Object?>.from(value);
  }
  return null;
}

int _requireInt(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  throw FormatException('Expected int for $key, got $value');
}

int? _optionalInt(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  throw FormatException('Expected int?, got $value');
}

String _requireString(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is String) {
    return value;
  }
  throw FormatException('Expected String for $key, got $value');
}

void _hintNewVersion(String detail) {
  developer.log(
    'Unknown Qualtive API field ($detail). Consider updating the Qualtive '
    'client library.',
    name: 'Qualtive',
  );
}

ScoreType? _scoreTypeFromApi(String raw) => switch (raw) {
  'smilies5' => ScoreType.smilies5,
  'smilies3' => ScoreType.smilies3,
  'thumbs' => ScoreType.thumbs,
  'nps' => ScoreType.nps,
  'stars5' => ScoreType.stars5,
  _ => null,
};

