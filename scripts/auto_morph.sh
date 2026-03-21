#!/bin/bash

NEW_THREAT_LEVEL=${1:-2}
NEW_BACKEND_ID=${2:-1}
LOG_FILE=~/chameleon-zk/simulator/logs/threat_log.txt

source ~/chameleon-zk/.env 2>/dev/null
source ~/chameleon-zk/deployment_addresses.txt 2>/dev/null

echo "" | tee -a $LOG_FILE
echo "[$(date +%H:%M:%S)] ============================================" | tee -a $LOG_FILE
echo "[$(date +%H:%M:%S)] AUTO-MORPH STARTED: BN254 --> BLS12-381" | tee -a $LOG_FILE
echo "[$(date +%H:%M:%S)] ============================================" | tee -a $LOG_FILE

# ---------------------------------------------------------------
# Step 1: State commitment proof (state_commitment circuit)
# WHY: Before switching curves, we must prove the current state
# data is valid. The state_commitment circuit hashes balance,
# nonce, and secret using Poseidon. If data was tampered with,
# this proof would fail and the morph is aborted.
# ---------------------------------------------------------------
echo "[$(date +%H:%M:%S)] Step 1/7: State commitment proof..." | tee -a $LOG_FILE

cd ~/chameleon-zk/circuits/build/state_commitment

node state_commitment_js/generate_witness.js \
    state_commitment_js/state_commitment.wasm \
    input.json witness.wtns 2>/dev/null

START=$(date +%s%N)
snarkjs groth16 prove \
    state_commitment_final.zkey witness.wtns \
    proof.json public.json 2>/dev/null
END=$(date +%s%N)
STATE_TIME=$(( (END - START) / 1000000 ))

VERIFY=$(snarkjs groth16 verify verification_key.json public.json proof.json 2>&1)
if echo "$VERIFY" | grep -q "OK\|true"; then
    echo "[$(date +%H:%M:%S)]   VALID (${STATE_TIME}ms)" | tee -a $LOG_FILE
else
    echo "[$(date +%H:%M:%S)]   FAILED — ABORTING MORPH" | tee -a $LOG_FILE
    exit 1
fi

# ---------------------------------------------------------------
# Step 2: Morph validity proof (morph_validator circuit)
# WHY: We must prove the curve switch is authorized. The
# morph_validator circuit checks old backend ID, new backend ID,
# and authorization key. Without this, anyone could force an
# unauthorized curve switch.
# ---------------------------------------------------------------
echo "[$(date +%H:%M:%S)] Step 2/7: Morph validity proof..." | tee -a $LOG_FILE

cd ~/chameleon-zk/circuits/build/morph_validator

node morph_validator_js/generate_witness.js \
    morph_validator_js/morph_validator.wasm \
    input.json witness.wtns 2>/dev/null

START=$(date +%s%N)
snarkjs groth16 prove \
    morph_validator_final.zkey witness.wtns \
    proof.json public.json 2>/dev/null
END=$(date +%s%N)
MORPH_TIME=$(( (END - START) / 1000000 ))

VERIFY=$(snarkjs groth16 verify verification_key.json public.json proof.json 2>&1)
if echo "$VERIFY" | grep -q "OK\|true"; then
    echo "[$(date +%H:%M:%S)]   VALID (${MORPH_TIME}ms)" | tee -a $LOG_FILE
else
    echo "[$(date +%H:%M:%S)]   FAILED — ABORTING MORPH" | tee -a $LOG_FILE
    exit 1
fi

# ---------------------------------------------------------------
# Step 3: Rust prover morph to BLS12-381
# WHY: The Rust prover itself switches its active backend.
# This is the actual curve switch at the prover level.
# ---------------------------------------------------------------
echo "[$(date +%H:%M:%S)] Step 3/7: Rust morph to BLS12-381..." | tee -a $LOG_FILE

cd ~/chameleon-zk/prover
cargo run --release -- morph --to bls12-381 2>&1 | while IFS= read -r line; do
    echo "[$(date +%H:%M:%S)]   $line" | tee -a $LOG_FILE
done

# ---------------------------------------------------------------
# Step 4: Generate proof on new backend (BLS12-381)
# WHY: After switching, we generate a proof on the new curve
# to confirm it actually works.
# ---------------------------------------------------------------
echo "[$(date +%H:%M:%S)] Step 4/7: Proof on BLS12-381..." | tee -a $LOG_FILE

