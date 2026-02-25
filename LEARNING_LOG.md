# Learning Log

## Week 1

###  Environment Setup
- Installed Rust via rustup
- Installed Node.js via nvm  
- Learned: ZK proofs allow proving knowledge without revealing it
- Analogy: Proving you know a cave path without showing the path

###  Circom and First Circuit
- Built Circom from source
- Compiled first circuit (simple multiplier)
- Completed trusted setup
- Generated first proof!
- Learned: R1CS = system of equations representing the computation

###  Foundry and On-Chain
- Installed Foundry toolkit
- Exported Solidity verifier
- Deployed to local Anvil
- Verified proof on-chain
- Learned: Pairing operations make verification efficient


### WEEK 2

##  Arkworks Deep Dive


1. **Arkworks is a collection of crates:**
   - ark-ff: Field arithmetic
   - ark-ec: Elliptic curve operations
   - ark-bn254, ark-bls12-381: Specific curves
   - ark-groth16: Proof system

2. **Finite fields:**
   - Numbers wrap around at a prime
   - All ZK math happens in finite fields
   - Field size determines security level

3. **Elliptic curves in crypto:**
   - Points on a curve with special properties
   - Hard to reverse scalar multiplication (discrete log)
   - This hardness = security

4. **Why Rust/Arkworks over Circom:**
   - Programmatic curve switching
   - Better performance
   - More control for Chameleon-ZK

### Files Created
- prover/Cargo.toml
- prover/src/main.rs
- prover/src/lib.rs
- prover/src/bn254_backend.rs (placeholder)
- prover/src/bls12_381_backend.rs (placeholder)
- prover/src/circuit.rs (placeholder)
- prover/src/morph.rs (placeholder)

### Concepts to Review
- Finite field arithmetic
- Elliptic curve discrete log problem
- Rust trait system


##  BN254 Backend Implementation



1. **BN254 curve specifics:**
   - 254-bit field size
   - ~100-bit security (reduced from ~128 due to 2016 attack)
   - Has Ethereum precompiles (cheap verification)
   - Also called BN128, alt_bn128

2. **Arkworks circuit definition:**
   - Implement `ConstraintSynthesizer` trait
   - `new_witness_variable` for private inputs
   - `new_input_variable` for public inputs/outputs
   - `enforce_constraint` creates R1CS constraint

3. **Groth16 API in arkworks:**
   - `circuit_specific_setup` generates keys
   - `prove` creates proof from witness
   - `verify` checks proof against public inputs

4. **Key insight for Chameleon-ZK:**
   - Different curves have same API structure
   - Can create unified interface
   - Backend switching is possible!

### Code Written
- bn254_backend.rs: Full BN254 implementation
- main.rs: Test harness

### Tests Passing
- test_bn254_proof_cycle: ✓

### Performance Notes
- Setup: ~500ms
- Prove: ~50ms
- Verify: ~5ms



## BLS12-381 Backend Implementation



1. **BLS12-381 specifics:**
   - 381-bit field (larger than BN254)
   - ~128-bit security (stronger than BN254)
   - Named after creators: Barreto-Lynn-Scott
   - Used by Zcash and Ethereum 2.0

2. **Backend implementation pattern:**
   - Same structure as BN254
   - Different types: `Bls12_381`, `BLS381Fr`
   - Can use same API design

3. **Performance tradeoffs:**
   - BLS12-381 is ~40-50% slower
   - But provides ~28% more security
   - Chameleon-ZK can choose based on needs

4. **Unified architecture realized:**
   - Both backends have identical interfaces
   - Makes switching straightforward
   - Foundation for morphing protocol

### Code Written
- bls12_381_backend.rs: Full implementation
- main.rs: Both backends with benchmarking

### Tests Passing
- test_bn254_proof_cycle: ✓
- test_bls12_381_proof_cycle: ✓

### Key Insight
The same circuit logic works on different curves!
Only the field type changes, everything else is identical.



##  State Commitment Circuit



1. **State in ZK systems:**
   - State = all data the system tracks
   - Must be preserved across backend switches
   - Commitment = hash of state (curve-agnostic)

2. **Poseidon hash:**
   - Designed specifically for ZK circuits
   - ~250 constraints (vs ~25,000 for SHA-256)
   - Standard in ZK projects

3. **State commitment pattern:**
   - Hash state into single value
   - Commitment survives backend morphs
   - Verify same commitment before/after

4. **Morph validation requirements:**
   - Pre-state commitment valid
   - Post-state commitment valid
   - States identical
   - Backend IDs different

### Files Created
- circuits/state_commitment.circom
- circuits/morph_validator.circom
- prover/src/circuit.rs

### Circuits Compiled
- state_commitment: ~250 constraints
- morph_validator: ~500 constraints

### Tests Passing
- test_state_creation: ✓
- test_morph_record_validity: ✓
- test_invalid_morph_same_backend: ✓

### Key Insight
The commitment is just bytes - it doesn't care what curve
created it. This is how Chameleon-ZK maintains consistency!

