## Key Design Principles

1. **Always query locally** — never wait for the network. CBL live queries update the UI automatically.
2. **Replicator is background infrastructure** — start it once after login, it handles everything.
3. **The Access Control Function is the security boundary** — validate and enforce on the server side, not just client side.
4. **One collection per document type** — each collection has its own Access Control Function.
5. **Channel = access scope** — design channels before writing any code.
