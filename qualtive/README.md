# Qualtive Client Library for Flutter

## Installation

Add the library as a Flutter dependency:

```
flutter pub add qualtive
```

Or in `pubspec.yaml`:

```
dependencies:
  qualtive: ^0.0.1
```

Minimum versions: iOS 15, Android API 24.

This library targets iOS and Android. The Dart API is the public surface; native SDKs are wrapped on those platforms.

## Usage

First of all, make sure you have created a question on [qualtive.io](https://qualtive.io). Each feedback entry is posted to an enquiry (ID or slug) within your container.

Optionally pass a workspace slug. When omitted, the user API uses the container's default workspace.

```dart
final qualtive = Qualtive(
  containerId: 'my-company',
  workspaceId: 'my-department',
);
```

### Fetching an enquiry

```dart
import 'package:qualtive/qualtive.dart';

final qualtive = Qualtive(containerId: 'my-company');
final enquiry = await qualtive.fetchEnquiry('my-enquiry');
print(enquiry.name);
```

### Using custom UI

To post a feedback entry:

```dart
final qualtive = Qualtive(containerId: 'my-company');

await qualtive.post(
  'my-enquiry',
  content: [
    EntryScore(value: 75),
    EntryText(value: 'Hello world!'),
  ],
);
```

If users can log in on your app, include a user describing them:

```dart
await qualtive.post(
  'my-enquiry',
  content: [
    EntryScore(value: 75),
    EntryText(value: 'Hello world!'),
  ],
  user: User(
    id: 'user-123',
    name: 'Steve',
    email: 'steve@gmail.com',
  ),
);
```

You can include custom attributes that will be shown on [qualtive.io](https://qualtive.io):

```dart
await qualtive.post(
  'my-enquiry',
  content: [
    EntryScore(value: 75),
  ],
  customAttributes: {
    'age': 22,
  },
);
```

Privacy options apply to that post only:

```dart
await qualtive.post(
  'my-enquiry',
  content: [
    EntryText(value: 'Hello'),
  ],
  options: PostOptions(
    metadataCollection: MetadataCollection.nonPersonal,
    userTrackingConsent: UserTrackingConsent.granted,
  ),
);
```

Attachments upload first, then reference the returned id:

```dart
final image = await qualtive.uploadAttachmentBytes(
  pngBytes,
  contentType: AttachmentContentType.imagePng,
);
await qualtive.post(
  'my-enquiry',
  content: [
    EntryAttachments(attachments: [image]),
  ],
);
```

Prefer `uploadAttachmentFile` for photos and especially video. Pass a filesystem path, `file://` URL, or (on Android) a `content://` URI.
