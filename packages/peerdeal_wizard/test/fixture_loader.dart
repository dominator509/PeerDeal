import 'dart:convert';
import 'dart:io';

Map<String, Object?> loadFixture(String name) {
  final file = File('test/fixtures/$name');
  return jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
}
