import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pubspec description is 50 to 180 characters', () {
    final description = _pubspecDescription();

    expect(description.length, greaterThanOrEqualTo(50));
    expect(description.length, lessThanOrEqualTo(180));
  });
}

String _pubspecDescription() {
  final contents = File('pubspec.yaml').readAsStringSync();
  final match = RegExp(r'^description:\s*(.+)$', multiLine: true)
      .firstMatch(contents);
  expect(match, isNotNull, reason: 'pubspec.yaml is missing description');
  return match!.group(1)!.trim();
}
