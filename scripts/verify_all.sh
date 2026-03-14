#!/bin/bash

echo "---------------------------------------------------"
echo "CHAMELEON-ZK ON-CHAIN VERIFICATION"
echo "---------------------------------------------------"
echo ""

source ~/chameleon-zk/.env
source ~/chameleon-zk/deployment_addresses.txt

if [ -z "$SEPOLIA_RPC_URL" ] || [ -z "$STATE_VERIFIER_ADDRESS" ]; then
    echo "ERROR: Environment not configured"
    exit 1
fi

echo "Network: Sepolia Testnet"
echo "RPC: ${SEPOLIA_RPC_URL:0:50}..."
echo ""
echo "Contracts:"
echo ""
echo "  State Verifier: $STATE_VERIFIER_ADDRESS"
echo ""
echo "  Morph Verifier: $MORPH_VERIFIER_ADDRESS"
echo ""
echo "  Universal Verifier: $UNIVERSAL_VERIFIER_ADDRESS"
echo ""

PASSED=0
FAILED=0

verify_proof() {
    local name=$1
    local contract=$2
    local proof_dir=$3
    local pub_count=$4
    
    echo ""
    echo "---------------------------------------------------"
    echo "Verifying: $name"
    echo ""
    echo "Contract: $contract"
    echo ""
    echo "Public inputs: $pub_count"
    echo "---------------------------------------------------"
    
    cd $proof_dir
    
    A0=$(jq -r '.pi_a[0]' proof.json)
    A1=$(jq -r '.pi_a[1]' proof.json)
    B00=$(jq -r '.pi_b[0][1]' proof.json)
    B01=$(jq -r '.pi_b[0][0]' proof.json)
    B10=$(jq -r '.pi_b[1][1]' proof.json)
    B11=$(jq -r '.pi_b[1][0]' proof.json)
    C0=$(jq -r '.pi_c[0]' proof.json)
    C1=$(jq -r '.pi_c[1]' proof.json)
    
    if [ $pub_count -eq 2 ]; then
        P0=$(jq -r '.[0]' public.json)
        P1=$(jq -r '.[1]' public.json)
        PUBS="[$P0,$P1]"
    else
        P0=$(jq -r '.[0]' public.json)
        P1=$(jq -r '.[1]' public.json)
        P2=$(jq -r '.[2]' public.json)
        P3=$(jq -r '.[3]' public.json)
        PUBS="[$P0,$P1,$P2,$P3]"
    fi
    
    echo "Public inputs: $PUBS"
    echo "Calling contract..."
    
    SIG="verifyProof(uint256[2],uint256[2][2],uint256[2],uint256[$pub_count])"
    
    RESULT=$(cast call $contract "$SIG" "[$A0,$A1]" "[[$B00,$B01],[$B10,$B11]]" "[$C0,$C1]" "$PUBS" --rpc-url $SEPOLIA_RPC_URL 2>&1)
    
    echo "Raw result: $RESULT"
    
    if [[ "$RESULT" == "0x0000000000000000000000000000000000000000000000000000000000000001" ]]; then
        echo " PROOF VERIFIED ON-CHAIN!"
        return 0
    else
        echo " FAILED: $RESULT"
        return 1
    fi
}

verify_proof "State Commitment" "$STATE_VERIFIER_ADDRESS" ~/chameleon-zk/circuits/build/state_commitment 2
if [ $? -eq 0 ]; then
    ((PASSED++))
else
    ((FAILED++))
fi

echo ""

verify_proof "Morph Validator" "$MORPH_VERIFIER_ADDRESS" ~/chameleon-zk/circuits/build/morph_validator 4
if [ $? -eq 0 ]; then
    ((PASSED++))
else
    ((FAILED++))
fi

echo ""
echo "VERIFICATION SUMMARY"
echo ""
echo "Passed: $PASSED"
echo ""
echo "Failed: $FAILED"
echo ""

if [ $FAILED -eq 0 ]; then
    echo " ALL PROOFS VERIFIED SUCCESSFULLY ON SEPOLIA!"
    exit 0
else
    echo " $FAILED verification(s) failed"
    exit 1
fi