import 'package:peerdeal_privacy/peerdeal_privacy.dart';
import 'package:test/test.dart';

void main() {
  group('DefaultRetentionPolicyEngine', () {
    const engine = DefaultRetentionPolicyEngine();

    final policy = RetentionPolicy(
      mode: RetentionMode.timedSandbox,
      wipeSchedule: const WipeSchedule(
        mode: 'timed_sandbox',
        timedWipeSeconds: 3600,
        durableExportAllowed: true,
        ephemeralExportOnly: false,
      ),
      manualWipeConfirmation: const ManualWipeConfirmation(
        requiresSecondConfirmation: true,
        confirmationPhrase: 'WIPE RECEIPT',
      ),
      allowSessionRestore: true,
      allowUserRestore: false,
      disappearingPolicy: const DisappearingPolicy(
        disappearingChatEnabled: false,
        disappearingSessionMode: false,
        messageRetentionPolicy: MessageRetentionPolicy.standard,
      ),
      metadataProfile: const MetadataMinimizationProfile(
        minimizeMetadata: true,
        exportMinimalIdentity: true,
        allowPseudonymousAliases: true,
        allowDeviceIdentifiers: false,
        allowIpAddressCapture: false,
      ),
    );

    test('allows restore for timed sandbox when session restore enabled', () {
      expect(engine.canRestore(policy), isTrue);
    });

    test('marks wipe due after configured seconds', () {
      final closedAt = DateTime.utc(2026, 4, 25, 0, 0, 0);
      final now = closedAt.add(const Duration(seconds: 3600));
      expect(
        engine.isWipeDue(policy: policy, sessionClosedAt: closedAt, now: now),
        isTrue,
      );
    });

    test('strict ephemeral disables restore and durable export', () {
      final strictPolicy = RetentionPolicy(
        mode: RetentionMode.strictEphemeral,
        wipeSchedule: const WipeSchedule(
          mode: 'strict_ephemeral',
          timedWipeSeconds: null,
          durableExportAllowed: true,
          ephemeralExportOnly: false,
        ),
        manualWipeConfirmation: const ManualWipeConfirmation(
          requiresSecondConfirmation: true,
          confirmationPhrase: 'WIPE',
        ),
        allowSessionRestore: true,
        allowUserRestore: true,
        disappearingPolicy: const DisappearingPolicy(
          disappearingChatEnabled: true,
          disappearingSessionMode: true,
          messageRetentionPolicy: MessageRetentionPolicy.strictEphemeral,
        ),
        metadataProfile: const MetadataMinimizationProfile(
          minimizeMetadata: true,
          exportMinimalIdentity: true,
          allowPseudonymousAliases: true,
          allowDeviceIdentifiers: false,
          allowIpAddressCapture: false,
        ),
      );

      final schedule = engine.deriveWipeSchedule(strictPolicy);
      expect(engine.canRestore(strictPolicy), isFalse);
      expect(schedule.ephemeralExportOnly, isTrue);
      expect(schedule.durableExportAllowed, isFalse);
    });
  });
}
