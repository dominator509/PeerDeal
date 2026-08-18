import 'dart:async';

import 'package:flutter/services.dart';

import 'local_network_channel_contract.dart';
import 'local_network_bridge.dart';
import 'local_network_bridge_models.dart';

const _localNetworkCallTimeout = Duration(seconds: 5);

class MethodChannelLocalNetworkBridge
    implements LocalNetworkBridge, CancellableLocalNetworkBridge {
  MethodChannelLocalNetworkBridge({
    MethodChannel? channel,
    Duration timeout = _localNetworkCallTimeout,
    Future<void>? cancellation,
  }) : _channel = channel ?? const MethodChannel(_channelName),
       _timeout = _validateTimeout(timeout),
       _cancellation = cancellation;

  static const _channelName = LocalNetworkChannelContract.channelName;

  final MethodChannel _channel;
  final Duration _timeout;
  final Future<void>? _cancellation;

  @override
  Future<LocalNetworkCapability> getCapability({
    Future<void>? cancellation,
  }) async {
    final Map<String, Object?>? result;
    try {
      result = await _invokeWithDeadline(
        _channel.invokeMapMethod<String, Object?>('getCapability'),
        cancellation: cancellation,
      );
    } on _LocalNetworkCallCancelled {
      return const LocalNetworkCapability.unavailable(
        warning: 'Local network call cancelled.',
      );
    } on TimeoutException {
      return const LocalNetworkCapability.unavailable(
        warning: 'Local network call timed out.',
      );
    } on MissingPluginException catch (error) {
      return LocalNetworkCapability.unavailable(
        warning: _warning('Local network plugin is unavailable', error),
      );
    } on PlatformException catch (error) {
      return LocalNetworkCapability.unavailable(
        warning: _warning('Local network capability lookup failed', error),
      );
    } on Object catch (error) {
      return LocalNetworkCapability.unavailable(
        warning: _warning(
          'Local network capability payload decode failed',
          error,
        ),
      );
    }

    return LocalNetworkChannelContract.decodeCapability(result);
  }

  @override
  Future<LocalNetworkDiscoverySnapshot> discoverPeers({
    Future<void>? cancellation,
  }) async {
    final Map<String, Object?>? result;
    try {
      result = await _invokeWithDeadline(
        _channel.invokeMapMethod<String, Object?>('discoverPeers'),
        cancellation: cancellation,
      );
    } on _LocalNetworkCallCancelled {
      return const LocalNetworkDiscoverySnapshot.unavailable(
        warning: 'Local network call cancelled.',
      );
    } on TimeoutException {
      return const LocalNetworkDiscoverySnapshot.unavailable(
        warning: 'Local network call timed out.',
      );
    } on MissingPluginException catch (error) {
      return LocalNetworkDiscoverySnapshot.unavailable(
        warning: _warning('Local network plugin is unavailable', error),
      );
    } on PlatformException catch (error) {
      return LocalNetworkDiscoverySnapshot.unavailable(
        warning: _warning('Local network discovery failed', error),
      );
    } on Object catch (error) {
      return LocalNetworkDiscoverySnapshot.unavailable(
        warning: _warning(
          'Local network discovery payload decode failed',
          error,
        ),
      );
    }

    return LocalNetworkChannelContract.decodeDiscoverySnapshot(result);
  }

  static Duration _validateTimeout(Duration timeout) {
    if (timeout.compareTo(Duration.zero) <= 0) {
      throw ArgumentError.value(timeout, 'timeout', 'must be positive');
    }
    return timeout;
  }

  Future<T> _invokeWithDeadline<T>(
    Future<T> operation, {
    Future<void>? cancellation,
  }) {
    final completer = Completer<T>();
    Timer? timer;
    var completed = false;

    void completeValue(T value) {
      if (completed) return;
      completed = true;
      timer?.cancel();
      completer.complete(value);
    }

    void completeError(Object error, StackTrace stackTrace) {
      if (completed) return;
      completed = true;
      timer?.cancel();
      completer.completeError(error, stackTrace);
    }

    timer = Timer(
      _timeout,
      () => completeError(
        TimeoutException('Local network call timed out.', _timeout),
        StackTrace.current,
      ),
    );
    final cancellationSignals = <Future<void>>[];
    if (_cancellation case final cancellationSignal?) {
      cancellationSignals.add(cancellationSignal);
    }
    if (cancellation case final cancellationSignal?) {
      cancellationSignals.add(cancellationSignal);
    }
    for (final cancellationSignal in cancellationSignals) {
      unawaited(
        cancellationSignal.then<void>(
          (_) => completeError(
            const _LocalNetworkCallCancelled(),
            StackTrace.current,
          ),
          onError: (Object _, StackTrace _) => completeError(
            const _LocalNetworkCallCancelled(),
            StackTrace.current,
          ),
        ),
      );
    }
    unawaited(
      operation.then<void>(
        completeValue,
        onError: (Object error, StackTrace stackTrace) {
          completeError(error, stackTrace);
        },
      ),
    );
    return completer.future;
  }

  String _warning(String prefix, Object error) {
    if (error is PlatformException) {
      final message = error.message;
      return message == null || message.isEmpty
          ? '$prefix: ${error.code}.'
          : '$prefix: ${error.code} - $message';
    }
    return '$prefix: $error';
  }
}

final class _LocalNetworkCallCancelled implements Exception {
  const _LocalNetworkCallCancelled();
}
