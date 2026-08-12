import 'package:meta/meta.dart';

import 'model_collection_ownership.dart';

@immutable
class ProtocolDiagnostic {
  ProtocolDiagnostic({
    required this.code,
    required this.message,
    Object? expected,
    Object? actual,
  }) : expected = freezeProtocolValue(expected),
       actual = freezeProtocolValue(actual);

  final String code;
  final String message;
  final Object? expected;
  final Object? actual;

  Map<String, Object?> toJson() => {
    'code': code,
    'message': message,
    if (expected != null) 'expected': expected,
    if (actual != null) 'actual': actual,
  };
}
