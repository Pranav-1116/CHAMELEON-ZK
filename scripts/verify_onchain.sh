#!/bin/bash

echo "      CHAMELEON-ZK ON-CHAIN VERIFICATION                   "
echo ""

# Load environment
source ~/chameleon-zk/.env
source ~/chameleon-zk/deployment_addresses.txt

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to verify a proof
verify_proof() {
    local name=$1
    local contract=$2
    local proof_dir=$3
    
    echo "Verifying: $name"
    
    cd $proof_dir
    
    # Get calldata
    CALLDATA=$(snarkjs zkey export soliditycalldata public.json proof.json)
    
    echo -e "${YELLOW}Sending verification transaction...${NC}"
    
    # Call verify function
    RESULT=$(cast call $contract "verifyProof(uint256[2],uint256[2][2],uint256[2],uint256[])" \
        $CALLDATA \
        --rpc-url $SEPOLIA_RPC_URL 2>&1)
    
    # Check result (should end with ...0001 for true)
    if [[ "$RESULT" == *"0000000000000000000000000000000000000000000000000000000000000001" ]]; then
        echo -e "${GREEN}✓ Proof verified successfully on-chain!${NC}"
        return 0
    else
        echo -e "${RED}✗ Proof verification failed${NC}"
        echo "Result: $RESULT"
        return 1
    fi
}

# Verify Simple Proof
verify_proof "Simple Multiplier (3 × 7 = 21)" \
    "$SIMPLE_VERIFIER_ADDRESS" \
    ~/chameleon-zk/circuits/build

echo ""

# Verify State Commitment Proof
verify_proof "State Commitment" \
    "$STATE_VERIFIER_ADDRESS" \
    ~/chameleon-zk/circuits/build/state_commitment

echo ""

# Verify Morph Validator Proof
verify_proof "Morph Validator" \
    "$MORPH_VERIFIER_ADDRESS" \
    ~/chameleon-zk/circuits/build/morph_validator

echo ""
echo "ON-CHAIN VERIFICATION COMPLETE"
