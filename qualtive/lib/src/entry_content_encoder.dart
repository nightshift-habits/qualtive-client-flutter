import 'models/entry.dart';
import 'models/page.dart';
import 'models/post_options.dart';
import 'models/score_type.dart';
import 'models/user.dart';

/// Encodes [content] for the `post` method channel.
List<Map<String, Object?>> encodeEntryContent(List<EntryContent> content) {
  return [for (final item in content) _encodeItem(item)];
}

Map<String, Object?>? encodeUser(User? user) {
  if (user == null) {
    return null;
  }
  return <String, Object?>{
    'id': user.id,
    'name': user.name,
    'email': user.email,
  };
}

Map<String, Object?> encodePostOptions(PostOptions options) {
  return <String, Object?>{
    'metadataCollection': switch (options.metadataCollection) {
      MetadataCollection.nonPersonal => 'nonPersonal',
      MetadataCollection.none => 'none',
    },
    'userTrackingConsent': switch (options.userTrackingConsent) {
      UserTrackingConsent.granted => 'granted',
      UserTrackingConsent.denied => 'denied',
    },
  };
}

Map<String, Object?> _encodeItem(EntryContent item) {
  switch (item) {
    case EntryTitle(:final text):
      return <String, Object?>{
        'type': 'title',
        'text': text,
      };
    case EntryScore(:final value, :final definition):
      return <String, Object?>{
        'type': 'score',
        'value': value,
        'scoreType': definition == null
            ? null
            : _scoreTypeToApi(definition.scoreType),
        'leadingText': definition?.leadingText,
        'trailingText': definition?.trailingText,
      };
    case EntryText(:final value, :final definition):
      return <String, Object?>{
        'type': 'text',
        'value': value,
        'storageTarget': definition == null
            ? null
            : _encodeStorageTarget(definition.storageTarget),
      };
    case EntrySelect(:final value):
      return <String, Object?>{
        'type': 'select',
        'value': value,
      };
    case EntryMultiselect(:final values):
      return <String, Object?>{
        'type': 'multiselect',
        'values': values,
      };
    case EntryAttachments(:final attachments):
      return <String, Object?>{
        'type': 'attachments',
        'values': [
          for (final attachment in attachments) <String, Object?>{'id': attachment.id},
        ],
      };
  }
}

Map<String, Object?> _encodeStorageTarget(TextStorageTarget target) {
  switch (target) {
    case TextStorageTargetText():
      return <String, Object?>{'type': 'text'};
    case TextStorageTargetAttribute(:final attribute):
      return <String, Object?>{
        'type': 'attribute',
        'attribute': attribute,
      };
  }
}

String _scoreTypeToApi(ScoreType type) => switch (type) {
  ScoreType.smilies5 => 'smilies5',
  ScoreType.smilies3 => 'smilies3',
  ScoreType.thumbs => 'thumbs',
  ScoreType.nps => 'nps',
  ScoreType.stars5 => 'stars5',
};
