import '../contracts/tooltip_registry.dart';

class DefaultTooltipRegistry implements TooltipRegistry {
  const DefaultTooltipRegistry();

  static const List<TooltipEntry> _entries = <TooltipEntry>[
    TooltipEntry(
      key: 'mode_type',
      title: 'Table mode',
      body: 'Choose Tournament Mode for structured progression or Open Table Mode for flexible join/leave play.',
    ),
    TooltipEntry(
      key: 'retention_profile',
      title: 'Retention',
      body: 'Controls whether receipts remain standard, timed, manual-wipeable, or strict-ephemeral after session close.',
    ),
    TooltipEntry(
      key: 'table_capture_policy',
      title: 'Capture policy',
      body: 'Controls how strongly the app protects normal gameplay views. Always-sensitive views remain strict regardless of this setting.',
    ),
  ];

  @override
  List<TooltipEntry> all() => _entries;

  @override
  TooltipEntry? byKey(String key) {
    for (final entry in _entries) {
      if (entry.key == key) {
        return entry;
      }
    }
    return null;
  }
}
