import 'dart:async';

import 'package:flutter/services.dart';

import 'capture_protection_channel_contract.dart';
import 'capture_protection_bridge.dart';
import 'capture_protection_bridge_models.dart';

const _captureProtectionCallTimeout = Duration(seconds: 5);

class MethodChannelCaptureProtectionBridge
    implements CaptureProtectionBridge, CaptureProtectionActionBridge {
  MethodChannelCaptureProtectionBridge({
    MethodChannel? channel,
    Duration timeout = _captureProtectionCallTimeout,
  }) : _channel = channel ?? const MethodChannel(_channelName),
       _timeout = _validateTimeout(timeout);

  static const _channelName = CaptureProtectionChannelContract.channelName;

  final MethodChannel _channel;
  final Duration _timeout;

  @override
  Future<CaptureProtectionCapability> getCapability() async {
    final Map<String, Object?>? result;
    try {
      result = await _channel
          .invokeMapMethod<String, Object?>('getCapability')
          .timeout(_timeout);
    } on TimeoutException {
      return const CaptureProtectionCapability.unavailable(
        warning: 'Capture protection call timed out.',
      );
    } on MissingPluginException catch (error) {
      return CaptureProtectionCapability.unavailable(
        warning: _warning('Capture protection plugin is unavailable', error),
      );
    } on PlatformException catch (error) {
      return CaptureProtectionCapability.unavailable(
        warning: _warning('Capture protection capability lookup failed', error),
      );
    } on Object catch (error) {
      return CaptureProtectionCapability.unavailable(
        warning: _warning('Capture protection payload decode failed', error),
      );
    }

    return CaptureProtectionChannelContract.decodeCapability(result);
  }

  @override
  Future<CaptureProtectionActionResult> setBlocking({
    required bool enabled,
  }) async {
    final Map<String, Object?>? result;
    try {
      result = await _channel
          .invokeMapMethod<String, Object?>(
            CaptureProtectionChannelContract.setBlockingMethod,
            CaptureProtectionChannelContract.encodeBlockingRequest(
              enabled: enabled,
            ),
          )
          .timeout(_timeout);
    } on TimeoutException {
      return const CaptureProtectionActionResult.failure(
        warning: 'Capture protection call timed out.',
      );
    } on MissingPluginException catch (error) {
      return CaptureProtectionActionResult.failure(
        warning: _warning('Capture protection plugin is unavailable', error),
      );
    } on PlatformException catch (error) {
      return CaptureProtectionActionResult.failure(
        warning: _warning('Capture protection action failed', error),
      );
    } on Object catch (error) {
      return CaptureProtectionActionResult.failure(
        warning: _warning('Capture protection action decode failed', error),
      );
    }

    return CaptureProtectionChannelContract.decodeActionResult(result);
  }

  static Duration _validateTimeout(Duration timeout) {
    if (timeout.compareTo(Duration.zero) <= 0) {
      throw ArgumentError.value(timeout, 'timeout', 'must be positive');
    }
    return timeout;
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
