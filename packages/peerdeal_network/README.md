# peerdeal_network LAN + Relay Overlay

This overlay extends the earlier network-confidence starter with Sprint 10 seams:
- LAN discovery
- relay fallback
- bootstrap candidate resolution
- session path selection
- direct-to-relay transition planning

The package continues to own transport routing concerns only.
It must not own poker truth, reducers, receipts, or settlement semantics.
