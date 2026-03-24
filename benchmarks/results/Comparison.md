# Chameleon-ZK Performance Comparison

## Circuit Proof Sizes (Circom, Groth16 on BN254)

| Circuit | Proof Size | Public Inputs | Verification Key | Proving Key |
|---------|-----------|---------------|------------------|-------------|
| State Commitment | 806 bytes | 89 bytes | 3,113 bytes | 330 KB |
| Morph Validator | 806 bytes | 176 bytes | 3,469 bytes | 659 KB |

## Rust Prover Proof Sizes (Arkworks)

| Backend | Raw Proof | Saved File | Ratio |
|---------|-----------|-----------|-------|
| BN254 | 128 bytes | 435 bytes | 1x |
| BLS12-381 | 192 bytes | 567 bytes | 1.5x |

## Why BLS12-381 Proofs Are Larger

BLS12-381 has a 381-bit field vs BN254's 254-bit field.
Each curve point takes more bytes to represent:
- BN254 point: ~32 bytes compressed
- BLS12-381 point: ~48 bytes compressed
- A Groth16 proof has 2-3 points = 50% more data

## Total Data Per Morph Cycle

| Step | Proof Size | Purpose |
|------|-----------|---------|
| State commitment | 806 bytes | Prove data integrity |
| Morph validator | 806 bytes | Prove switch authorized |
| BN254 proof | 435 bytes | Prove old curve works |
| BLS12-381 proof | 567 bytes | Prove new curve works |
| **Total** | **2,614 bytes** | **One complete morph** |

## Scaling

| Morphs | Total Proofs | Total Size |
|--------|-------------|-----------|
| 1 | 4 | 2.6 KB |
| 10 | 40 | 26 KB |
| 100 | 400 | 261 KB |
| 1,000 | 4,000 | 2.6 MB |

## Circuit Benchmarks

| Circuit | Prove Time | Verify Time |
|---------|-----------|-------------|
| State Commitment | ~800ms | ~550ms |
| Morph Validator | ~900ms | ~570ms |

## Rust Prover Benchmarks

| Metric | BN254 | BLS12-381 |
|--------|-------|-----------|
| Setup | 51ms | 50ms |
| Prove | 14ms | 8ms |
| Verify | 3ms | 8ms |

## Total Morph Time

| Component | Time |
|-----------|------|
| State commitment proof | ~800ms |
| Morph validity proof | ~900ms |
| Rust backend switch | ~50ms |
| Rust proof generation | ~70ms |
| On-chain transactions | ~12,000ms |
| Post-morph verification | ~800ms |
| **Total** | **~14,620ms (~15 seconds)** |

## Key Finding

Proof size is CONSTANT per circuit regardless of which
backend is active. The state_commitment proof is always
806 bytes whether generated before or after a morph.

What changes: Rust proof size (435 vs 567 bytes) because
BLS12-381 curve points are physically larger.