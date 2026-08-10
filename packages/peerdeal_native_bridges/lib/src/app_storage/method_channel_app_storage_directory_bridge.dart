import 'package:flutter/services.dart';

import 'app_storage_directory_bridge.dart';
import 'app_storage_directory_bridge_models.dart';
import 'app_storage_directory_channel_contract.dart';

class MethodChannelAppStorageDirectoryBridge
    implements AppStorageDirectoryBridge {
  MethodChannelAppStorageDirectoryBridge({MethodChannel? channel})
    : _channel =
          channel ??
          const MethodChannel(AppStorageDirectoryChannelContract.channelName);

  final MethodChannel _channel;

  @override
  Future<AppStorageDirectorySnapshot> getAppSupportDirectory() async {
    final Map<String, Object?>? result;
    try {
      result = await _channel.invokeMapMethod<String, Object?>(
        AppStorageDirectoryChannelContract.getAppSupportDirectoryMethod,
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
}
