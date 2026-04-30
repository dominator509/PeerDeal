import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../serialization/canonical_json.dart';

String computeCanonicalHash(Object? payload) {
  final bytes = utf8.encode(canonicalJsonEncode(payload));
  return sha256.convert(bytes).toString();
}
