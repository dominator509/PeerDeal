import 'package:peerdeal_mobile/demo_slice/demo_slice_routes.dart';
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

  test('enabled mounted route subset keeps home and selected routes', () {
    final enabled = DemoSliceRoutes.enabledMountedRoutes(const <String>{
      DemoSliceRoutes.home,
      DemoSliceRoutes.table,
    });

    expect(enabled.map((route) => route.path), <String>[
      DemoSliceRoutes.home,
      DemoSliceRoutes.table,
    ]);
    expect(
      DemoSliceRoutes.enabledPrimaryNavigation(const <String>{
        DemoSliceRoutes.home,
        DemoSliceRoutes.table,
      }).map((route) => route.path),
      <String>[DemoSliceRoutes.table],
    );
  });

  test('enabled mounted route subset rejects unsafe route config', () {
    expect(
      () => DemoSliceRoutes.enabledMountedRoutes(const <String>{
        DemoSliceRoutes.table,
      }),
      throwsA(isA<StateError>()),
    );
    expect(
      () => DemoSliceRoutes.enabledMountedRoutes(const <String>{
        DemoSliceRoutes.home,
        '/demo/missing',
      }),
      throwsA(isA<StateError>()),
    );
    expect(
      () => DemoSliceRoutes.enabledMountedRoutes(const <String>{
        DemoSliceRoutes.home,
        '${DemoSliceRoutes.table} ',
      }),
      throwsA(isA<StateError>()),
    );
    expect(
      () => DemoSliceRoutes.enabledMountedRoutes(const <String>{
        DemoSliceRoutes.home,
        r'/demo\table',
      }),
      throwsA(isA<StateError>()),
    );
    expect(
      () => DemoSliceRoutes.enabledMountedRoutes(<String>{
        DemoSliceRoutes.home,
        '/demo/${List.filled(120, 'a').join()}',
      }),
      throwsA(isA<StateError>()),
    );
  });

  test('enabled mounted route subset does not echo unknown paths', () {
    expect(
      () => DemoSliceRoutes.enabledMountedRoutes(const <String>{
        DemoSliceRoutes.home,
        '/demo/missing-secret-token',
      }),
      throwsA(
        isA<StateError>().having(
          (error) => error.toString(),
          'message',
          isNot(contains('missing-secret-token')),
        ),
      ),
    );
  });

  test('enabled mounted route subset rejects excessive route config', () {
    expect(
      () => DemoSliceRoutes.enabledMountedRoutes(<String>{
        DemoSliceRoutes.home,
        for (var index = 0; index < 6; index++) '/demo/extra-$index',
      }),
      throwsA(isA<StateError>()),
    );
  });

  test('route map validation accepts mounted routes and explicit aliases', () {
    final validated = DemoSliceRoutes.requireMountedRouteMap(
      <String, int>{
        for (final route in DemoSliceRoutes.mountedRoutes) route.path: 1,
        '/': 1,
        '/table-live': 1,
      },
      allowedExtraPaths: const <String>{'/', '/table-live'},
    );

    expect(
      validated.keys,
      containsAll(DemoSliceRoutes.mountedRoutes.map((route) => route.path)),
    );
    expect(validated.keys, contains('/table-live'));
    expect(() => validated['/demo/other'] = 1, throwsUnsupportedError);
  });

  test('route map validation rejects unsafe allowed extra paths', () {
    final routes = <String, int>{
      for (final route in DemoSliceRoutes.mountedRoutes) route.path: 1,
    };

    expect(
      () => DemoSliceRoutes.requireMountedRouteMap(
        routes,
        allowedExtraPaths: const <String>{'/demo/other'},
      ),
      throwsA(isA<StateError>()),
    );
    expect(
      () => DemoSliceRoutes.requireMountedRouteMap(
        routes,
        allowedExtraPaths: const <String>{'/Demo/other'},
      ),
      throwsA(isA<StateError>()),
    );
    expect(
      () => DemoSliceRoutes.requireMountedRouteMap(
        routes,
        allowedExtraPaths: const <String>{'/table-live '},
      ),
      throwsA(isA<StateError>()),
    );
    expect(
      () => DemoSliceRoutes.requireMountedRouteMap(
        routes,
        allowedExtraPaths: const <String>{r'/table\live'},
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('route map validation rejects case-colliding allowed extra paths', () {
    final routes = <String, int>{
      for (final route in DemoSliceRoutes.mountedRoutes) route.path: 1,
      '/table-live': 1,
      '/Table-Live': 1,
    };

    expect(
      () => DemoSliceRoutes.requireMountedRouteMap(
        routes,
        allowedExtraPaths: const <String>{'/table-live', '/Table-Live'},
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('route map validation rejects excessive allowed extra paths', () {
    final routes = <String, int>{
      for (final route in DemoSliceRoutes.mountedRoutes) route.path: 1,
    };

    expect(
      () => DemoSliceRoutes.requireMountedRouteMap(
        routes,
        allowedExtraPaths: <String>{
          for (var index = 0; index < 26; index++) '/production-$index',
        },
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('route map validation accepts an enabled route subset', () {
    final expectedRoutes = DemoSliceRoutes.enabledMountedRoutes(const <String>{
      DemoSliceRoutes.home,
      DemoSliceRoutes.table,
    });
    final validated = DemoSliceRoutes.requireMountedRouteMap(
      <String, int>{for (final route in expectedRoutes) route.path: 1, '/': 1},
      expectedRoutes: expectedRoutes,
      allowedExtraPaths: const <String>{'/'},
    );

    expect(
      validated.keys,
      containsAll(<String>[DemoSliceRoutes.home, DemoSliceRoutes.table]),
    );
    expect(validated.keys, isNot(contains(DemoSliceRoutes.receipt)));
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
          isNot(contains(r'\')),
        ),
      ),
    );
    expect(
      DemoSliceRoutes.mountedRoutes
          .where(
            (route) =>
                route.label.trim().isEmpty ||
                route.surface.trim().isEmpty ||
                route.label.length > 48 ||
                route.surface.length > 64 ||
                route.label.codeUnits.any(
                  (codeUnit) => codeUnit < 0x20 || codeUnit == 0x7F,
                ) ||
                route.surface.codeUnits.any(
                  (codeUnit) => codeUnit < 0x20 || codeUnit == 0x7F,
                ),
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
      '/unexpected-secret-token': 1,
    };

    expect(
      () => DemoSliceRoutes.requireMountedRouteMap(routes),
      throwsA(
        isA<StateError>().having(
          (error) => error.toString(),
          'message',
          isNot(contains('unexpected-secret-token')),
        ),
      ),
    );
  });
}
