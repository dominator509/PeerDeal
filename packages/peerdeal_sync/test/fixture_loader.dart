import 'dart:convert';
import 'dart:io';

Map<String, Object?> loadFixture(String relativePath) {
  final file = File(relativePath);
  return jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
}
