import 'package:meta/meta.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';

@immutable
class ReplayMismatch {
  ReplayMismatch({
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

  ProtocolDiagnostic toProtocolDiagnostic() {
    return ProtocolDiagnostic(
      code: code,
      message: message,
      expected: expected,
      actual: actual,
    );
  }
}
