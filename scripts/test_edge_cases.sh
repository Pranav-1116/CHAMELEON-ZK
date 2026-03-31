#!/bin/bash

echo ""
echo "========================================"
echo "  CHAMELEON-ZK EDGE CASE TESTS"
echo "========================================"
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

PASSED=0
FAILED=0

check() {
    if [ $1 -eq $2 ]; then
        echo -e "  ${GREEN}PASS${NC}: $3"
        ((PASSED++))
    else
        echo -e "  ${RED}FAIL${NC}: $3"
        ((FAILED++))
    fi
}

# ================================================================
# TEST GROUP 1: PROOF CONSISTENCY
# PURPOSE: Same inputs must always produce same public outputs.
# This is critical for state migration — if the hash changed
# randomly, we could not verify state integrity across morphs.
# ================================================================
echo -e "${CYAN}--- Test Group 1: Proof Consistency ---${NC}"
echo "  Same inputs must always produce same public outputs"
echo ""

cd ~/chameleon-zk/circuits/build/state_commitment

node state_commitment_js/generate_witness.js \
    state_commitment_js/state_commitment.wasm \
    input.json w1.wtns 2>/dev/null
snarkjs groth16 prove state_commitment_final.zkey w1.wtns p1.json pub1.json 2>/dev/null

node state_commitment_js/generate_witness.js \
    state_commitment_js/state_commitment.wasm \
    input.json w2.wtns 2>/dev/null
snarkjs groth16 prove state_commitment_final.zkey w2.wtns p2.json pub2.json 2>/dev/null

PUB1=$(cat pub1.json)
PUB2=$(cat pub2.json)

if [ "$PUB1" = "$PUB2" ]; then
    check 0 0 "Same inputs produce same state hash"
else
    check 0 1 "Same inputs produce same state hash"
fi

rm -f w1.wtns w2.wtns p1.json p2.json pub1.json pub2.json

echo ""

# ================================================================
# TEST GROUP 2: DIFFERENT INPUTS PRODUCE DIFFERENT HASHES
# PURPOSE: If someone changes the balance from 1000 to 999,
# the hash MUST change. Otherwise tampered data would not
# be detected during a morph.
# ================================================================
echo -e "${CYAN}--- Test Group 2: Different Inputs → Different Hashes ---${NC}"
echo "  Changed data must produce different commitment hash"
echo ""

cd ~/chameleon-zk/circuits/build/state_commitment

# Original input
node state_commitment_js/generate_witness.js \
    state_commitment_js/state_commitment.wasm \
    input.json witness.wtns 2>/dev/null
snarkjs groth16 prove \
    state_commitment_final.zkey witness.wtns \
    proof_orig.json public_orig.json 2>/dev/null

ORIG_HASH=$(cat public_orig.json)

# Modified input — different balance
echo '{"balance":"999","nonce":"5","account_id":"12345","backend_id":"0"}' > /tmp/modified_input.json

node state_commitment_js/generate_witness.js \
    state_commitment_js/state_commitment.wasm \
    /tmp/modified_input.json /tmp/mod_witness.wtns 2>/dev/null

snarkjs groth16 prove \
    state_commitment_final.zkey /tmp/mod_witness.wtns \
    /tmp/mod_proof.json /tmp/mod_public.json 2>/dev/null

# Verify modified proof is still valid (different inputs are valid, just different hash)
snarkjs groth16 verify verification_key.json /tmp/mod_public.json /tmp/mod_proof.json 2>/dev/null
check $? 0 "Modified input (balance=999) produces valid proof"

MOD_HASH=$(cat /tmp/mod_public.json)

if [ "$ORIG_HASH" != "$MOD_HASH" ]; then
    check 0 0 "Different balance produces different hash"
else
    check 0 1 "Different balance produces different hash"
fi

# Different nonce
echo '{"balance":"1000","nonce":"99","account_id":"12345","backend_id":"0"}' > /tmp/mod2_input.json

node state_commitment_js/generate_witness.js \
    state_commitment_js/state_commitment.wasm \
    /tmp/mod2_input.json /tmp/mod2_witness.wtns 2>/dev/null

snarkjs groth16 prove \
    state_commitment_final.zkey /tmp/mod2_witness.wtns \
    /tmp/mod2_proof.json /tmp/mod2_public.json 2>/dev/null

MOD2_HASH=$(cat /tmp/mod2_public.json)

if [ "$ORIG_HASH" != "$MOD2_HASH" ]; then
    check 0 0 "Different nonce produces different hash"
else
    check 0 1 "Different nonce produces different hash"
fi

rm -f proof_orig.json public_orig.json
rm -f /tmp/modified_input.json /tmp/mod_witness.wtns /tmp/mod_proof.json /tmp/mod_public.json
rm -f /tmp/mod2_input.json /tmp/mod2_witness.wtns /tmp/mod2_proof.json /tmp/mod2_public.json