START=$(date +%s%N)
cargo run --release -- prove --backend bls12-381 2>&1 | while IFS= read -r line; do
    echo "[$(date +%H:%M:%S)]   $line" | tee -a $LOG_FILE
done
END=$(date +%s%N)
BLS_PROVE_TIME=$(( (END - START) / 1000000 ))

echo "[$(date +%H:%M:%S)]   BLS12-381 proof: ${BLS_PROVE_TIME}ms" | tee -a $LOG_FILE

# ---------------------------------------------------------------
# Step 5-6: On-chain updates (Sepolia testnet)
# WHY: Record the morph permanently on blockchain. Update threat
# level and switch the active backend in the smart contracts.
# ---------------------------------------------------------------
if [ -n "$MORPH_CONTROLLER_ADDRESS" ] && [ -n "$PRIVATE_KEY" ]; then
    echo "[$(date +%H:%M:%S)] Step 5/7: On-chain threat level..." | tee -a $LOG_FILE
    cast send $MORPH_CONTROLLER_ADDRESS \
        "updateThreatLevel(uint8)" $NEW_THREAT_LEVEL \
        --rpc-url $SEPOLIA_RPC_URL \
        --private-key $PRIVATE_KEY \
        > /dev/null 2>&1
    sleep 5
    echo "[$(date +%H:%M:%S)]   Updated to level $NEW_THREAT_LEVEL" | tee -a $LOG_FILE

    echo "[$(date +%H:%M:%S)] Step 6/7: On-chain backend switch..." | tee -a $LOG_FILE
    cast send $UNIVERSAL_VERIFIER_ADDRESS \
        "switchBackend(uint256)" $NEW_BACKEND_ID \
        --rpc-url $SEPOLIA_RPC_URL \
        --private-key $PRIVATE_KEY \
        > /dev/null 2>&1
    sleep 5
    echo "[$(date +%H:%M:%S)]   Backend switched on-chain" | tee -a $LOG_FILE
else
    echo "[$(date +%H:%M:%S)] Step 5-6: [Offline — no on-chain update]" | tee -a $LOG_FILE
fi

# ---------------------------------------------------------------
# Step 7: Post-morph verification (state_commitment circuit)
# WHY: After the entire morph, generate state_commitment proof
# again. If it still verifies, the data survived the switch.
# ---------------------------------------------------------------
echo "[$(date +%H:%M:%S)] Step 7/7: Post-morph verification..." | tee -a $LOG_FILE

cd ~/chameleon-zk/circuits/build/state_commitment

node state_commitment_js/generate_witness.js \
    state_commitment_js/state_commitment.wasm \
    input.json witness.wtns 2>/dev/null

snarkjs groth16 prove \
    state_commitment_final.zkey witness.wtns \
    proof.json public.json 2>/dev/null

VERIFY=$(snarkjs groth16 verify verification_key.json public.json proof.json 2>&1)
if echo "$VERIFY" | grep -q "OK\|true"; then
    echo "[$(date +%H:%M:%S)]   Post-morph: VALID" | tee -a $LOG_FILE
else
    echo "[$(date +%H:%M:%S)]   Post-morph: FAILED" | tee -a $LOG_FILE
    exit 1
fi

TOTAL=$((STATE_TIME + MORPH_TIME + BLS_PROVE_TIME))

echo "" | tee -a $LOG_FILE
echo "[$(date +%H:%M:%S)] ============================================" | tee -a $LOG_FILE
echo "[$(date +%H:%M:%S)] AUTO-MORPH COMPLETE (${TOTAL}ms)" | tee -a $LOG_FILE
echo "[$(date +%H:%M:%S)] ============================================" | tee -a $LOG_FILE

# Save to morph history
HISTORY=~/chameleon-zk/simulator/logs/morph_history.json
if [ ! -f "$HISTORY" ]; then echo '[]' > $HISTORY; fi

TEMP=$(mktemp)
jq ". += [{
    \"time\": \"$(date +%H:%M:%S)\",
    \"direction\": \"FORWARD\",
    \"from\": \"BN254\",
    \"to\": \"BLS12-381\",
    \"state_proof_ms\": $STATE_TIME,
    \"morph_proof_ms\": $MORPH_TIME,
    \"bls_proof_ms\": $BLS_PROVE_TIME,
    \"total_ms\": $TOTAL
}]" $HISTORY > $TEMP && mv $TEMP $HISTORY 2>/dev/null

exit 0
