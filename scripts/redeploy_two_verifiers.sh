#!/bin/bash

source ~/chameleon-zk/.env

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║      REDEPLOYING SIMPLE & STATE VERIFIERS                 ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

cd ~/chameleon-zk/contracts

# Check balance first
BALANCE=$(cast balance $(cast wallet address --private-key $PRIVATE_KEY) --rpc-url $SEPOLIA_RPC_URL --ether)
echo -e "${YELLOW}Wallet balance: $BALANCE ETH${NC}"
echo ""

# Deploy Simple Verifier
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Deploying Simple Verifier..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

SIMPLE_RESULT=$(forge create --rpc-url $SEPOLIA_RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast \
    src/Verifier.sol:Groth16Verifier 2>&1)

echo "$SIMPLE_RESULT"

SIMPLE_ADDRESS=$(echo "$SIMPLE_RESULT" | grep "Deployed to:" | awk '{print $3}')

if [ -n "$SIMPLE_ADDRESS" ]; then
    echo -e "${GREEN}✓ Simple Verifier deployed to: $SIMPLE_ADDRESS${NC}"
else
    echo -e "${RED}✗ Failed to deploy Simple Verifier${NC}"
    exit 1
fi

echo ""
sleep 5

# Deploy State Commitment Verifier
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Deploying State Commitment Verifier..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

STATE_RESULT=$(forge create --rpc-url $SEPOLIA_RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast \
    src/StateCommitmentVerifier.sol:Groth16Verifier 2>&1)

echo "$STATE_RESULT"

STATE_ADDRESS=$(echo "$STATE_RESULT" | grep "Deployed to:" | awk '{print $3}')

if [ -n "$STATE_ADDRESS" ]; then
    echo -e "${GREEN}✓ State Commitment Verifier deployed to: $STATE_ADDRESS${NC}"
else
    echo -e "${RED}✗ Failed to deploy State Commitment Verifier${NC}"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}DEPLOYMENT COMPLETE${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "NEW ADDRESSES - Update deployment_addresses.txt with these:"
echo ""
echo "SIMPLE_VERIFIER_ADDRESS=$SIMPLE_ADDRESS"
echo "STATE_VERIFIER_ADDRESS=$STATE_ADDRESS"
echo ""
echo "Run this command to update:"
echo ""
echo "sed -i 's/SIMPLE_VERIFIER_ADDRESS=.*/SIMPLE_VERIFIER_ADDRESS=$SIMPLE_ADDRESS/' ~/chameleon-zk/deployment_addresses.txt"
echo "sed -i 's/STATE_VERIFIER_ADDRESS=.*/STATE_VERIFIER_ADDRESS=$STATE_ADDRESS/' ~/chameleon-zk/deployment_addresses.txt"
