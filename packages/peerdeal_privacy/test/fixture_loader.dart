import 'dart:convert';
import 'dart:io';

Map<String, Object?> loadFixture(String name) {
  final packageLocal = File('test/fixtures/$name');
  final workspaceLocal = File('packages/peerdeal_privacy/test/fixtures/$name');
  final file = packageLocal.existsSync() ? packageLocal : workspaceLocal;
  return jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
}
