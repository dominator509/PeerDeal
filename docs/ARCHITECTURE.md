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

## Forbidden patterns
- UI mutating core state directly
- wizard-only hidden runtime flags
- receipt or capture logic inside reducers
- transport-specific packet structures leaking into protocol contracts
- variant-specific rules hardcoded in universal core
