# Changelog

All notable changes to this project will be documented in this file.

## Unreleased

## 0.0.2

### Added

- Optional `workspaceId` on `Qualtive(...)`, sent as the `X-Workspace` header.

## 0.0.1

- Initial Flutter plugin for iOS and Android.
- Add `Qualtive.fetchEnquiry` with Dart enquiry models over the method channel.
- Add `Qualtive.post`, `uploadAttachmentBytes`, and `uploadAttachmentFile` with Dart entry models.
- Rename enquiry `Page` / `Theme` / `Container` so they do not clash with Flutter widgets.
