# Starter fixture notes

These fixtures are intentionally small and deterministic.

They are decoded through the typed test-only fixture loader, and every setup
intent fixture is routed through resolver validation.

Use them to prove:
- simple / advanced / conversational paths converge on the same validated boundary
- preset layer priority is deterministic
- helper suggestions remain advisory and never bypass validation
- Game File compilation only happens from a build-ready validated plan

Current fixtures cover simple, advanced, and conversational setup intents plus
the deterministic preset stack. They are not a production-complete setup
corpus.
