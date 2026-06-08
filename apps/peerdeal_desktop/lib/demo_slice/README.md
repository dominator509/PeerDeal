# Desktop Demo Slice Overlay

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

## Receipt Verification Flow

Demo receipt artifact verification should use
`DemoReceiptArtifactVerifierFactory.methodChannel()` at the app boundary. The
call order is native secure-key bridge -> app key-ring loader -> artifact
verifier -> presenter -> safe surface.

Receipt key writes should use the app-owned `NativeReceiptKeyRingWriter`:
receipt signing/encryption key material -> generic native secure-key mutation
bridge. The native bridge stays generic and does not own receipt key purpose,
algorithm, rotation, or verification policy.

## Local Bootstrap Flow

Demo bootstrap candidate loading should use
`NativeBootstrapCandidateLoader.methodChannel()` at the app boundary. The call
order is native local-network bridge -> normalized discovery snapshot ->
`peerdeal_network` bootstrap candidate provider -> mounted table route ->
render-only table screen. The native bridge stays generic and does not own
table, invite, or session policy.

Join-flow bootstrap planning follows the same boundary rule through the
app-owned `NativeJoinBootstrapCoordinator`: native local-network bridge ->
normalized discovery -> `peerdeal_network` bootstrap candidates -> join
`BootstrapPlan`.
