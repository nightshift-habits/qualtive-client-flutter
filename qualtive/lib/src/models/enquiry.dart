import 'container.dart';
import 'entry.dart';
import 'page.dart';
import 'submitted_page.dart';
import 'theme.dart';

/// An enquiry (feedback form) definition from Qualtive.
class Enquiry {
  const Enquiry({
    required this.id,
    required this.slug,
    required this.name,
    required this.pages,
    this.submittedPages = const [],
    required this.theme,
    required this.container,
    this.isUserContactDetailsRequired = false,
  });

  final int id;
  final String slug;
  final String name;
  final List<EnquiryPage> pages;
  final List<SubmittedPage> submittedPages;
  final EnquiryTheme theme;
  final EnquiryContainer container;
  final bool isUserContactDetailsRequired;

  /// Creates a flat list of empty [EntryContent] ready to be filled by the user.
  ///
  /// Pages are flattened. Static page content that is not part of an entry
  /// (body, image, contact details) is omitted.
  List<EntryContent> entryContentTemplate() {
    return [
      for (final page in pages)
        for (final content in page.content) ?_templateContent(content),
    ];
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Enquiry &&
          other.id == id &&
          other.slug == slug &&
          other.name == name &&
          _listEquals(other.pages, pages) &&
          _listEquals(other.submittedPages, submittedPages) &&
          other.theme == theme &&
          other.container == container &&
          other.isUserContactDetailsRequired == isUserContactDetailsRequired;

  @override
  int get hashCode => Object.hash(
    id,
    slug,
    name,
    Object.hashAll(pages),
    Object.hashAll(submittedPages),
    theme,
    container,
    isUserContactDetailsRequired,
  );

  @override
  String toString() =>
      'Enquiry(id: $id, slug: $slug, name: $name, pages: $pages, '
      'submittedPages: $submittedPages, theme: $theme, container: $container, '
      'isUserContactDetailsRequired: $isUserContactDetailsRequired)';
}

EntryContent? _templateContent(PageContent content) {
  switch (content) {
    case PageTitle():
      return EntryTitle(text: content.text, definition: content);
    case PageScore():
      return EntryScore(value: null, definition: content);
    case PageText():
      return EntryText(value: null, definition: content);
    case PageSelect():
      return EntrySelect(value: null, definition: content);
    case PageMultiselect():
      return EntryMultiselect(values: const [], definition: content);
    case PageAttachments():
      return EntryAttachments(attachments: const [], definition: content);
    case PageBody():
    case PageImage():
    case PageContactDetails():
      return null;
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
