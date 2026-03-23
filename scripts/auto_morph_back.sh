#!/bin/bash

LOG_FILE=~/chameleon-zk/simulator/logs/threat_log.txt

source ~/chameleon-zk/.env 2>/dev/null
source ~/chameleon-zk/deployment_addresses.txt 2>/dev/null

echo "" | tee -a $LOG_FILE
echo "[$(date +%H:%M:%S)] ============================================" | tee -a $LOG_FILE
echo "[$(date +%H:%M:%S)] MORPH-BACK: BLS12-381 --> BN254" | tee -a $LOG_FILE
echo "[$(date +%H:%M:%S)] ============================================" | tee -a $LOG_FILE

# Step 1: State commitment proof (state_commitment circuit)
# WHY: Prove data is valid before switching back.
echo "[$(date +%H:%M:%S)] Step 1/5: State commitment proof..." | tee -a $LOG_FILE

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
    echo "[$(date +%H:%M:%S)]   FAILED — ABORTING" | tee -a $LOG_FILE
    exit 1
fi

# Step 2: Rust prover morph back to BN254
echo "[$(date +%H:%M:%S)] Step 2/5: Rust morph to BN254..." | tee -a $LOG_FILE

cd ~/chameleon-zk/prover
cargo run --release -- morph --to bn254 2>&1 | while IFS= read -r line; do
    echo "[$(date +%H:%M:%S)]   $line" | tee -a $LOG_FILE
done

# Step 3: Proof on restored backend (BN254)
echo "[$(date +%H:%M:%S)] Step 3/5: Proof on BN254..." | tee -a $LOG_FILE

START=$(date +%s%N)
cargo run --release -- prove --backend bn254 2>&1 | while IFS= read -r line; do
    echo "[$(date +%H:%M:%S)]   $line" | tee -a $LOG_FILE
done
END=$(date +%s%N)
BN_TIME=$(( (END - START) / 1000000 ))

# Step 4: On-chain reset
if [ -n "$MORPH_CONTROLLER_ADDRESS" ] && [ -n "$PRIVATE_KEY" ]; then
    echo "[$(date +%H:%M:%S)] Step 4/5: On-chain reset..." | tee -a $LOG_FILE
    cast send $MORPH_CONTROLLER_ADDRESS \
        "updateThreatLevel(uint8)" 0 \
        --rpc-url $SEPOLIA_RPC_URL \
        --private-key $PRIVATE_KEY > /dev/null 2>&1
    sleep 5
    cast send $UNIVERSAL_VERIFIER_ADDRESS \
        "switchBackend(uint256)" 0 \
        --rpc-url $SEPOLIA_RPC_URL \
        --private-key $PRIVATE_KEY > /dev/null 2>&1
    sleep 5
    echo "[$(date +%H:%M:%S)]   On-chain reset done" | tee -a $LOG_FILE
else
    echo "[$(date +%H:%M:%S)] Step 4/5: [Offline — skipped]" | tee -a $LOG_FILE
fi

# Step 5: Post-recovery verification (state_commitment circuit)
# WHY: Prove data survived the switch back.
echo "[$(date +%H:%M:%S)] Step 5/5: Post-recovery verification..." | tee -a $LOG_FILE

cd ~/chameleon-zk/circuits/build/state_commitment

node state_commitment_js/generate_witness.js \
    state_commitment_js/state_commitment.wasm \
    input.json witness.wtns 2>/dev/null

snarkjs groth16 prove \
    state_commitment_final.zkey witness.wtns \
    proof.json public.json 2>/dev/null

VERIFY=$(snarkjs groth16 verify verification_key.json public.json proof.json 2>&1)
if echo "$VERIFY" | grep -q "OK\|true"; then
    echo "[$(date +%H:%M:%S)]   Post-recovery: VALID" | tee -a $LOG_FILE
else
    echo "[$(date +%H:%M:%S)]   Post-recovery: FAILED" | tee -a $LOG_FILE
fi

echo "" | tee -a $LOG_FILE
echo "[$(date +%H:%M:%S)] MORPH-BACK COMPLETE — BN254 restored" | tee -a $LOG_FILE

HISTORY=~/chameleon-zk/simulator/logs/morph_history.json
TEMP=$(mktemp)
jq ". += [{
    \"time\": \"$(date +%H:%M:%S)\",
    \"direction\": \"BACK\",
    \"from\": \"BLS12-381\",
    \"to\": \"BN254\",
    \"state_proof_ms\": $STATE_TIME,
    \"bn254_proof_ms\": $BN_TIME
}]" $HISTORY > $TEMP && mv $TEMP $HISTORY 2>/dev/null

exit 0
