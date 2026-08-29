import 'dart:async';

import 'package:peerdeal_desktop/transport/app_table_session_transport_source.dart';
import 'package:peerdeal_desktop/transport/native_transport_frame_adapter.dart';
import 'package:peerdeal_network/peerdeal_network.dart';
import 'package:test/test.dart';

void main() {
  test('copies and freezes transport poll warnings', () {
    final warnings = <String>['warning_1'];
    final result = AppTableSessionTransportPollResult.unavailable(
      warnings: warnings,
    );

    warnings.add('warning_2');
    expect(result.warnings, ['warning_1']);
    expect(() => result.warnings.add('warning_3'), throwsUnsupportedError);
  });

  test('copies and freezes transport start warnings', () {
    final warnings = <String>['warning_1'];
    final result = AppTableSessionTransportSourceStartResult.unavailable(
      warnings: warnings,
    );

    warnings.add('warning_2');
    expect(result.warnings, ['warning_1']);
    expect(() => result.warnings.add('warning_3'), throwsUnsupportedError);
  });

  test('bounds direct transport result warnings', () {
    final warnings = List<String>.generate(5, (index) => 'warning_$index');
    final poll = AppTableSessionTransportPollResult.unavailable(
      warnings: warnings,
    );
    final start = AppTableSessionTransportSourceStartResult.unavailable(
      warnings: warnings,
    );

    expect(poll.warnings, [
      'warning_0',
      'warning_1',
      'warning_2',
      'Native transport source warnings truncated.',
    ]);
    expect(start.warnings, poll.warnings);
  });

  test('polls a drain and counts accepted and rejected frames', () async {
    final source = AppTableSessionTransportSource(
      sessionId: 'session_1',
      peerId: 'peer_b',
      drain: () async => NativeTransportFrameDrainResult(
        available: true,
        results: <TransportFrameReceiveResult>[
          const TransportFrameReceiveResult.accepted(),
          TransportFrameReceiveResult.rejected(
            reasonCode: 'ERR_EVENT_REJECTED',
          ),
        ],
        warnings: const <String>['transport warning'],
      ),
    );

    final result = await source.pollNow();

    expect(result.available, isTrue);
    expect(result.receivedFrameCount, 2);
    expect(result.acceptedFrameCount, 1);
    expect(result.rejectedFrameCount, 1);
    expect(result.hasRejectedFrames, isTrue);
    expect(result.warnings, ['transport warning']);
    expect(source.lastPoll, same(result));
  });

  test('serializes concurrent polls onto one native drain call', () async {
    final completer = Completer<NativeTransportFrameDrainResult>();
    var drainCalls = 0;
    final source = AppTableSessionTransportSource(
      sessionId: 'session_1',
      peerId: 'peer_b',
      drain: () {
        drainCalls += 1;
        return completer.future;
      },
    );

    final first = source.pollNow();
    final second = source.pollNow();
    expect(drainCalls, 1);

    completer.complete(
      NativeTransportFrameDrainResult(
        available: true,
        results: <TransportFrameReceiveResult>[],
      ),
    );

    final firstResult = await first;
    final secondResult = await second;
    expect(firstResult.available, isTrue);
    expect(secondResult.available, isTrue);
    expect(drainCalls, 1);
  });

  test(
    'cancels a pending drain without starting an overlapping poll',
    () async {
      final drainResult = Completer<NativeTransportFrameDrainResult>();
      final cancellation = Completer<void>();
      var drainCalls = 0;
      final source = AppTableSessionTransportSource(
        sessionId: 'session_1',
        peerId: 'peer_b',
        cancellation: cancellation.future,
        drain: () {
          drainCalls += 1;
          return drainResult.future;
        },
      );

      final first = source.pollNow();
      cancellation.complete();

      final firstResult = await first;
      final secondResult = await source.pollNow();
      expect(firstResult.available, isFalse);
      expect(firstResult.warnings, ['Native transport source poll cancelled.']);
      expect(secondResult.warnings, [
        'Native transport source poll cancelled.',
      ]);
      expect(drainCalls, 1);

      source.dispose();
      drainResult.complete(
        NativeTransportFrameDrainResult(
          available: true,
          results: <TransportFrameReceiveResult>[],
        ),
      );
    },
  );

  test('cancellation wins over an immediately completing poll', () async {
    final source = AppTableSessionTransportSource(
      sessionId: 'session_1',
      peerId: 'peer_b',
      cancellation: Future<void>.value(),
      drain: () async => NativeTransportFrameDrainResult(
        available: true,
        results: const <TransportFrameReceiveResult>[],
      ),
    );

    final result = await source.pollNow();

    expect(result.available, isFalse);
    expect(result.warnings, ['Native transport source poll cancelled.']);
    source.dispose();
  });

  test('stops active polling when external cancellation wins', () async {
    _FakeTimer? timer;
    final cancellation = Completer<void>();
    var drainCalls = 0;
    final source = AppTableSessionTransportSource(
      sessionId: 'session_1',
      peerId: 'peer_b',
      cancellation: cancellation.future,
      timerFactory: (interval, callback) {
        timer = _FakeTimer(callback);
        return timer!;
      },
      drain: () async {
        drainCalls += 1;
        return NativeTransportFrameDrainResult(
          available: true,
          results: const <TransportFrameReceiveResult>[],
        );
      },
    );

    expect(source.start().started, isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(drainCalls, 1);

    cancellation.complete();
    await Future<void>.delayed(Duration.zero);

    expect(source.state, AppTableSessionTransportSourceState.stopped);
    expect(source.start().isSuccess, isFalse);
    timer!.fire();
    await Future<void>.delayed(Duration.zero);
    final result = await source.pollNow();
    expect(result.available, isFalse);
    expect(result.warnings, ['Native transport source poll cancelled.']);
    expect(drainCalls, 1);
  });

  test('disposal cancels a pending drain owned by the source', () async {
    final drainResult = Completer<NativeTransportFrameDrainResult>();
    final source = AppTableSessionTransportSource(
      sessionId: 'session_1',
      peerId: 'peer_b',
      drain: () => drainResult.future,
    );

    final poll = source.pollNow();
    source.dispose();

    final result = await poll;
    expect(result.available, isFalse);
    expect(result.warnings, ['Native transport source poll cancelled.']);

    drainResult.complete(
      NativeTransportFrameDrainResult(
        available: true,
        results: <TransportFrameReceiveResult>[],
      ),
    );
  });

  test('propagates source disposal into a cancellable drain', () async {
    final drainResult = Completer<NativeTransportFrameDrainResult>();
    final cancellationObserved = Completer<void>();
    final source = AppTableSessionTransportSource(
      sessionId: 'session_1',
      peerId: 'peer_b',
      drain: () => drainResult.future,
      drainWithCancellation: (cancellation) {
        cancellation.then<void>((_) {
          if (!cancellationObserved.isCompleted) {
            cancellationObserved.complete();
          }
        });
        return drainResult.future;
      },
    );

    final poll = source.pollNow();
    source.dispose();

    await cancellationObserved.future;
    final result = await poll;
    expect(result.available, isFalse);
    expect(result.warnings, ['Native transport source poll cancelled.']);

    drainResult.complete(
      NativeTransportFrameDrainResult(
        available: true,
        results: <TransportFrameReceiveResult>[],
      ),
    );
  });

  test('rejects invalid scope and poll interval before draining', () async {
    var drainCalls = 0;
    Future<NativeTransportFrameDrainResult> drain() async {
      drainCalls += 1;
      return NativeTransportFrameDrainResult(
        available: true,
        results: <TransportFrameReceiveResult>[],
      );
    }

    final invalidScope = AppTableSessionTransportSource(
      sessionId: ' session_1',
      peerId: 'peer_b',
      drain: drain,
    );
    final invalidInterval = AppTableSessionTransportSource(
      sessionId: 'session_1',
      peerId: 'peer_b',
      pollInterval: const Duration(milliseconds: 1),
      drain: drain,
    );

    final scopeResult = await invalidScope.pollNow();
    final intervalResult = invalidInterval.start();

    expect(scopeResult.available, isFalse);
    expect(scopeResult.warnings, ['Native transport source scope is invalid.']);
    expect(intervalResult.isSuccess, isFalse);
    expect(intervalResult.warnings, [
      'Native transport source poll interval is invalid.',
    ]);
    expect(drainCalls, 0);
  });

  test(
    'rejects control-bearing and oversized scopes before source start or poll',
    () async {
      final invalidScopes = <List<String>>[
        <String>['session_${String.fromCharCode(1)}', 'peer_b'],
        <String>['session_1', 'peer_${String.fromCharCode(0x85)}'],
        <String>['x' * 257, 'peer_b'],
        <String>['session_1', 'none'],
        <String>['session_1', 'unresolved'],
        <String>['session_1', 'peer::reserved'],
      ];

      for (final scopes in invalidScopes) {
        var drainCalls = 0;
        final source = AppTableSessionTransportSource(
          sessionId: scopes[0],
          peerId: scopes[1],
          drain: () async {
            drainCalls += 1;
            return NativeTransportFrameDrainResult(
              available: true,
              results: <TransportFrameReceiveResult>[],
            );
          },
        );

        final start = source.start();
        final poll = await source.pollNow();
        expect(start.isSuccess, isFalse);
        expect(start.warnings, ['Native transport source scope is invalid.']);
        expect(poll.available, isFalse);
        expect(poll.warnings, ['Native transport source scope is invalid.']);
        expect(drainCalls, 0);
      }
    },
  );

  test('bounds and scrubs source warnings', () async {
    final source = AppTableSessionTransportSource(
      sessionId: 'session_1',
      peerId: 'peer_b',
      drain: () async => NativeTransportFrameDrainResult(
        available: false,
        results: const <TransportFrameReceiveResult>[],
        warnings: <String>[
          ' first',
          'a' * 200,
          'line\nfeed',
          'warning_1',
          'warning_2',
          'warning_3',
        ],
      ),
    );

    final result = await source.pollNow();

    expect(result.available, isFalse);
    expect(result.warnings, [
      'Native transport source warning unavailable.',
      'Native transport source warning unavailable.',
      'Native transport source warning unavailable.',
      'Native transport source warnings truncated.',
    ]);
  });

  test('starts, serializes timer polls, and stops cleanly', () async {
    _FakeTimer? timer;
    var drainCalls = 0;
    final source = AppTableSessionTransportSource(
      sessionId: 'session_1',
      peerId: 'peer_b',
      timerFactory: (interval, callback) {
        expect(interval, const Duration(seconds: 1));
        timer = _FakeTimer(callback);
        return timer!;
      },
      drain: () async {
        drainCalls += 1;
        return NativeTransportFrameDrainResult(
          available: true,
          results: <TransportFrameReceiveResult>[],
        );
      },
    );

    expect(source.start().started, isTrue);
    expect(source.start().alreadyRunning, isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(drainCalls, 1);

    timer!.fire();
    await Future<void>.delayed(Duration.zero);
    expect(drainCalls, 2);

    source.stop();
    expect(source.state, AppTableSessionTransportSourceState.stopped);
    timer!.fire();
    await Future<void>.delayed(Duration.zero);
    expect(drainCalls, 2);
  });

  test('disposes and fails closed on future polls', () async {
    final source = AppTableSessionTransportSource(
      sessionId: 'session_1',
      peerId: 'peer_b',
      drain: () async => NativeTransportFrameDrainResult(
        available: true,
        results: <TransportFrameReceiveResult>[],
      ),
    );

    source.dispose();

    final start = source.start();
    final poll = await source.pollNow();

    expect(source.state, AppTableSessionTransportSourceState.disposed);
    expect(start.isSuccess, isFalse);
    expect(start.warnings, ['Native transport source is disposed.']);
    expect(poll.available, isFalse);
    expect(poll.warnings, ['Native transport source is disposed.']);
  });
}

class _FakeTimer implements Timer {
  _FakeTimer(this._callback);

  final void Function(Timer timer) _callback;
  bool _isActive = true;
  int _tick = 0;

  void fire() {
    if (!_isActive) return;
    _tick += 1;
    _callback(this);
  }

  @override
  void cancel() {
    _isActive = false;
  }

  @override
  bool get isActive => _isActive;

  @override
  int get tick => _tick;
}
