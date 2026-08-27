/// Visual theme for an enquiry.
class EnquiryTheme {
  const EnquiryTheme({
    required this.background,
    required this.font,
    required this.cornerStyle,
    this.isBackgroundAttachmentVisibleInResponses = true,
    this.isBackgroundColorVisibleInResponses = true,
  });

  final ThemeBackground background;
  final ThemeFont font;
  final ThemeCornerStyle cornerStyle;
  final bool isBackgroundAttachmentVisibleInResponses;
  final bool isBackgroundColorVisibleInResponses;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EnquiryTheme &&
          other.background == background &&
          other.font == font &&
          other.cornerStyle == cornerStyle &&
          other.isBackgroundAttachmentVisibleInResponses ==
              isBackgroundAttachmentVisibleInResponses &&
          other.isBackgroundColorVisibleInResponses ==
              isBackgroundColorVisibleInResponses;

  @override
  int get hashCode => Object.hash(
    background,
    font,
    cornerStyle,
    isBackgroundAttachmentVisibleInResponses,
    isBackgroundColorVisibleInResponses,
  );

  @override
  String toString() =>
      'EnquiryTheme(background: $background, font: $font, cornerStyle: $cornerStyle, '
      'isBackgroundAttachmentVisibleInResponses: '
      '$isBackgroundAttachmentVisibleInResponses, '
      'isBackgroundColorVisibleInResponses: '
      '$isBackgroundColorVisibleInResponses)';
}

enum ThemeCornerStyle { rounded, square }

sealed class ThemeBackground {
  const ThemeBackground();
}

class ThemeBackgroundPredefined extends ThemeBackground {
  const ThemeBackgroundPredefined({required this.value});

  final ThemeBackgroundPredefinedValue value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemeBackgroundPredefined && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'ThemeBackgroundPredefined(value: $value)';
}

enum ThemeBackgroundPredefinedValue { plain, sponda }

class ThemeBackgroundCustom extends ThemeBackground {
  const ThemeBackgroundCustom({this.attachment, required this.color});

  final ThemeBackgroundCustomAttachment? attachment;
  final ThemeBackgroundCustomColor color;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemeBackgroundCustom &&
          other.attachment == attachment &&
          other.color == color;

  @override
  int get hashCode => Object.hash(attachment, color);

  @override
  String toString() =>
      'ThemeBackgroundCustom(attachment: $attachment, color: $color)';
}

class ThemeBackgroundCustomAttachment {
  const ThemeBackgroundCustomAttachment({
    required this.id,
    required this.contentType,
    required this.url,
  });

  final int id;
  final String contentType;
  final String url;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemeBackgroundCustomAttachment &&
          other.id == id &&
          other.contentType == contentType &&
          other.url == url;

  @override
  int get hashCode => Object.hash(id, contentType, url);

  @override
  String toString() =>
      'ThemeBackgroundCustomAttachment(id: $id, contentType: $contentType, '
      'url: $url)';
}

class ThemeBackgroundCustomColor {
  const ThemeBackgroundCustomColor({required this.value});

  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemeBackgroundCustomColor && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'ThemeBackgroundCustomColor(value: $value)';
}

sealed class ThemeFont {
  const ThemeFont();
}

class ThemeFontPredefined extends ThemeFont {
  const ThemeFontPredefined({required this.value});

  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemeFontPredefined && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'ThemeFontPredefined(value: $value)';
}

class ThemeFontCustom extends ThemeFont {
  const ThemeFontCustom({required this.url});

  final String url;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ThemeFontCustom && other.url == url;

  @override
  int get hashCode => url.hashCode;

  @override
  String toString() => 'ThemeFontCustom(url: $url)';
}
