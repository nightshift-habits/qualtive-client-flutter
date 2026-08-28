/// MIME type for an uploaded attachment.
///
/// Any MIME string is accepted (for example `application/pdf`, `video/mp4`,
/// `image/jpeg`).
class AttachmentContentType {
  AttachmentContentType(this.mimeType) {
    if (mimeType.trim().isEmpty) {
      throw ArgumentError.value(mimeType, 'mimeType', 'must not be blank');
    }
  }

  /// Convenience for `image/jpeg`.
  static final imageJpeg = AttachmentContentType('image/jpeg');

  /// Convenience for `image/png`.
  static final imagePng = AttachmentContentType('image/png');

  final String mimeType;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttachmentContentType && other.mimeType == mimeType;

  @override
  int get hashCode => mimeType.hashCode;

  @override
  String toString() => 'AttachmentContentType($mimeType)';
}
