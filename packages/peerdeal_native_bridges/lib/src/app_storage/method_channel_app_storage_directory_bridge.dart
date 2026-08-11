import 'dart:async';

import 'package:flutter/services.dart';

import 'app_storage_directory_bridge.dart';
import 'app_storage_directory_bridge_models.dart';
import 'app_storage_directory_channel_contract.dart';

const _appStorageDirectoryCallTimeout = Duration(seconds: 5);

class MethodChannelAppStorageDirectoryBridge
    implements AppStorageDirectoryBridge, CancellableAppStorageDirectoryBridge {
  MethodChannelAppStorageDirectoryBridge({
    MethodChannel? channel,
    Duration timeout = _appStorageDirectoryCallTimeout,
  }) : _channel =
           channel ??
           const MethodChannel(AppStorageDirectoryChannelContract.channelName),
       _timeout = _validateTimeout(timeout);

  final MethodChannel _channel;
  final Duration _timeout;

  @override
  Future<AppStorageDirectorySnapshot> getAppSupportDirectory({
    Future<void>? cancellation,
  }) async {
    final Map<String, Object?>? result;
    try {
      result = await _invokeWithDeadline(
        _channel.invokeMapMethod<String, Object?>(
          AppStorageDirectoryChannelContract.getAppSupportDirectoryMethod,
        ),
        cancellation: cancellation,
      );
    } on _AppStorageDirectoryCallCancelled {
      return const AppStorageDirectorySnapshot.unavailable(
        warning: 'Native app storage directory lookup cancelled.',
      );
    } on TimeoutException {
      return const AppStorageDirectorySnapshot.unavailable(
        warning: 'Native app storage directory lookup timed out.',
      );
    } on MissingPluginException {
      return const AppStorageDirectorySnapshot.unavailable(
        warning: 'Native app storage directory plugin is unavailable.',
      );
    } on PlatformException {
      return const AppStorageDirectorySnapshot.unavailable(
        warning: 'Native app storage directory lookup failed.',
      );
    } on Object {
      return const AppStorageDirectorySnapshot.unavailable(
        warning: 'Native app storage directory lookup failed.',
      );
    }

    return AppStorageDirectoryChannelContract.decodeAppSupportDirectory(result);
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
        TimeoutException(
          'Native app storage directory lookup timed out.',
          _timeout,
        ),
        StackTrace.current,
      ),
    );
    unawaited(
      operation.then<void>(
        completeValue,
        onError: (Object error, StackTrace stackTrace) {
          completeError(error, stackTrace);
        },
      ),
    );

    if (cancellation != null) {
      unawaited(
        cancellation.then<void>(
          (_) => completeError(
            const _AppStorageDirectoryCallCancelled(),
            StackTrace.current,
          ),
          onError: (Object _, StackTrace _) => completeError(
            const _AppStorageDirectoryCallCancelled(),
            StackTrace.current,
          ),
        ),
      );
    }
    return completer.future;
  }
}

final class _AppStorageDirectoryCallCancelled implements Exception {
  const _AppStorageDirectoryCallCancelled();
}
