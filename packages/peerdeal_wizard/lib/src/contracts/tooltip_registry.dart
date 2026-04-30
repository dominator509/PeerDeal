import 'package:meta/meta.dart';

@immutable
class TooltipEntry {
  const TooltipEntry({
    required this.key,
    required this.title,
    required this.body,
  });

  final String key;
  final String title;
  final String body;
}

abstract interface class TooltipRegistry {
  TooltipEntry? byKey(String key);
  List<TooltipEntry> all();
}
