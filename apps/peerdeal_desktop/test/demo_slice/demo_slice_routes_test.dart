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

  test('route map validation accepts mounted routes and explicit aliases', () {
    final validated = DemoSliceRoutes.requireMountedRouteMap(
      <String, int>{
        for (final route in DemoSliceRoutes.mountedRoutes) route.path: 1,
        '/': 1,
      },
      allowedExtraPaths: const <String>{'/'},
    );

    expect(
      validated.keys,
      containsAll(DemoSliceRoutes.mountedRoutes.map((route) => route.path)),
    );
    expect(() => validated['/demo/other'] = 1, throwsUnsupportedError);
  });

  test('route map validation locks canonical route registry metadata', () {
    final validated = DemoSliceRoutes.requireMountedRouteMap(<String, int>{
      for (final route in DemoSliceRoutes.mountedRoutes) route.path: 1,
    });

    expect(validated, hasLength(DemoSliceRoutes.mountedRoutes.length));
    expect(DemoSliceRoutes.mountedRoutes.first.path, DemoSliceRoutes.home);
    expect(
      DemoSliceRoutes.mountedRoutes.map((route) => route.path),
      everyElement(
        allOf(
          startsWith('/demo'),
          isNot(contains('?')),
          isNot(contains('#')),
          isNot(contains('//')),
        ),
      ),
    );
    expect(
      DemoSliceRoutes.mountedRoutes
          .where(
            (route) =>
                route.label.trim().isEmpty || route.surface.trim().isEmpty,
          )
          .toList(),
      isEmpty,
    );
    expect(
      DemoSliceRoutes.primaryNavigation.map((route) => route.path),
      isNot(contains(DemoSliceRoutes.home)),
    );
  });

  test('route map validation rejects missing mounted routes', () {
    final routes = <String, int>{
      for (final route in DemoSliceRoutes.mountedRoutes)
        if (route.path != DemoSliceRoutes.receipt) route.path: 1,
    };

    expect(
      () => DemoSliceRoutes.requireMountedRouteMap(routes),
      throwsA(isA<StateError>()),
    );
  });

  test('route map validation rejects unexpected routes', () {
    final routes = <String, int>{
      for (final route in DemoSliceRoutes.mountedRoutes) route.path: 1,
      '/unexpected': 1,
    };

    expect(
      () => DemoSliceRoutes.requireMountedRouteMap(routes),
      throwsA(isA<StateError>()),
    );
  });
}
