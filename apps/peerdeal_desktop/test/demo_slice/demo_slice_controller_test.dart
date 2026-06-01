import 'package:peerdeal_desktop/demo_slice/controllers/demo_slice_controller.dart';
import 'package:test/test.dart';

void main() {
  test('trySelectScenario selects known scenario', () {
    final controller = DemoSliceController();

    final selected = controller.trySelectScenario(
      'verification_receipt_review',
    );

    expect(selected, isTrue);
    expect(controller.activeScenario.id, 'verification_receipt_review');
  });

  test(
    'trySelectScenario rejects unknown scenario without changing active',
    () {
      final controller = DemoSliceController();
      final initial = controller.activeScenario;

      final selected = controller.trySelectScenario('missing_scenario');

      expect(selected, isFalse);
      expect(controller.activeScenario, same(initial));
    },
  );

  test('selectScenario ignores unknown scenario without throwing', () {
    final controller = DemoSliceController();
    final initial = controller.activeScenario;

    controller.selectScenario('missing_scenario');

    expect(controller.activeScenario, same(initial));
  });
}
