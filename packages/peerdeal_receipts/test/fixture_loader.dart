import 'dart:convert';
import 'dart:io';

Map<String, dynamic> loadFixture(String name) {
  final file = File('test/fixtures/$name');
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}
