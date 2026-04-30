# AGENTS.md — join_flow overlay

Scope:
- App/service-layer orchestration for invite resolution, disclosure ACKs, role authorization,
  bootstrap planning, governance commit, and rejoin flows.

Do:
- keep adapter boundaries explicit
- preserve normalized states from the join-handshake spec
- fail safe when negotiation, required ACKs, role grant, or governance commit fails
- keep protocol/result-code mapping visible in one place

Do not:
- implement protocol schema ownership here
- move governance truth into the UI layer
- mutate table/session truth directly
- bypass required disclosure acknowledgements
