import 'dart:convert';
import 'dart:io';

class FixtureLoader {
  const FixtureLoader();

  Map<String, Object?> loadJsonObject(String path) {
    final file = File(path);
    return jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
  }
}
