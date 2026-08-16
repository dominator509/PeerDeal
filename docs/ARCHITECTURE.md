# PeerDeal Architecture

## North star
PeerDeal is a deterministic, event-sourced, privacy-first poker engine. The app shell is a client; the engine is the product.

## Core rules
- Dependencies point inward only.
- UI never owns game truth.
- Every hand must be reconstructable from ordered events.
- Networking must be replaceable without rewriting poker rules.
- Variant rules must remain isolated from the universal core.
- Privacy, receipt lifecycle, and capture policy must remain outside core hand logic.

## Layer map
1. Client App Layer
2. Session / Network Layer
3. Fair Deal / Crypto Layer
4. Universal Poker Core
5. Variant Modules
6. Privacy / Receipt / Capture Layer

## Required extension seams
- variant adapters
- mode adapters
- transport adapters
- receipt packaging / invalidation
- replay / snapshot recovery
- capture policy and native bridge hooks

## Settlement breadcrumb chain
The canonical Hold'em settlement breadcrumb path is covered across:
- `peerdeal_protocol`: owns the fixture event identities.
- `peerdeal_core`: projects settlement metadata from accepted events.
- `peerdeal_replay`: verifies core settlement metadata survives ordered replay.
- `peerdeal_sync`: verifies core settlement metadata survives snapshot + suffix
  recovery.

This chain is metadata-only. It does not move Hold'em ranking, settlement
projection, pot math, odd-chip handling, or ledger policy into replay or sync.
Next settlement hardening belongs in `peerdeal_variants` for Hold'em-specific
projection rules and in `peerdeal_core` for universal pot/ledger boundaries.
The variant-owned `HoldemCoreProjectionAdapter` now joins those boundaries by
emitting catalog-approved protocol events and applying them through the core
reducer transactionally; app/session code remains responsible for invoking it
from a live table flow. Mirrored app-owned `AppHoldemTableSessionRuntime`
owners now provide that invocation boundary and atomically commit the emitted
non-retention batches before advancing variant state. Its inbound path accepts
only contiguous, hash-valid envelopes, reduces Hold'em state in
`peerdeal_variants`, and commits the same envelope through the app-owned core
runtime before advancing the variant cursor. Generic core-only transport
remains available for non-variant sessions.
The mirrored app-owned `AppHoldemTableSessionRoute` now composes this validated
runtime with transport/source lifecycle and accepted-event surface refresh;
its route context can publish canonical projection frames and report partial
sends without rerunning variant rules. Android and Windows hosts now provide
the generic native byte transport through a host-private bounded multicast
envelope; device/network reachability and product route integration remain
outside this seam.
The app-owned transport source stops its polling timer and rejects future
drains when route cancellation wins; an already-started native drain remains
host-owned until it settles. This keeps transport lifecycle policy at the app
boundary without changing the generic bridge contract.
The app-owned production route keeps remote-peer identity separate from the
local recipient identity: native receive scope is filtered to the local peer,
and the app handler rejects configured sender/recipient mismatches before
event decode or state mutation. This is an existing-frame routing and
authorization binding, not a cryptographic authentication protocol; session
authentication remains an explicit product/protocol contract.
The app-owned production table surface also binds pending projection work to
the current transport session/source; replacement invalidates stale operation
completion before it can publish through a new session. This remains app
lifecycle ownership and does not alter protocol or native bridge contracts.
Pending projection or persistence work also blocks new local action submission
until the existing retry path clears it, preserving event order at the app
surface without creating a second state store.
Typed `AppHoldemProductionRouteRegistration` owners now merge that seam into
the mobile and desktop production route maps, auto-register navigation, and
require native readiness before mounting; product callers still own session
state construction and local identity. The app-owned
`AppHoldemProductionTableSurface` renders bounded projection state and routes
local actions through the runtime and canonical publisher; it never evaluates
variant rules or becomes a second state store. Partial publication resumes from
the publisher's reported event offset. The mirrored
`AppHoldemProductionSessionFactory` composes that existing route boundary from
injected canonical table/hand state, event cursor, close-retention adapter, and
peer identity. It validates app-owned route metadata and transport
configuration without deriving product session truth.
Bootstrap source loads also receive an app-owned cancellation signal that is
completed on route cancellation or timeout, so source-owned persistence or
native work can stop without moving lifecycle policy into shared packages.
The persisted source checks that signal immediately before initial typed
snapshot checkpointing and again after the checkpoint settles; a cancelled
load never returns a production input, even if an already-started checkpoint
has completed.

## Forbidden patterns
- UI mutating core state directly
- wizard-only hidden runtime flags
- receipt or capture logic inside reducers
- transport-specific packet structures leaking into protocol contracts
- variant-specific rules hardcoded in universal core
