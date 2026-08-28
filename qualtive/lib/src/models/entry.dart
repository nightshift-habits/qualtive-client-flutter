import 'page.dart';

/// A feedback entry (user response).
///
/// Use [Enquiry.entryContentTemplate] to build empty content for custom UI,
/// then [Qualtive.post] to submit.
class Entry {
  const Entry({this.id, this.content = const []});

  final int? id;
  final List<EntryContent> content;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Entry &&
          other.id == id &&
          _listEquals(other.content, content);

  @override
  int get hashCode => Object.hash(id, Object.hashAll(content));

  @override
  String toString() => 'Entry(id: $id, content: $content)';
}

/// Content section for an entry, parallel to enquiry page content that accepts
/// input.
sealed class EntryContent {
  const EntryContent();
}

/// Static title that was displayed to the user.
class EntryTitle extends EntryContent {
  const EntryTitle({required this.text, this.definition});

  final String text;
  final PageTitle? definition;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EntryTitle &&
          other.text == text &&
          other.definition == definition;

  @override
  int get hashCode => Object.hash(text, definition);

  @override
  String toString() => 'EntryTitle(text: $text, definition: $definition)';
}

/// Score / rating input (0–100).
class EntryScore extends EntryContent {
  EntryScore({this.value, this.definition}) {
    _validateScore(value);
  }

  final int? value;
  final PageScore? definition;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EntryScore &&
          other.value == value &&
          other.definition == definition;

  @override
  int get hashCode => Object.hash(value, definition);

  @override
  String toString() => 'EntryScore(value: $value, definition: $definition)';
}

/// Free-form text input.
class EntryText extends EntryContent {
  const EntryText({this.value, this.definition});

  final String? value;
  final PageText? definition;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EntryText &&
          other.value == value &&
          other.definition == definition;

  @override
  int get hashCode => Object.hash(value, definition);

  @override
  String toString() => 'EntryText(value: $value, definition: $definition)';
}

/// Single-select input.
class EntrySelect extends EntryContent {
  const EntrySelect({this.value, this.definition});

  final String? value;
  final PageSelect? definition;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EntrySelect &&
          other.value == value &&
          other.definition == definition;

  @override
  int get hashCode => Object.hash(value, definition);

  @override
  String toString() => 'EntrySelect(value: $value, definition: $definition)';
}

/// Multi-select input.
class EntryMultiselect extends EntryContent {
  const EntryMultiselect({this.values = const [], this.definition});

  final List<String> values;
  final PageMultiselect? definition;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EntryMultiselect &&
          _listEquals(other.values, values) &&
          other.definition == definition;

  @override
  int get hashCode => Object.hash(Object.hashAll(values), definition);

  @override
  String toString() =>
      'EntryMultiselect(values: $values, definition: $definition)';
}

/// Attachments input. Values are ids returned by upload.
class EntryAttachments extends EntryContent {
  const EntryAttachments({this.attachments = const [], this.definition});

  final List<AttachmentReference> attachments;
  final PageAttachments? definition;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EntryAttachments &&
          _listEquals(other.attachments, attachments) &&
          other.definition == definition;

  @override
  int get hashCode => Object.hash(Object.hashAll(attachments), definition);

  @override
  String toString() =>
      'EntryAttachments(attachments: $attachments, definition: $definition)';
}

/// Reference to an uploaded attachment (id assigned after upload).
class AttachmentReference {
  const AttachmentReference({required this.id});

  final int id;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AttachmentReference && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'AttachmentReference(id: $id)';
}

void _validateScore(int? value) {
  if (value != null && (value < 0 || value > 100)) {
    throw ArgumentError.value(value, 'value', 'must be between 0 and 100');
  }
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
