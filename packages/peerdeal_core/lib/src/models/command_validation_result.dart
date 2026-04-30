import 'package:meta/meta.dart';

@immutable
class CommandValidationResult {
  const CommandValidationResult({
    required this.isAccepted,
    required this.resultCode,
    required this.message,
  });

  const CommandValidationResult.accepted()
      : isAccepted = true,
        resultCode = 'OK_ACCEPTED',
        message = 'Command accepted.';

  const CommandValidationResult.rejected({
    required this.resultCode,
    required this.message,
  }) : isAccepted = false;

  final bool isAccepted;
  final String resultCode;
  final String message;
}
