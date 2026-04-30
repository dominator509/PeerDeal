import 'package:meta/meta.dart';

@immutable
class ReducerContext {
  const ReducerContext({
    required this.protocolVersion,
    required this.strictInvariantMode,
  });

  final String protocolVersion;
  final bool strictInvariantMode;
}
