import 'dart:convert';

String canonicalJsonEncode(Object? value) {
  final normalized = _normalize(value);
  return jsonEncode(normalized);
}

Object? _normalize(Object? value) {
  if (value is Map) {
    final keys = value.keys.map((e) => e.toString()).toList()..sort();
    return {
      for (final key in keys) key: _normalize(value[key]),
    };
  }
  if (value is List) {
    return value.map(_normalize).toList();
  }
  return value;
}
