#!/bin/bash

echo ""
echo "========================================"
echo "  CHAMELEON-ZK DASHBOARD"
echo "========================================"
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

HISTORY=~/chameleon-zk/simulator/logs/morph_history.json
LOG=~/chameleon-zk/simulator/logs/threat_log.txt

source ~/chameleon-zk/.env 2>/dev/null
source ~/chameleon-zk/deployment_addresses.txt 2>/dev/null

# ================================================================
# SECTION 1: ON-CHAIN STATUS
# PURPOSE: Query Sepolia contracts to show current state.
# This proves the contracts are live and responding.
# ================================================================
echo -e "${CYAN}--- ON-CHAIN STATUS ---${NC}"
echo ""

if [ -n "$SEPOLIA_RPC_URL" ] && [ -n "$MORPH_CONTROLLER_ADDRESS" ]; then
    THREAT_LEVEL=$(cast call $MORPH_CONTROLLER_ADDRESS "currentThreatLevel()" --rpc-url $SEPOLIA_RPC_URL 2>/dev/null)
    THREAT_NAME_HEX=$(cast call $MORPH_CONTROLLER_ADDRESS "getThreatLevelName()" --rpc-url $SEPOLIA_RPC_URL 2>/dev/null)
    THREAT_NAME=$(echo $THREAT_NAME_HEX | sed 's/0x//' | xxd -r -p 2>/dev/null | tr -d '\0')

    BACKEND_HEX=$(cast call $UNIVERSAL_VERIFIER_ADDRESS "getActiveBackendName()" --rpc-url $SEPOLIA_RPC_URL 2>/dev/null)
    BACKEND_NAME=$(echo $BACKEND_HEX | sed 's/0x//' | xxd -r -p 2>/dev/null | tr -d '\0')

    echo "  Threat Level:   $THREAT_NAME"
    echo "  Active Backend: $BACKEND_NAME"
    echo "  Network:        Sepolia Testnet"
else
    echo "  [Offline — .env or deployment_addresses.txt not configured]"
fi

echo ""

# ================================================================
# SECTION 2: MORPH HISTORY
# PURPOSE: Read morph_history.json and display every morph that
# happened during the last simulation run. Shows timing data.
# ================================================================
echo -e "${CYAN}--- MORPH HISTORY ---${NC}"
echo ""

if [ ! -f "$HISTORY" ]; then
    echo "  No morph history found."
    echo "  Run ./threat_simulator.sh first to generate history."
else
    COUNT=$(jq length $HISTORY 2>/dev/null)

    if [ "$COUNT" = "0" ] || [ -z "$COUNT" ]; then
        echo "  No morphs recorded yet."
        echo "  Run ./threat_simulator.sh first."
    else
        echo "  Total morphs recorded: $COUNT"
        echo ""
        echo "  │    │ Time     │ Dir      │ Curve Change          │ Time(ms) │"

        INDEX=0
        jq -r '.[] | "\(.time)|\(.direction)|\(.from)|\(.to)|\(.total_ms // "N/A")"' $HISTORY 2>/dev/null | while IFS='|' read -r TIME DIR FROM TO TOTAL; do
            ((INDEX++))
            printf "  │ %3d │ %-8s │ %-8s │ %-7s → %-7s     │ %8s │\n" "$INDEX" "$TIME" "$DIR" "$FROM" "$TO" "$TOTAL"
        done


        # Statistics
        FORWARD=$(jq '[.[] | select(.direction == "FORWARD")] | length' $HISTORY 2>/dev/null)
        BACK=$(jq '[.[] | select(.direction == "BACK")] | length' $HISTORY 2>/dev/null)
        AVG=$(jq '[.[] | select(.total_ms != null) | .total_ms] | if length > 0 then (add / length | floor) else 0 end' $HISTORY 2>/dev/null)

        echo ""
        echo "  Forward morphs:  $FORWARD"
        echo "  Back morphs:     $BACK"
        echo "  Avg morph time:  ${AVG}ms"

        # Check if proof sizes are recorded
        HAS_SIZES=$(jq '.[0] | has("state_proof_bytes")' $HISTORY 2>/dev/null)
        if [ "$HAS_SIZES" = "true" ]; then
            echo ""
            echo "  Proof sizes per morph:"
            jq -r '.[] | select(.state_proof_bytes != null) | "    \(.direction): state=\(.state_proof_bytes)B morph=\(.morph_proof_bytes // "N/A")B"' $HISTORY 2>/dev/null
        fi
    fi
fi

echo ""

# ================================================================
# SECTION 3: PROOF SIZES
# PURPOSE: Show current proof file sizes. This data is useful
# for understanding the cost of on-chain verification.
# ================================================================
echo -e "${CYAN}--- PROOF SIZES ---${NC}"
echo ""

