import 'app_storage_directory_bridge_models.dart';
import '../native_bridge_payload_limits.dart';

class AppStorageDirectoryChannelContract {
  const AppStorageDirectoryChannelContract._();

  static const channelName = 'peerdeal/native_bridges/app_storage';
  static const getAppSupportDirectoryMethod = 'getAppSupportDirectory';

  static AppStorageDirectorySnapshot decodeAppSupportDirectory(
    Map<String, Object?>? payload,
  ) {
    if (payload == null) {
      return const AppStorageDirectorySnapshot.unavailable(
        warning: 'Native app storage directory is unavailable.',
      );
    }

    final available = payload['available'];
    final directoryPath = payload['directoryPath'];
    if (available is! bool ||
        !available ||
        directoryPath is! String ||
        !_isValidPath(directoryPath)) {
      return AppStorageDirectorySnapshot.unavailable(
        warning:
            _stringValue(payload['warning']) ??
            'Native app storage directory is unavailable.',
      );
    }

    return AppStorageDirectorySnapshot(
      available: true,
      directoryPath: directoryPath,
      warning: _stringValue(payload['warning']),
    );
  }

  static bool _isValidPath(String value) {
    return NativeBridgePayloadLimits.isSafeUtf8Text(
      value,
      NativeBridgePayloadLimits.maxAppStoragePathBytes,
    );
  }

  static String? _stringValue(Object? value) {
    if (value is! String ||
        !NativeBridgePayloadLimits.isSafeUtf8Text(
          value,
          NativeBridgePayloadLimits.maxDiagnosticBytes,
        )) {
      return null;
    }
    return value;
  }
}
