#!/bin/bash

echo "========================================"
echo "  STATE MIGRATION TEST"
echo "========================================"
echo ""

PASSED=0
FAILED=0

check() {
    if [ $1 -eq 0 ]; then
        echo "  PASS: $2"
        ((PASSED++))
    else
        echo "  FAIL: $2"
        ((FAILED++))
    fi
}

echo "--- Test 1: Same inputs produce same state hash ---"
cd ~/chameleon-zk/circuits/build/state_commitment

node state_commitment_js/generate_witness.js \
    state_commitment_js/state_commitment.wasm \
    input.json witness1.wtns 2>/dev/null
snarkjs groth16 prove \
    state_commitment_final.zkey witness1.wtns \
    proof1.json public1.json 2>/dev/null

node state_commitment_js/generate_witness.js \
    state_commitment_js/state_commitment.wasm \
    input.json witness2.wtns 2>/dev/null
snarkjs groth16 prove \
    state_commitment_final.zkey witness2.wtns \
    proof2.json public2.json 2>/dev/null

HASH1=$(cat public1.json)
HASH2=$(cat public2.json)

if [ "$HASH1" = "$HASH2" ]; then
    check 0 "Same inputs produce identical hash"
else
    check 1 "Hashes differ"
fi
rm -f witness1.wtns witness2.wtns proof1.json proof2.json public1.json public2.json

echo ""
echo "--- Test 2: State commitment proof verifies ---"
node state_commitment_js/generate_witness.js \
    state_commitment_js/state_commitment.wasm \
    input.json witness.wtns 2>/dev/null
snarkjs groth16 prove \
    state_commitment_final.zkey witness.wtns \
    proof.json public.json 2>/dev/null
snarkjs groth16 verify verification_key.json public.json proof.json 2>/dev/null
check $? "State commitment verifies"

echo ""
echo "--- Test 3: Morph validity proof verifies ---"
cd ~/chameleon-zk/circuits/build/morph_validator
node morph_validator_js/generate_witness.js \
    morph_validator_js/morph_validator.wasm \
    input.json witness.wtns 2>/dev/null
snarkjs groth16 prove \
    morph_validator_final.zkey witness.wtns \
    proof.json public.json 2>/dev/null
snarkjs groth16 verify verification_key.json public.json proof.json 2>/dev/null
check $? "Morph validator verifies"

echo ""
echo "--- Test 4: Rust BN254 proof ---"
cd ~/chameleon-zk/prover
cargo run --release -- prove --backend bn254 > /dev/null 2>&1
check $? "BN254 proof"

echo ""
echo "--- Test 5: Rust BLS12-381 proof ---"
cargo run --release -- prove --backend bls12-381 > /dev/null 2>&1
check $? "BLS12-381 proof"

echo ""
echo "--- Test 6: Rust morph commands ---"
cargo run --release -- morph --to bls12-381 > /dev/null 2>&1
check $? "Morph to BLS12-381"
cargo run --release -- morph --to bn254 > /dev/null 2>&1
check $? "Morph back to BN254"

echo ""
echo "--- Test 7: Rust benchmark ---"
cargo run --release -- benchmark > /dev/null 2>&1
check $? "Benchmark both backends"

echo ""
echo "========================================"
echo "  RESULT: $PASSED passed, $FAILED failed"
echo "========================================"
if [ $FAILED -eq 0 ]; then echo "  ALL PASSED"; fi
echo ""
