import 'dart:async';

import 'package:flutter/services.dart';

import 'secure_key_storage_bridge.dart';
import 'secure_key_storage_bridge_models.dart';
import 'secure_key_storage_channel_contract.dart';

const _secureKeyStorageCallTimeout = Duration(seconds: 5);

class MethodChannelSecureKeyStorageBridge
    implements
        SecureKeyStorageMutationBridge,
        CancellableSecureKeyStorageMutationBridge {
  MethodChannelSecureKeyStorageBridge({
    MethodChannel? channel,
    Duration timeout = _secureKeyStorageCallTimeout,
  }) : _channel = channel ?? const MethodChannel(_channelName),
       _timeout = _validateTimeout(timeout);

  static const _channelName = SecureKeyStorageChannelContract.channelName;

  final MethodChannel _channel;
  final Duration _timeout;

  @override
  Future<SecureKeyStorageSnapshot> loadKeyRing({
    required String namespace,
    Future<void>? cancellation,
  }) async {
    if (!_isValidNamespace(namespace)) {
      return const SecureKeyStorageSnapshot.unavailable(
        warning: 'Secure key storage load request is invalid.',
      );
    }

    final Map<String, Object?>? result;
    try {
      result = await _invokeWithDeadline(
        _channel.invokeMapMethod<String, Object?>(
          SecureKeyStorageChannelContract.loadKeyRingMethod,
          <String, Object?>{'namespace': namespace},
        ),
        cancellation: cancellation,
      );
    } on _SecureKeyStorageCallCancelled {
      return const SecureKeyStorageSnapshot.unavailable(
        warning: 'Secure key storage call cancelled.',
      );
    } on TimeoutException {
      return const SecureKeyStorageSnapshot.unavailable(
        warning: 'Secure key storage call timed out.',
      );
    } on MissingPluginException catch (error) {
      return SecureKeyStorageSnapshot.unavailable(
        warning: _warning('Secure key storage plugin is unavailable', error),
      );
    } on PlatformException catch (error) {
      return SecureKeyStorageSnapshot.unavailable(
        warning: _warning('Secure key storage lookup failed', error),
      );
    } on Object catch (error) {
      return SecureKeyStorageSnapshot.unavailable(
        warning: _warning('Secure key storage payload decode failed', error),
      );
    }

    return SecureKeyStorageChannelContract.decodeSnapshot(result);
  }

  @override
  Future<SecureKeyStorageMutationResult> saveKey({
    required String namespace,
    required SecureKeyRecord key,
    Future<void>? cancellation,
  }) async {
    if (!_isValidNamespace(namespace) || !key.isUsable) {
      return const SecureKeyStorageMutationResult.failure(
        warning: 'Secure key storage save request is invalid.',
      );
    }

    final Map<String, Object?>? result;
    try {
      result = await _invokeWithDeadline(
        _channel.invokeMapMethod<String, Object?>(
          SecureKeyStorageChannelContract.saveKeyMethod,
          <String, Object?>{
            'namespace': namespace,
            'key': SecureKeyStorageChannelContract.encodeKey(key),
          },
        ),
        cancellation: cancellation,
      );
    } on _SecureKeyStorageCallCancelled {
      return const SecureKeyStorageMutationResult.failure(
        warning: 'Secure key storage call cancelled.',
      );
    } on TimeoutException {
      return const SecureKeyStorageMutationResult.failure(
        warning: 'Secure key storage call timed out.',
      );
    } on MissingPluginException catch (error) {
      return SecureKeyStorageMutationResult.failure(
        warning: _warning('Secure key storage plugin is unavailable', error),
      );
    } on PlatformException catch (error) {
      return SecureKeyStorageMutationResult.failure(
        warning: _warning('Secure key storage save failed', error),
      );
    } on Object catch (error) {
      return SecureKeyStorageMutationResult.failure(
        warning: _warning(
          'Secure key storage save result decode failed',
          error,
        ),
      );
    }

    return SecureKeyStorageChannelContract.decodeMutationResult(result);
  }

  @override
  Future<SecureKeyStorageMutationResult> deleteKey({
    required String namespace,
    required String keyId,
    Future<void>? cancellation,
  }) async {
    if (!_isValidNamespace(namespace) || !_isValidKeyId(keyId)) {
      return const SecureKeyStorageMutationResult.failure(
        warning: 'Secure key storage delete request is invalid.',
      );
    }

    final Map<String, Object?>? result;
    try {
      result = await _invokeWithDeadline(
        _channel.invokeMapMethod<String, Object?>(
          SecureKeyStorageChannelContract.deleteKeyMethod,
          <String, Object?>{'namespace': namespace, 'keyId': keyId},
        ),
        cancellation: cancellation,
      );
    } on _SecureKeyStorageCallCancelled {
      return const SecureKeyStorageMutationResult.failure(
        warning: 'Secure key storage call cancelled.',
      );
    } on TimeoutException {
      return const SecureKeyStorageMutationResult.failure(
        warning: 'Secure key storage call timed out.',
      );
    } on MissingPluginException catch (error) {
      return SecureKeyStorageMutationResult.failure(
        warning: _warning('Secure key storage plugin is unavailable', error),
      );
    } on PlatformException catch (error) {
      return SecureKeyStorageMutationResult.failure(
        warning: _warning('Secure key storage delete failed', error),
      );
    } on Object catch (error) {
      return SecureKeyStorageMutationResult.failure(
        warning: _warning(
          'Secure key storage delete result decode failed',
          error,
        ),
      );
    }

    return SecureKeyStorageChannelContract.decodeMutationResult(result);
  }

  bool _isValidNamespace(String namespace) =>
      namespace.trim().isNotEmpty && namespace.trim() == namespace;

  bool _isValidKeyId(String keyId) =>
      keyId.trim().isNotEmpty && keyId.trim() == keyId && !keyId.contains(':');

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
        TimeoutException('Secure key storage call timed out.', _timeout),
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
            const _SecureKeyStorageCallCancelled(),
            StackTrace.current,
          ),
          onError: (Object _, StackTrace _) => completeError(
            const _SecureKeyStorageCallCancelled(),
            StackTrace.current,
          ),
        ),
      );
    }
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

final class _SecureKeyStorageCallCancelled implements Exception {
  const _SecureKeyStorageCallCancelled();
}
