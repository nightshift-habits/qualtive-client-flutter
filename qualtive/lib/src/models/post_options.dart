/// Per-post options for [Qualtive.post].
class PostOptions {
  const PostOptions({
    this.metadataCollection = MetadataCollection.nonPersonal,
    this.userTrackingConsent = UserTrackingConsent.granted,
  });

  /// Whether to attach device/app attributes.
  final MetadataCollection metadataCollection;

  /// Whether a persisted client id may be stored/sent.
  final UserTrackingConsent userTrackingConsent;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostOptions &&
          other.metadataCollection == metadataCollection &&
          other.userTrackingConsent == userTrackingConsent;

  @override
  int get hashCode => Object.hash(metadataCollection, userTrackingConsent);

  @override
  String toString() =>
      'PostOptions(metadataCollection: $metadataCollection, '
      'userTrackingConsent: $userTrackingConsent)';
}

/// How much non-user metadata may be attached for a single post.
///
/// Independent of [UserTrackingConsent], which only controls a persisted
/// client id.
enum MetadataCollection {
  /// Device and app attributes (for example `Platform`, `OS Version`).
  nonPersonal,

  /// No automatic metadata.
  none,
}

/// Whether the user has consented to a persisted client id for a single post.
///
/// [denied] means no client id is stored or sent. Device/app metadata is
/// controlled separately by [MetadataCollection].
enum UserTrackingConsent { granted, denied }
