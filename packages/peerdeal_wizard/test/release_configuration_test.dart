import 'package:peerdeal_wizard/peerdeal_wizard.dart';
import 'package:test/test.dart';

void main() {
  test('rejects invalid configured limits at runtime', () {
    expect(
      () => const DefaultPresetResolver(
        maxPresetLayers: 0,
      ).mergeLayers(const <PresetLayer>[]),
      throwsArgumentError,
    );
  });
}
