import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peerdeal_mobile/transport/app_table_session_transport_source.dart';
import 'package:peerdeal_mobile/transport/app_table_session_transport_source_mount.dart';
import 'package:peerdeal_mobile/transport/native_transport_frame_adapter.dart';
import 'package:peerdeal_network/peerdeal_network.dart';

void main() {
  testWidgets('mount starts and disposes its owned source', (tester) async {
    final source = _source();

    await tester.pumpWidget(
      AppTableSessionTransportSourceMount(
        source: source,
        child: const SizedBox(),
      ),
    );
    expect(source.state, AppTableSessionTransportSourceState.running);

    await tester.pumpWidget(const SizedBox());
    expect(source.state, AppTableSessionTransportSourceState.disposed);
  });

  testWidgets('mount disposes the old source when the route source changes', (
    tester,
  ) async {
    final first = _source();
    final second = _source();

    await tester.pumpWidget(
      AppTableSessionTransportSourceMount(
        source: first,
        child: const SizedBox(),
      ),
    );
    await tester.pumpWidget(
      AppTableSessionTransportSourceMount(
        source: second,
        child: const SizedBox(),
      ),
    );

    expect(first.state, AppTableSessionTransportSourceState.disposed);
    expect(second.state, AppTableSessionTransportSourceState.running);

    await tester.pumpWidget(const SizedBox());
    expect(second.state, AppTableSessionTransportSourceState.disposed);
  });
}

AppTableSessionTransportSource _source() {
  return AppTableSessionTransportSource(
    sessionId: 'session_1',
    peerId: 'peer_b',
    drain: () async => const NativeTransportFrameDrainResult(
      available: true,
      results: <TransportFrameReceiveResult>[],
    ),
  );
}
