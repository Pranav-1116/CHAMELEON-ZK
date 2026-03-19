#!/bin/bash

echo "========================================"
echo "  CHAMELEON-ZK PERFORMANCE BENCHMARKS"
echo "========================================"
echo ""

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULTS_FILE=~/chameleon-zk/benchmarks/results/benchmark_${TIMESTAMP}.txt

echo "Benchmark started at $(date)" > $RESULTS_FILE
echo "" >> $RESULTS_FILE

# ----- STATE COMMITMENT CIRCUIT -----
echo "--- State Commitment Circuit ---"
echo "    This is the primary circuit. It hashes state values"
echo "    to create a commitment that survives curve switches."
echo ""

cd ~/chameleon-zk/circuits/build/state_commitment

node state_commitment_js/generate_witness.js \
    state_commitment_js/state_commitment.wasm \
    input.json witness.wtns 2>/dev/null

START=$(date +%s%N)
snarkjs groth16 prove \
    state_commitment_final.zkey witness.wtns \
    proof.json public.json 2>/dev/null
END=$(date +%s%N)
STATE_PROVE=$(( (END - START) / 1000000 ))

START=$(date +%s%N)
snarkjs groth16 verify \
    verification_key.json public.json proof.json 2>/dev/null
END=$(date +%s%N)
STATE_VERIFY=$(( (END - START) / 1000000 ))

STATE_SIZE=$(wc -c < proof.json)

echo "  Prove:  ${STATE_PROVE}ms"
echo "  Verify: ${STATE_VERIFY}ms"
echo "  Size:   ${STATE_SIZE} bytes"

# ----- MORPH VALIDATOR CIRCUIT -----
echo ""
echo "--- Morph Validator Circuit ---"
echo "    This circuit proves a curve switch is authorized."
echo ""

cd ~/chameleon-zk/circuits/build/morph_validator

node morph_validator_js/generate_witness.js \
    morph_validator_js/morph_validator.wasm \
    input.json witness.wtns 2>/dev/null

START=$(date +%s%N)
snarkjs groth16 prove \
    morph_validator_final.zkey witness.wtns \
    proof.json public.json 2>/dev/null
END=$(date +%s%N)
MORPH_PROVE=$(( (END - START) / 1000000 ))

START=$(date +%s%N)
snarkjs groth16 verify \
    verification_key.json public.json proof.json 2>/dev/null
END=$(date +%s%N)
MORPH_VERIFY=$(( (END - START) / 1000000 ))

MORPH_SIZE=$(wc -c < proof.json)

echo "  Prove:  ${MORPH_PROVE}ms"
echo "  Verify: ${MORPH_VERIFY}ms"
echo "  Size:   ${MORPH_SIZE} bytes"

# ----- RUST DUAL-BACKEND -----
echo ""
echo "--- Rust Dual-Backend Prover ---"
echo "    Generates proofs on both BN254 and BLS12-381."
echo ""

cd ~/chameleon-zk/prover

START=$(date +%s%N)
cargo run --release -- benchmark 2>&1
END=$(date +%s%N)
RUST_TIME=$(( (END - START) / 1000000 ))

echo ""
echo "  Total benchmark time: ${RUST_TIME}ms"

# ----- MORPHING OVERHEAD CALCULATION -----
TOTAL_MORPH_OVERHEAD=$((STATE_PROVE + MORPH_PROVE))

# ----- SUMMARY -----
echo ""
echo "========================================"
echo "  SUMMARY"
echo "========================================"
echo ""
echo "  Circuit            | Prove(ms) | Verify(ms) | Size(bytes)"
echo "  -------------------|-----------|------------|------------"
echo "  State Commitment   | $STATE_PROVE       | $STATE_VERIFY        | $STATE_SIZE"
echo "  Morph Validator    | $MORPH_PROVE       | $MORPH_VERIFY        | $MORPH_SIZE"
echo "  Rust (both curves) | $RUST_TIME       |            |"
echo ""
echo "  Morphing overhead (state + morph proofs): ${TOTAL_MORPH_OVERHEAD}ms"
echo ""

# Save to file
cat >> $RESULTS_FILE << EOF
RESULTS
-------
State Commitment:   Prove=${STATE_PROVE}ms  Verify=${STATE_VERIFY}ms  Size=${STATE_SIZE}bytes
Morph Validator:    Prove=${MORPH_PROVE}ms  Verify=${MORPH_VERIFY}ms  Size=${MORPH_SIZE}bytes
Rust Dual-Backend:  Total=${RUST_TIME}ms
Morph Overhead:     ${TOTAL_MORPH_OVERHEAD}ms
EOF

echo "Results saved to: $RESULTS_FILE"