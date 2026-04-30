# PeerDeal Repo Operating Rules

## Scope

This file applies to the whole repository. Package-local `AGENTS.md` files add
more specific rules for their own package lanes.

## Purpose

This repository is optimized for agent-safe, package-local work.

## Default patch rules

- Prefer one package or one clearly bounded pair per patch.
- Always list touched invariants and touched public APIs.
- Add or update tests in the same patch.
- Do not import sibling package `src/` internals.
- Do not add hidden runtime behavior that bypasses Game File or protocol validation.

## Required patch output

Every serious patch should include:

- objective
- packages touched
- public API changes
- fixture/golden changes
- tests added or changed
- risks / follow-up

## When to stop and escalate

Stop and ask for architecture review if:

- a change regularly touches many unrelated packages
- a new feature cannot fit the existing adapter / package seams
- transport logic wants to mutate canonical truth
- wizard logic wants to become runtime truth
