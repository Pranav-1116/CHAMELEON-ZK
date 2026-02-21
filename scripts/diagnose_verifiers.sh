#!/bin/bash

source ~/chameleon-zk/.env
source ~/chameleon-zk/deployment_addresses.txt

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║      VERIFIER DIAGNOSTIC TOOL                             ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Function to analyze a circuit
analyze_circuit() {
    local name=$1
    local dir=$2
    local contract=$3
    local verifier_file=$4
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${YELLOW}Analyzing: $name${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    echo ""
    echo "1. Public signals in proof:"
    cd "$dir"
    cat public.json
    echo ""
    
    PUB_COUNT=$(jq '. | length' public.json)
    echo "   Count: $PUB_COUNT"
    
    echo ""
    echo "2. Expected public signals in verifier contract:"
    grep -o "uint256\[[0-9]*\].*_pubSignals" ~/chameleon-zk/contracts/src/$verifier_file 2>/dev/null || \
    grep -o "uint\[[0-9]*\].*public" ~/chameleon-zk/contracts/src/$verifier_file 2>/dev/null || \
    echo "   Could not find - checking full signature..."
    
    grep "function verifyProof" ~/chameleon-zk/contracts/src/$verifier_file
    
    echo ""
    echo "3. Local verification:"
    VERIFY_RESULT=$(snarkjs groth16 verify verification_key.json public.json proof.json 2>&1)
    if [[ "$VERIFY_RESULT" == *"OK"* ]]; then
        echo -e "   ${GREEN}✓ Local verification PASSED${NC}"
    else
        echo -e "   ${RED}✗ Local verification FAILED${NC}"
        echo "   $VERIFY_RESULT"
    fi
    
    echo ""
    echo "4. Contract deployed at: $contract"
    CODE=$(cast code $contract --rpc-url $SEPOLIA_RPC_URL 2>/dev/null)
    if [ ${#CODE} -gt 10 ]; then
        echo -e "   ${GREEN}✓ Contract exists${NC}"
    else
        echo -e "   ${RED}✗ No code at address${NC}"
    fi
    
    echo ""
}

# Analyze each circuit
analyze_circuit "Simple Multiplier" \
    ~/chameleon-zk/circuits/build \
    $SIMPLE_VERIFIER_ADDRESS \
    "Verifier.sol"

analyze_circuit "State Commitment" \
    ~/chameleon-zk/circuits/build/state_commitment \
    $STATE_VERIFIER_ADDRESS \
    "StateCommitmentVerifier.sol"

analyze_circuit "Morph Validator" \
    ~/chameleon-zk/circuits/build/morph_validator \
    $MORPH_VERIFIER_ADDRESS \
    "MorphValidatorVerifier.sol"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "DIAGNOSTIC COMPLETE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
