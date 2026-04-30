import 'package:meta/meta.dart';

@immutable
class InvariantViolation {
  const InvariantViolation({
    required this.code,
    required this.message,
  });

  final String code;
  final String message;
}
