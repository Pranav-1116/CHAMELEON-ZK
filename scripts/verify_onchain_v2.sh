#!/bin/bash

echo "     CHAMELEON-ZK ON-CHAIN VERIFICATION V2                "
echo ""

source ~/chameleon-zk/.env
source ~/chameleon-zk/deployment_addresses.txt

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

verify_with_calldata() {
    local name=$1
    local contract=$2
    local proof_dir=$3
    local expected_pub_count=$4
    
    echo -e "${BLUE}Verifying: $name${NC}"
    
    cd "$proof_dir"
    
    # First verify locally
    echo -e "${YELLOW}  Step 1: Local verification...${NC}"
    LOCAL_RESULT=$(snarkjs groth16 verify verification_key.json public.json proof.json 2>&1)
    if [[ "$LOCAL_RESULT" != *"OK"* ]]; then
        echo -e "${RED}  ✗ Local verification failed - proof is invalid${NC}"
        echo "  $LOCAL_RESULT"
        return 1
    fi
    echo -e "${GREEN}  ✓ Local verification passed${NC}"
    
    # Get proof components
    echo -e "${YELLOW}  Step 2: Extracting proof data...${NC}"
    
    A0=$(jq -r '.pi_a[0]' proof.json)
    A1=$(jq -r '.pi_a[1]' proof.json)
    
    # Note: B coordinates are swapped in the circuit format vs contract format
    B00=$(jq -r '.pi_b[0][1]' proof.json)
    B01=$(jq -r '.pi_b[0][0]' proof.json)
    B10=$(jq -r '.pi_b[1][1]' proof.json)
    B11=$(jq -r '.pi_b[1][0]' proof.json)
    
    C0=$(jq -r '.pi_c[0]' proof.json)
    C1=$(jq -r '.pi_c[1]' proof.json)
    
    # Get actual public signal count
    ACTUAL_PUB_COUNT=$(jq '. | length' public.json)
    echo "  Public signals count: $ACTUAL_PUB_COUNT"
    
    # Build public signals array
    PUBS=""
    for i in $(seq 0 $((ACTUAL_PUB_COUNT - 1))); do
        VAL=$(jq -r ".[$i]" public.json)
        if [ -n "$PUBS" ]; then
            PUBS="$PUBS,$VAL"
        else
            PUBS="$VAL"
        fi
    done
    
    echo "  Public signals: ${PUBS:0:50}..."
    
    echo -e "${YELLOW}  Step 3: Calling on-chain verifier...${NC}"
    
    # Build function signature based on public signal count
    FUNC_SIG="verifyProof(uint256[2],uint256[2][2],uint256[2],uint256[$ACTUAL_PUB_COUNT])(bool)"
    
    echo "  Function: $FUNC_SIG"
    
    RESULT=$(cast call "$contract" \
        "$FUNC_SIG" \
        "[$A0,$A1]" \
        "[[$B00,$B01],[$B10,$B11]]" \
        "[$C0,$C1]" \
        "[$PUBS]" \
        --rpc-url "$SEPOLIA_RPC_URL" 2>&1)
    
    echo "  Result: $RESULT"
    
    if [[ "$RESULT" == "true" ]]; then
        echo -e "${GREEN}  ✓ ON-CHAIN VERIFICATION PASSED!${NC}"
        return 0
    elif [[ "$RESULT" == "false" ]]; then
        echo -e "${RED}  ✗ On-chain verification returned FALSE${NC}"
        echo ""
        echo "  This usually means the verifier contract expects different data."
        echo "  The contract and proof may have been generated with different keys."
        return 1
    else
        echo -e "${RED}  ✗ Error during verification${NC}"
        
        # Try alternative: maybe the contract uses dynamic array
        echo ""
        echo -e "${YELLOW}  Trying with dynamic array signature...${NC}"
        
        RESULT2=$(cast call "$contract" \
            "verifyProof(uint256[2],uint256[2][2],uint256[2],uint256[])(bool)" \
            "[$A0,$A1]" \
            "[[$B00,$B01],[$B10,$B11]]" \
            "[$C0,$C1]" \
            "[$PUBS]" \
            --rpc-url "$SEPOLIA_RPC_URL" 2>&1)
        
        echo "  Result: $RESULT2"
        
        if [[ "$RESULT2" == "true" ]]; then
            echo -e "${GREEN}  ✓ ON-CHAIN VERIFICATION PASSED!${NC}"
            return 0
        fi
        
        return 1
    fi
}

echo ""
PASSED=0
FAILED=0

# Verify Simple
verify_with_calldata "Simple Multiplier" "$SIMPLE_VERIFIER_ADDRESS" ~/chameleon-zk/circuits/build 1
if [ $? -eq 0 ]; then ((PASSED++)); else ((FAILED++)); fi

echo ""
sleep 1

# Verify State Commitment  
verify_with_calldata "State Commitment" "$STATE_VERIFIER_ADDRESS" ~/chameleon-zk/circuits/build/state_commitment 2
if [ $? -eq 0 ]; then ((PASSED++)); else ((FAILED++)); fi

echo ""
sleep 1

# Verify Morph Validator
verify_with_calldata "Morph Validator" "$MORPH_VERIFIER_ADDRESS" ~/chameleon-zk/circuits/build/morph_validator 4
if [ $? -eq 0 ]; then ((PASSED++)); else ((FAILED++)); fi

echo ""
echo -e "${BLUE}SUMMARY${NC}"
echo -e "  Passed: ${GREEN}$PASSED${NC} / 3"
echo -e "  Failed: ${RED}$FAILED${NC} / 3"
echo ""
