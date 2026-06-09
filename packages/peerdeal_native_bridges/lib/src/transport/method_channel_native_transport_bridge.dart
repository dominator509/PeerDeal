import 'package:flutter/services.dart';

import 'native_transport_bridge.dart';
import 'native_transport_bridge_models.dart';
import 'native_transport_channel_contract.dart';

class MethodChannelNativeTransportBridge implements NativeTransportBridge {
  MethodChannelNativeTransportBridge({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(_channelName);

  static const _channelName = NativeTransportChannelContract.channelName;

  final MethodChannel _channel;

  @override
  Future<NativeTransportCapability> getCapability() async {
    final Map<String, Object?>? result;
    try {
      result = await _channel.invokeMapMethod<String, Object?>(
        NativeTransportChannelContract.getCapabilityMethod,
      );
    } on MissingPluginException catch (error) {
      return NativeTransportCapability.unavailable(
        warning: _warning('Native transport plugin is unavailable', error),
      );
    } on PlatformException catch (error) {
      return NativeTransportCapability.unavailable(
        warning: _warning('Native transport capability lookup failed', error),
      );
    } on Object catch (error) {
      return NativeTransportCapability.unavailable(
        warning: _warning(
          'Native transport capability payload decode failed',
          error,
        ),
      );
    }

    return NativeTransportChannelContract.decodeCapability(result);
  }

  @override
  Future<NativeTransportSendResult> sendFrame(
    NativeTransportFrame frame,
  ) async {
    if (!frame.isUsable) {
      return const NativeTransportSendResult.failure(
        warning: 'Native transport send frame request is invalid.',
      );
    }

    final Map<String, Object?>? result;
    try {
      result = await _channel.invokeMapMethod<String, Object?>(
        NativeTransportChannelContract.sendFrameMethod,
        <String, Object?>{
          'frame': NativeTransportChannelContract.encodeFrame(frame),
        },
      );
    } on MissingPluginException catch (error) {
      return NativeTransportSendResult.failure(
        warning: _warning('Native transport plugin is unavailable', error),
      );
    } on PlatformException catch (error) {
      return NativeTransportSendResult.failure(
        warning: _warning('Native transport send failed', error),
      );
    } on Object catch (error) {
      return NativeTransportSendResult.failure(
        warning: _warning('Native transport send result decode failed', error),
      );
    }

    return NativeTransportChannelContract.decodeSendResult(result);
  }

  @override
  Future<NativeTransportReceiveSnapshot> receiveFrames({
    required String sessionId,
    required String peerId,
  }) async {
    if (!_isValidReceiveScope(sessionId) || !_isValidReceiveScope(peerId)) {
      return const NativeTransportReceiveSnapshot.unavailable(
        warning: 'Native transport receive request is invalid.',
      );
    }

    final Map<String, Object?>? result;
    try {
      result = await _channel.invokeMapMethod<String, Object?>(
        NativeTransportChannelContract.receiveFramesMethod,
        <String, Object?>{'sessionId': sessionId, 'peerId': peerId},
      );
    } on MissingPluginException catch (error) {
      return NativeTransportReceiveSnapshot.unavailable(
        warning: _warning('Native transport plugin is unavailable', error),
      );
    } on PlatformException catch (error) {
      return NativeTransportReceiveSnapshot.unavailable(
        warning: _warning('Native transport receive failed', error),
      );
    } on Object catch (error) {
      return NativeTransportReceiveSnapshot.unavailable(
        warning: _warning(
          'Native transport receive payload decode failed',
          error,
        ),
      );
    }

    return NativeTransportChannelContract.decodeReceiveSnapshot(result);
  }

  bool _isValidReceiveScope(String value) =>
      value.trim().isNotEmpty && value.trim() == value;

  String _warning(String prefix, Object error) {
    if (error is PlatformException) {
      return '$prefix: ${error.code} ${error.message ?? ''}'.trim();
    }
    return '$prefix: $error';
  }
}
