# AGENTS.md — peerdeal_variants

## Package role
Own the variant adapter boundary for PeerDeal.

## You may change here
- variant identity/capability models
- Hold'em adapter
- Hold'em hand-plan and street model
- showdown/evaluation contracts
- variant fixtures and tests

## You must not do here
- do not move mode/session policy into this package
- do not add transport or UI logic
- do not put receipt/capture/privacy rules here
- do not hardwire app-layer assumptions into adapter contracts

## Patch discipline
- keep public exports intentional
- add or update fixtures for behavior changes
- update tests when changing legal-action or phase semantics
- preserve Hold'em-first launch boundary while keeping Omaha/PLO expansion seams clean
