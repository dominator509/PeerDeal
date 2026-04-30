import 'package:meta/meta.dart';

@immutable
class ReplayMismatch {
  const ReplayMismatch({
    required this.code,
    required this.message,
    this.expected,
    this.actual,
  });

  final String code;
  final String message;
  final Object? expected;
  final Object? actual;
}