SC_PROOF=$(wc -c < ~/chameleon-zk/circuits/build/state_commitment/proof.json 2>/dev/null || echo "N/A")
SC_PUBLIC=$(wc -c < ~/chameleon-zk/circuits/build/state_commitment/public.json 2>/dev/null || echo "N/A")
MV_PROOF=$(wc -c < ~/chameleon-zk/circuits/build/morph_validator/proof.json 2>/dev/null || echo "N/A")
MV_PUBLIC=$(wc -c < ~/chameleon-zk/circuits/build/morph_validator/public.json 2>/dev/null || echo "N/A")

echo "  │ Circuit                    │ Proof    │ Public   │"
echo "  │ State Commitment           │ ${SC_PROOF} B   │ ${SC_PUBLIC} B    │"
echo "  │ Morph Validator            │ ${MV_PROOF} B   │ ${MV_PUBLIC} B   │"
echo "  │ Rust BN254 (raw)           │ 128 B    │          │"
echo "  │ Rust BLS12-381 (raw)       │ 192 B    │          │"

echo ""

# ================================================================
# SECTION 4: LATEST BENCHMARK
# PURPOSE: Show the most recent benchmark results so you can
# cite exact numbers during interviews.
# ================================================================
echo -e "${CYAN}--- LATEST BENCHMARK ---${NC}"
echo ""

LATEST=$(ls -t ~/chameleon-zk/benchmarks/results/benchmark_*.txt 2>/dev/null | head -1)

if [ -n "$LATEST" ]; then
    echo "  File: $(basename $LATEST)"
    echo ""
    cat "$LATEST" | while IFS= read -r line; do
        echo "  $line"
    done
else
    echo "  No benchmarks found."
    echo "  Run ~/chameleon-zk/benchmarks/run_benchmarks.sh first."
fi

echo ""

# ================================================================
# SECTION 5: DEPLOYED CONTRACTS
# PURPOSE: Show Etherscan links for your deployed contracts.
# Anyone can click these to verify your work.
# ================================================================
echo -e "${CYAN}--- DEPLOYED CONTRACTS ---${NC}"
echo ""

if [ -n "$STATE_VERIFIER_ADDRESS" ]; then
    echo "  State Verifier:     $STATE_VERIFIER_ADDRESS"
    echo "    https://sepolia.etherscan.io/address/$STATE_VERIFIER_ADDRESS"
    echo ""
fi

if [ -n "$MORPH_VERIFIER_ADDRESS" ]; then
    echo "  Morph Verifier:     $MORPH_VERIFIER_ADDRESS"
    echo "    https://sepolia.etherscan.io/address/$MORPH_VERIFIER_ADDRESS"
    echo ""
fi

if [ -n "$UNIVERSAL_VERIFIER_ADDRESS" ]; then
    echo "  Universal Verifier: $UNIVERSAL_VERIFIER_ADDRESS"
    echo "    https://sepolia.etherscan.io/address/$UNIVERSAL_VERIFIER_ADDRESS"
    echo ""
fi

if [ -n "$MORPH_CONTROLLER_ADDRESS" ]; then
    echo "  Morph Controller:   $MORPH_CONTROLLER_ADDRESS"
    echo "    https://sepolia.etherscan.io/address/$MORPH_CONTROLLER_ADDRESS"
    echo ""
fi

if [ -z "$STATE_VERIFIER_ADDRESS" ]; then
    echo "  No deployment addresses found."
    echo "  Check ~/chameleon-zk/deployment_addresses.txt"
fi

echo ""

# ================================================================
# SECTION 6: SYSTEM HEALTH CHECK
# PURPOSE: Quick check that everything is working.
# ================================================================
echo -e "${CYAN}--- SYSTEM HEALTH ---${NC}"
echo ""

CHECKS=0
GOOD=0

health() {
    ((CHECKS++))
    if [ $1 -eq 0 ]; then
        echo -e "  ${GREEN}✓${NC} $2"
        ((GOOD++))
    else
        echo -e "  ${RED}✗${NC} $2"
    fi
}

test -f ~/chameleon-zk/circuits/build/state_commitment/state_commitment_final.zkey
health $? "State commitment circuit ready"

test -f ~/chameleon-zk/circuits/build/morph_validator/morph_validator_final.zkey
health $? "Morph validator circuit ready"

cd ~/chameleon-zk/prover
cargo run --release -- status > /dev/null 2>&1
health $? "Rust prover operational"

cd ~/chameleon-zk/contracts
forge build > /dev/null 2>&1
health $? "Contracts compile"

test -x ~/chameleon-zk/scripts/threat_simulator.sh
health $? "Threat simulator ready"

test -x ~/chameleon-zk/scripts/auto_morph.sh
health $? "Auto-morph ready"

test -x ~/chameleon-zk/scripts/verify_onchain.sh
health $? "On-chain verification ready"

echo ""
echo "  Health: $GOOD / $CHECKS passed"
echo ""
echo "========================================"
echo ""
