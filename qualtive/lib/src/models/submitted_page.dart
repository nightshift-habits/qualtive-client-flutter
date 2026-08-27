import 'attachment.dart';

/// Thank-you / submitted page, optionally gated by score conditions.
class SubmittedPage {
  const SubmittedPage({
    required this.content,
    this.conditions = const [],
  });

  final List<SubmittedContent> content;
  final List<SubmittedCondition> conditions;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubmittedPage &&
          _listEquals(other.content, content) &&
          _listEquals(other.conditions, conditions);

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(content), Object.hashAll(conditions));

  @override
  String toString() =>
      'SubmittedPage(content: $content, conditions: $conditions)';
}

/// Content block on a submitted page.
sealed class SubmittedContent {
  const SubmittedContent();
}

class SubmittedTitle extends SubmittedContent {
  const SubmittedTitle({required this.text});

  final String text;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SubmittedTitle && other.text == text;

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => 'SubmittedTitle(text: $text)';
}

class SubmittedBody extends SubmittedContent {
  const SubmittedBody({required this.text});

  final String text;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SubmittedBody && other.text == text;

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => 'SubmittedBody(text: $text)';
}

class SubmittedImage extends SubmittedContent {
  const SubmittedImage({required this.attachment, this.linkUrl});

  final Attachment attachment;
  final String? linkUrl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubmittedImage &&
          other.attachment == attachment &&
          other.linkUrl == linkUrl;

  @override
  int get hashCode => Object.hash(attachment, linkUrl);

  @override
  String toString() =>
      'SubmittedImage(attachment: $attachment, linkUrl: $linkUrl)';
}

class SubmittedConfirmationText extends SubmittedContent {
  const SubmittedConfirmationText({required this.text});

  final String text;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubmittedConfirmationText && other.text == text;

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => 'SubmittedConfirmationText(text: $text)';
}

class SubmittedName extends SubmittedContent {
  const SubmittedName();

  @override
  bool operator ==(Object other) => other is SubmittedName;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'SubmittedName()';
}

class SubmittedUserInput extends SubmittedContent {
  const SubmittedUserInput();

  @override
  bool operator ==(Object other) => other is SubmittedUserInput;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'SubmittedUserInput()';
}

class SubmittedUserInputScore extends SubmittedContent {
  const SubmittedUserInputScore();

  @override
  bool operator ==(Object other) => other is SubmittedUserInputScore;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'SubmittedUserInputScore()';
}

class SubmittedLink extends SubmittedContent {
  const SubmittedLink({required this.text, required this.url});

  final String text;
  final String url;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubmittedLink && other.text == text && other.url == url;

  @override
  int get hashCode => Object.hash(text, url);

  @override
  String toString() => 'SubmittedLink(text: $text, url: $url)';
}

class SubmittedReviewLinks extends SubmittedContent {
  const SubmittedReviewLinks({required this.links});

  final List<ReviewLink> links;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubmittedReviewLinks && _listEquals(other.links, links);

  @override
  int get hashCode => Object.hashAll(links);

  @override
  String toString() => 'SubmittedReviewLinks(links: $links)';
}

class ReviewLink {
  const ReviewLink({
    required this.title,
    required this.url,
    this.logo,
    this.icon,
  });

  final String title;
  final String url;
  final ReviewLinkLogo? logo;
  final ReviewLinkIcon? icon;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReviewLink &&
          other.title == title &&
          other.url == url &&
          other.logo == logo &&
          other.icon == icon;

  @override
  int get hashCode => Object.hash(title, url, logo, icon);

  @override
  String toString() =>
      'ReviewLink(title: $title, url: $url, logo: $logo, icon: $icon)';
}

class ReviewLinkLogo {
  const ReviewLinkLogo({
    required this.urlVector,
    required this.urlVectorDark,
  });

  final String urlVector;
  final String urlVectorDark;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReviewLinkLogo &&
          other.urlVector == urlVector &&
          other.urlVectorDark == urlVectorDark;

  @override
  int get hashCode => Object.hash(urlVector, urlVectorDark);

  @override
  String toString() =>
      'ReviewLinkLogo(urlVector: $urlVector, urlVectorDark: $urlVectorDark)';
}

class ReviewLinkIcon {
  const ReviewLinkIcon({
    required this.urlRaster,
    required this.urlRasterDark,
  });

  final String urlRaster;
  final String urlRasterDark;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReviewLinkIcon &&
          other.urlRaster == urlRaster &&
          other.urlRasterDark == urlRasterDark;

  @override
  int get hashCode => Object.hash(urlRaster, urlRasterDark);

  @override
  String toString() =>
      'ReviewLinkIcon(urlRaster: $urlRaster, urlRasterDark: $urlRasterDark)';
}

/// Condition that must match for a submitted page to be shown.
sealed class SubmittedCondition {
  const SubmittedCondition();
}

class SubmittedScoreCondition extends SubmittedCondition {
  const SubmittedScoreCondition({required this.ranges});

  final List<ScoreRange> ranges;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubmittedScoreCondition && _listEquals(other.ranges, ranges);

  @override
  int get hashCode => Object.hashAll(ranges);

  @override
  String toString() => 'SubmittedScoreCondition(ranges: $ranges)';
}

class ScoreRange {
  const ScoreRange({this.lower, this.upper});

  final int? lower;
  final int? upper;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScoreRange && other.lower == lower && other.upper == upper;

  @override
  int get hashCode => Object.hash(lower, upper);

  @override
  String toString() => 'ScoreRange(lower: $lower, upper: $upper)';
}

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
