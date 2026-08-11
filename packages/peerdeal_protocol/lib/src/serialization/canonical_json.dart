import 'dart:convert';

import 'canonical_json_limits.dart';

String canonicalJsonEncode(
  Object? value, {
  CanonicalJsonLimits limits = const CanonicalJsonLimits(),
}) {
  limits.validate();
  final writer = _CanonicalJsonWriter(limits);
  writer.write(value, 0);
  return writer.result;
}

class _CanonicalJsonWriter {
  _CanonicalJsonWriter(this.limits);

  final CanonicalJsonLimits limits;
  final _buffer = StringBuffer();
  var _encodedBytes = 0;
  var _nodes = 0;

  String get result => _buffer.toString();

  void write(Object? value, int depth) {
    _checkDepth(depth);
    _consumeNode();
    if (value is Map) {
      _writeMap(value, depth);
      return;
    }
    if (value is List) {
      _writeList(value, depth);
      return;
    }
    if (value is String) {
      _checkText(value, 'Canonical JSON text');
    } else if (value is num) {
      if (value is double && !value.isFinite) {
        throw const FormatException(
          'Canonical JSON contains a non-finite number.',
        );
      }
    } else if (value is! bool && value != null) {
      throw const FormatException(
        'Canonical JSON contains an unsupported value.',
      );
    }
    _appendEncoded(value);
  }

  void _writeMap(Map<dynamic, dynamic> value, int depth) {
    if (value.length > limits.maxMapEntries) {
      throw const FormatException(
        'Canonical JSON object has too many entries.',
      );
    }
    final entries = <MapEntry<String, Object?>>[];
    for (final entry in value.entries) {
      if (entry.key is! String) {
        throw const FormatException(
          'Canonical JSON object contains a non-string key.',
        );
      }
      final key = entry.key as String;
      _checkText(key, 'Canonical JSON object key');
      entries.add(MapEntry(key, entry.value));
    }
    entries.sort((a, b) => a.key.compareTo(b.key));

    _append('{');
    for (var index = 0; index < entries.length; index += 1) {
      if (index > 0) _append(',');
      _appendEncoded(entries[index].key);
      _append(':');
      write(entries[index].value, depth + 1);
    }
    _append('}');
  }

  void _writeList(List<dynamic> value, int depth) {
    if (value.length > limits.maxListItems) {
      throw const FormatException('Canonical JSON array has too many items.');
    }

    _append('[');
    for (var index = 0; index < value.length; index += 1) {
      if (index > 0) _append(',');
      write(value[index], depth + 1);
    }
    _append(']');
  }

  void _checkDepth(int depth) {
    if (depth > limits.maxDepth) {
      throw const FormatException('Canonical JSON nesting is too deep.');
    }
  }

  void _consumeNode() {
    _nodes += 1;
    if (_nodes > limits.maxNodes) {
      throw const FormatException('Canonical JSON contains too many nodes.');
    }
  }

  void _checkText(String value, String label) {
    if (utf8.encode(value).length > limits.maxTextBytes) {
      throw FormatException('$label exceeds its configured byte limit.');
    }
  }

  void _appendEncoded(Object? value) {
    late final String encoded;
    try {
      encoded = jsonEncode(value);
    } on Object {
      throw const FormatException('Canonical JSON value is not encodable.');
    }
    _append(encoded);
  }

  void _append(String value) {
    _encodedBytes += utf8.encode(value).length;
    if (_encodedBytes > limits.maxEncodedBytes) {
      throw const FormatException('Canonical JSON payload is too large.');
    }
    _buffer.write(value);
  }
}
