import 'container.dart';
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
