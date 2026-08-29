import 'dart:convert';
import 'dart:io';

import 'package:peerdeal_privacy/peerdeal_privacy.dart';

Map<String, Object?> loadFixture(String name) {
  final packageLocal = File('test/fixtures/$name');
  final workspaceLocal = File('packages/peerdeal_privacy/test/fixtures/$name');
  final file = packageLocal.existsSync() ? packageLocal : workspaceLocal;
  return jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
}

RetentionPolicy loadRetentionPolicyFixture(String name) {
  final json = loadFixture(name);
  final mode = _retentionMode(_requiredString(json, 'mode'));
  final timedWipeSeconds = _requiredInt(json, 'timed_wipe_seconds');
  if (timedWipeSeconds < 0) {
    throw const FormatException('timed_wipe_seconds must be non-negative.');
  }

  return RetentionPolicy(
    mode: mode,
    wipeSchedule: WipeSchedule(
      mode: _scheduleMode(mode),
      timedWipeSeconds: timedWipeSeconds,
      durableExportAllowed: _requiredBool(json, 'durable_export_allowed'),
      ephemeralExportOnly: _requiredBool(json, 'ephemeral_export_only'),
    ),
    manualWipeConfirmation: const ManualWipeConfirmation(
      requiresSecondConfirmation: true,
      confirmationPhrase: 'WIPE RECEIPT',
    ),
    allowSessionRestore: _requiredBool(json, 'allow_session_restore'),
    allowUserRestore: _requiredBool(json, 'allow_user_restore'),
    disappearingPolicy: DisappearingPolicy(
      disappearingChatEnabled: mode == RetentionMode.strictEphemeral,
      disappearingSessionMode: mode == RetentionMode.strictEphemeral,
      messageRetentionPolicy: mode == RetentionMode.strictEphemeral
          ? MessageRetentionPolicy.strictEphemeral
          : MessageRetentionPolicy.standard,
    ),
    metadataProfile: const MetadataMinimizationProfile(
      minimizeMetadata: true,
      exportMinimalIdentity: true,
      allowPseudonymousAliases: true,
      allowDeviceIdentifiers: false,
      allowIpAddressCapture: false,
    ),
  );
}

RetentionMode _retentionMode(String value) {
  switch (value) {
    case 'standard':
      return RetentionMode.standard;
    case 'timedSandbox':
      return RetentionMode.timedSandbox;
    case 'manualWipeAllowed':
      return RetentionMode.manualWipeAllowed;
    case 'strictEphemeral':
      return RetentionMode.strictEphemeral;
    default:
      throw FormatException('Unsupported retention mode: $value.');
  }
}

String _scheduleMode(RetentionMode mode) {
  switch (mode) {
    case RetentionMode.standard:
      return 'standard';
    case RetentionMode.timedSandbox:
      return 'timed_sandbox';
    case RetentionMode.manualWipeAllowed:
      return 'manual_wipe_allowed';
    case RetentionMode.strictEphemeral:
      return 'strict_ephemeral';
  }
}

String _requiredString(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is String) return value;
  throw FormatException('$key must be a string.');
}

int _requiredInt(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is int) return value;
  throw FormatException('$key must be an integer.');
}

bool _requiredBool(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is bool) return value;
  throw FormatException('$key must be a boolean.');
}
