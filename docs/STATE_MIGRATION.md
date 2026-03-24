# Cross-Backend State Migration

## How Data Survives a Curve Switch

The state_commitment circuit hashes state values (balance, nonce,
secret) using Poseidon. This hash does NOT depend on which curve
is used. Same inputs always produce the same hash.

Before switching: generate state_commitment proof → record hash
After switching: generate state_commitment proof → compare hash
If hashes match: data was not modified during the switch.

## What Each Circuit Does During Migration

| Circuit | When Used | Purpose |
|---------|-----------|---------|
| state_commitment | Before morph | Prove current data is valid |
| morph_validator | During morph | Prove switch is authorized |
| state_commitment | After morph | Prove data survived switch |

## Morph Timing

| Step | Time |
|------|------|
| State commitment proof | ~800ms |
| Morph validity proof | ~900ms |
| Rust backend switch | ~50ms |
| Rust proof on new curve | ~50ms |
| On-chain transactions | ~12,000ms |
| Post-morph verification | ~800ms |
| **Total** | **~15 seconds** |