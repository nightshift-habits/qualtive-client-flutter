/// Remote file referenced by an enquiry (page image, submitted-page image).
class Attachment {
  const Attachment({required this.url});

  final String url;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Attachment && other.url == url;

  @override
  int get hashCode => url.hashCode;

  @override
  String toString() => 'Attachment(url: $url)';
}
