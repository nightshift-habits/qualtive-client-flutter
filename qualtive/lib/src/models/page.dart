import 'attachment.dart';
import 'score_type.dart';

/// A single page of enquiry content.
class EnquiryPage {
  const EnquiryPage({required this.content});

  final List<PageContent> content;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EnquiryPage && _listEquals(other.content, content);

  @override
  int get hashCode => Object.hashAll(content);

  @override
  String toString() => 'EnquiryPage(content: $content)';
}

/// Content block shown on an enquiry page.
sealed class PageContent {
  const PageContent();
}

/// Static title.
class PageTitle extends PageContent {
  const PageTitle({required this.text});

  final String text;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PageTitle && other.text == text;

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => 'PageTitle(text: $text)';
}

/// Static body text.
class PageBody extends PageContent {
  const PageBody({required this.text});

  final String text;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PageBody && other.text == text;

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => 'PageBody(text: $text)';
}

/// Static image.
class PageImage extends PageContent {
  const PageImage({required this.attachment});

  final Attachment attachment;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PageImage && other.attachment == attachment;

  @override
  int get hashCode => attachment.hashCode;

  @override
  String toString() => 'PageImage(attachment: $attachment)';
}

/// Score / rating input (0–100).
class PageScore extends PageContent {
  const PageScore({
    required this.scoreType,
    this.leadingText,
    this.trailingText,
  });

  final ScoreType scoreType;
  final String? leadingText;
  final String? trailingText;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PageScore &&
          other.scoreType == scoreType &&
          other.leadingText == leadingText &&
          other.trailingText == trailingText;

  @override
  int get hashCode => Object.hash(scoreType, leadingText, trailingText);

  @override
  String toString() =>
      'PageScore(scoreType: $scoreType, leadingText: $leadingText, '
      'trailingText: $trailingText)';
}

/// Free-form text input.
class PageText extends PageContent {
  const PageText({this.placeholder, required this.storageTarget});

  final String? placeholder;
  final TextStorageTarget storageTarget;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PageText &&
          other.placeholder == placeholder &&
          other.storageTarget == storageTarget;

  @override
  int get hashCode => Object.hash(placeholder, storageTarget);

  @override
  String toString() =>
      'PageText(placeholder: $placeholder, storageTarget: $storageTarget)';
}

/// Where text input is stored when posting.
sealed class TextStorageTarget {
  const TextStorageTarget();
}

/// Stored as entry text content.
class TextStorageTargetText extends TextStorageTarget {
  const TextStorageTargetText();

  @override
  bool operator ==(Object other) => other is TextStorageTargetText;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'TextStorageTargetText()';
}

/// Stored as a custom attribute.
class TextStorageTargetAttribute extends TextStorageTarget {
  const TextStorageTargetAttribute({required this.attribute});

  final String attribute;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextStorageTargetAttribute && other.attribute == attribute;

  @override
  int get hashCode => attribute.hashCode;

  @override
  String toString() => 'TextStorageTargetAttribute(attribute: $attribute)';
}

/// Single-select input.
class PageSelect extends PageContent {
  const PageSelect({
    required this.options,
    this.allowsCustomInput = false,
  });

  final List<String> options;
  final bool allowsCustomInput;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PageSelect &&
          _listEquals(other.options, options) &&
          other.allowsCustomInput == allowsCustomInput;

  @override
  int get hashCode => Object.hash(Object.hashAll(options), allowsCustomInput);

  @override
  String toString() =>
      'PageSelect(options: $options, allowsCustomInput: $allowsCustomInput)';
}

/// Multi-select input.
class PageMultiselect extends PageContent {
  const PageMultiselect({required this.options});

  final List<String> options;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PageMultiselect && _listEquals(other.options, options);

  @override
  int get hashCode => Object.hashAll(options);

  @override
  String toString() => 'PageMultiselect(options: $options)';
}

/// Attachments input.
class PageAttachments extends PageContent {
  const PageAttachments();

  @override
  bool operator ==(Object other) => other is PageAttachments;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'PageAttachments()';
}

/// Contact details input.
class PageContactDetails extends PageContent {
  const PageContactDetails({required this.title, this.placeholder});

  final String title;
  final String? placeholder;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PageContactDetails &&
          other.title == title &&
          other.placeholder == placeholder;

  @override
  int get hashCode => Object.hash(title, placeholder);

  @override
  String toString() =>
      'PageContactDetails(title: $title, placeholder: $placeholder)';
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
