/// Container (workspace) details for an enquiry.
class EnquiryContainer {
  const EnquiryContainer({
    required this.id,
    this.isWhiteLabel = false,
    this.customLogos = const [],
    required this.visibilityMode,
  });

  final String id;
  final bool isWhiteLabel;
  final List<CustomLogo> customLogos;
  final EnquiryVisibility visibilityMode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EnquiryContainer &&
          other.id == id &&
          other.isWhiteLabel == isWhiteLabel &&
          _listEquals(other.customLogos, customLogos) &&
          other.visibilityMode == visibilityMode;

  @override
  int get hashCode =>
      Object.hash(id, isWhiteLabel, Object.hashAll(customLogos), visibilityMode);

  @override
  String toString() =>
      'EnquiryContainer(id: $id, isWhiteLabel: $isWhiteLabel, '
      'customLogos: $customLogos, visibilityMode: $visibilityMode)';
}

enum EnquiryVisibility { public, private }

class CustomLogo {
  const CustomLogo({
    required this.size,
    required this.intendedBackground,
    required this.primaryColor,
    required this.urlVector,
  });

  final CustomLogoSize size;
  final CustomLogoIntendedBackground intendedBackground;
  final String primaryColor;
  final String urlVector;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomLogo &&
          other.size == size &&
          other.intendedBackground == intendedBackground &&
          other.primaryColor == primaryColor &&
          other.urlVector == urlVector;

  @override
  int get hashCode =>
      Object.hash(size, intendedBackground, primaryColor, urlVector);

  @override
  String toString() =>
      'CustomLogo(size: $size, intendedBackground: $intendedBackground, '
      'primaryColor: $primaryColor, urlVector: $urlVector)';
}

enum CustomLogoSize { wide, square }

enum CustomLogoIntendedBackground { light, dark }

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
