import 'package:peerdeal_wizard/peerdeal_wizard.dart';
import 'package:test/test.dart';

void main() {
  group('DefaultPresetResolver', () {
    test('later layers override earlier layers deterministically', () {
      const resolver = DefaultPresetResolver();
      const layers = <PresetLayer>[
        PresetLayer(
          presetId: 'builtin_open_table',
          priority: 1,
          values: <String, Object?>{'mode_type': 'open_table', 'seat_count': 6},
          isLockedBuiltin: true,
        ),
        PresetLayer(
          presetId: 'host_override',
          priority: 2,
          values: <String, Object?>{'seat_count': 8},
        ),
      ];

      final result = resolver.mergeLayers(layers);
      expect(result.mergedValues['mode_type'], 'open_table');
      expect(result.mergedValues['seat_count'], 8);
      expect(result.conflicts, isNotEmpty);
    });
  });
}