echo ""

# ================================================================
# TEST GROUP 3: MORPH VALIDATOR WITH CORRECT INPUTS
# PURPOSE: The morph validator proof must verify when given
# correct authorization inputs.
# ================================================================
echo -e "${CYAN}--- Test Group 3: Morph Validator ---${NC}"
echo ""

cd ~/chameleon-zk/circuits/build/morph_validator

node morph_validator_js/generate_witness.js \
    morph_validator_js/morph_validator.wasm \
    input.json witness.wtns 2>/dev/null

snarkjs groth16 prove \
    morph_validator_final.zkey witness.wtns \
    proof.json public.json 2>/dev/null

snarkjs groth16 verify verification_key.json public.json proof.json 2>/dev/null
check $? 0 "Morph validator proof with correct inputs"

echo ""

# ================================================================
# TEST GROUP 4: RUST BACKEND SWITCHING (MULTIPLE TIMES)
# PURPOSE: Test that morph commands work in sequence.
# What if someone morphs 4 times rapidly? Must still work.
# ================================================================
echo -e "${CYAN}--- Test Group 4: Rapid Backend Switching ---${NC}"
echo "  Morph 4 times in sequence"
echo ""

cd ~/chameleon-zk/prover

cargo run --release -- morph --to bls12-381 > /dev/null 2>&1
check $? 0 "Morph #1: BN254 → BLS12-381"

cargo run --release -- morph --to bn254 > /dev/null 2>&1
check $? 0 "Morph #2: BLS12-381 → BN254"

cargo run --release -- morph --to bls12-381 > /dev/null 2>&1
check $? 0 "Morph #3: BN254 → BLS12-381"

cargo run --release -- morph --to bn254 > /dev/null 2>&1
check $? 0 "Morph #4: BLS12-381 → BN254"

echo ""

# ================================================================
# TEST GROUP 5: PROOF ON EACH BACKEND AFTER SWITCHING
# PURPOSE: After switching backends, the prover must still
# generate valid proofs on each curve.
# ================================================================
echo -e "${CYAN}--- Test Group 5: Proof After Each Switch ---${NC}"
echo ""

cargo run --release -- prove --backend bn254 > /dev/null 2>&1
check $? 0 "BN254 proof after switching"

cargo run --release -- prove --backend bls12-381 > /dev/null 2>&1
check $? 0 "BLS12-381 proof after switching"

echo ""

# ================================================================
# TEST GROUP 6: MULTIPLE STATE COMMITMENTS IN SEQUENCE
# PURPOSE: Generate 5 proofs rapidly. The circuit must work
# reliably every time, not just once.
# ================================================================
echo -e "${CYAN}--- Test Group 6: Rapid Sequential Proofs ---${NC}"
echo "  Generate 5 state commitment proofs rapidly"
echo ""

cd ~/chameleon-zk/circuits/build/state_commitment

ALL_SAME=true
FIRST_HASH=""

for i in 1 2 3 4 5; do
    node state_commitment_js/generate_witness.js \
        state_commitment_js/state_commitment.wasm \
        input.json witness.wtns 2>/dev/null

    snarkjs groth16 prove \
        state_commitment_final.zkey witness.wtns \
        proof.json public.json 2>/dev/null

    snarkjs groth16 verify \
        verification_key.json public.json proof.json 2>/dev/null
    check $? 0 "Sequential proof #$i"

    CURRENT_HASH=$(cat public.json)
    if [ -z "$FIRST_HASH" ]; then
        FIRST_HASH="$CURRENT_HASH"
    elif [ "$CURRENT_HASH" != "$FIRST_HASH" ]; then
        ALL_SAME=false
    fi
done

echo ""

if [ "$ALL_SAME" = true ]; then
    check 0 0 "All 5 sequential proofs produce same hash"
else
    check 0 1 "All 5 sequential proofs produce same hash"
fi

echo ""

# ================================================================
# TEST GROUP 7: BENCHMARK STILL WORKS
# PURPOSE: Both backends must pass the benchmark after all
# the switching and testing above.
# ================================================================
echo -e "${CYAN}--- Test Group 7: Final Benchmark Check ---${NC}"
echo ""

cd ~/chameleon-zk/prover
cargo run --release -- benchmark > /dev/null 2>&1
check $? 0 "Benchmark passes after all tests"

echo ""

# ================================================================
# SUMMARY
# ================================================================
echo "========================================"
echo "  EDGE CASE TEST RESULTS"
echo "========================================"
echo ""
echo -e "  Passed: ${GREEN}$PASSED${NC}"
echo -e "  Failed: ${RED}$FAILED${NC}"
echo ""
if [ $FAILED -eq 0 ]; then
    echo -e "  ${GREEN}ALL EDGE CASES PASSED${NC}"
else
    echo -e "  ${RED}$FAILED TESTS FAILED — review output above${NC}"
fi
echo ""
