import 'package:peerdeal_desktop/demo_slice/demo_slice_routes.dart';
import 'package:test/test.dart';

void main() {
  test('mounted route registry has unique paths and labels', () {
    final paths = DemoSliceRoutes.mountedRoutes
        .map((route) => route.path)
        .toList(growable: false);
    final labels = DemoSliceRoutes.mountedRoutes
        .map((route) => route.label)
        .toList(growable: false);

    expect(paths.toSet(), hasLength(paths.length));
    expect(labels.toSet(), hasLength(labels.length));
  });

  test('primary navigation covers mounted non-home surfaces', () {
    expect(
      DemoSliceRoutes.primaryNavigation.map((route) => route.path),
      <String>[
        DemoSliceRoutes.table,
        DemoSliceRoutes.chat,
        DemoSliceRoutes.receipt,
        DemoSliceRoutes.join,
        DemoSliceRoutes.setup,
      ],
    );
  });

  test('route lookup resolves known paths and rejects unknown paths', () {
    expect(DemoSliceRoutes.tryByPath(DemoSliceRoutes.table)?.label, 'Table');
    expect(DemoSliceRoutes.tryByPath('/missing'), isNull);
  });
}
