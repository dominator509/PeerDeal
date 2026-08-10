import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('release Android manifest declares the native network permission', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml');

    expect(manifest.existsSync(), isTrue);
    expect(
      manifest.readAsStringSync(),
      contains(
        '<uses-permission android:name="android.permission.INTERNET" />',
      ),
    );
  });
}
