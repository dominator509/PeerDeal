import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../serialization/canonical_json.dart';
import '../serialization/canonical_json_limits.dart';

String computeCanonicalHash(
  Object? payload, {
  CanonicalJsonLimits limits = const CanonicalJsonLimits(),
}) {
  final bytes = utf8.encode(canonicalJsonEncode(payload, limits: limits));
  return sha256.convert(bytes).toString();
}
