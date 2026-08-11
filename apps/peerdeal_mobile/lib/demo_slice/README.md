# Mobile Demo Slice Overlay

Mount these placeholders behind a dev-only route.

Recommended order:
1. demo home
2. scenario picker
3. table screen
4. chat route
5. receipt route

## Safe-Surface Route Flow

Sensitive demo routes should follow the same app-layer path:

1. Parse the scenario fixture into a demo snapshot.
2. Convert the snapshot into package-level inputs such as receipt scan or
   recovery results.
3. Pass those inputs through the route presenter.
4. Render only the presenter view model in the screen.
5. Wrap sensitive content with `SafeSurface` using the presenter's
   `SafeSurfaceRenderModel`.

Do not let screens decide capture policy directly. Future private ledger,
receipt detail, verification drill-down, restore, or stats-history demo screens
should reuse this fixture -> presenter -> safe screen shape.

Sensitive receipt routes apply native blocking through the capture coordinator
and release it when the route is disposed. If native blocking fails, the
coordinator downgrades to visual obscuring and keeps the warning scrubbed.

## Receipt Verification Flow

Demo receipt artifact verification should use
`DemoReceiptArtifactVerifierFactory.methodChannel()` at the app boundary. The
call order is native secure-key bridge -> app key-ring loader -> artifact
verifier -> presenter -> safe surface.

Receipt key writes should use the app-owned `NativeReceiptKeyRingWriter`:
receipt signing/encryption key material -> generic native secure-key mutation
bridge. The native bridge stays generic and does not own receipt key purpose,
algorithm, rotation, or verification policy.

Receipt key provisioning should use `NativeReceiptKeyRingProvisioner`: native
secure-key bridge -> app key-ring loader -> missing active key generation ->
app key-ring writer. Provisioning must fail closed when native storage cannot
be loaded or a write is rejected.

Receipt export should use `NativeReceiptExportArtifactFactory`: key-ring
provisioner -> receipt signer/cipher adapters -> receipt service export. Do
not export signed/encrypted artifacts from app code that bypasses native-backed
key provisioning.

Mounted receipt routes may receive an app-owned export factory. The route must
turn the active snapshot into a deterministic receipt input, export through the
factory, then verify through `DemoReceiptArtifactVerifierFactory` before
projecting the safe surface.

## Local Bootstrap Flow

Demo bootstrap candidate loading should use
`NativeBootstrapCandidateLoader.methodChannel()` at the app boundary. The call
order is native local-network bridge -> normalized discovery snapshot ->
`peerdeal_network` bootstrap candidate provider -> mounted table route ->
render-only table screen. The native bridge stays generic and does not own
table, invite, or session policy.
The default loader carries an app-owned cancellation signal, and the table
route cancels it on bootstrap replacement or route disposal. Native capability
and discovery calls also fail closed after their bounded default deadline.

Join-flow bootstrap planning follows the same boundary rule through the
app-owned `NativeJoinBootstrapCoordinator`: native local-network bridge ->
normalized discovery -> `peerdeal_network` bootstrap candidates -> join
`BootstrapPlan`. An accepted first join may then carry a
`JoinFlowSessionContext` through the app shell: first-join selected peer or
governance-bound rejoin peer plus assigned seat -> context-aware production
source -> validated session route.
Invite-only callbacks remain supported for integrations that do not expose
the typed session source yet.

## Recovery Persistence Flow

Mounted table routes should receive recovery persistence through
`AppRecoveryPersistenceStoreFactory`. The app shell may inject the factory
directly or default it in this order: `PEERDEAL_RECOVERY_ROOT` -> generic native
app-support directory (`noBackupFilesDir` on Android) -> app-owned factory ->
`peerdeal_sync` JSON recovery store. The app-owned
`AppHoldemProductionSessionConfigurationFactory` composes that store with
native local identity, caller-owned route policy, and deterministic event
factories before the validated session route is mounted. Its result must be
checked before passing the configuration into the runtime;
`AppHoldemProductionSessionConfiguration.fromPersistedLocalIdentity(...)`
remains the lower-level composition entrypoint. Missing,
malformed, or throwing roots must fail closed before recovery windows are
loaded. The native bridge supplies only a directory fact; recovery and
retention policy remain app-owned. The factory result also includes a validated
`snapshotWriter` for product code that already owns canonical typed Hold'em
state and an event cursor; it persists only the supplied snapshot and does not
choose state, append the event log, own a database, or define route policy.
Route cancellation also propagates through
the app local-identity secure-key seam when the host exposes its additive
cancellation capability; an already-dispatched host mutation remains
host-owned and must be atomic/idempotent.

## Android Native Call Order

On Android, the app shell registers the generic secure-key method channel in
the host activity. Receipt flows still use the same app-owned order:
native bridge -> key-ring loader/provisioner -> receipt signer/cipher ->
artifact verifier -> presenter -> safe surface. Android encryption and
Keystore access are implementation details of the generic bridge; receipt
policy must not move into the host activity.
Receipt route replacement and disposal also cancel pending native-backed
verification through the app-owned loader/verifier seam; a host call already
dispatched remains host-owned.
