import 'package:meta/meta.dart';

@immutable
class AnchorHash {
  const AnchorHash({
    required this.scope,
    required this.value,
  });

  final String scope;
  final String value;

  @override
  bool operator ==(Object other) =>
      other is AnchorHash && other.scope == scope && other.value == value;

  @override
  int get hashCode => Object.hash(scope, value);

  @override
  String toString() => '$scope:$value';
}
