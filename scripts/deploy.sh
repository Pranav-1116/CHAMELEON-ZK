#!/bin/bash

echo "    CHAMELEON-ZK SEPOLIA DEPLOYMENT                      "
echo ""

# Load environment variables
source ~/chameleon-zk/.env

# Check if environment is set
if [ -z "$SEPOLIA_RPC_URL" ] || [ -z "$PRIVATE_KEY" ]; then
    echo "ERROR: Please set SEPOLIA_RPC_URL and PRIVATE_KEY in .env"
    exit 1
fi

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Contract directory
CONTRACTS_DIR=~/chameleon-zk/contracts

echo -e "${YELLOW}Checking wallet balance...${NC}"
BALANCE=$(cast balance $(cast wallet address --private-key $PRIVATE_KEY) --rpc-url $SEPOLIA_RPC_URL)
echo "Wallet balance: $BALANCE wei"
echo ""

# Deploy Simple Verifier
echo "Deploying Simple Verifier..."

cd $CONTRACTS_DIR

SIMPLE_DEPLOY=$(forge create --rpc-url $SEPOLIA_RPC_URL \
    --private-key $PRIVATE_KEY \
    src/Verifier.sol:Groth16Verifier 2>&1)

SIMPLE_ADDRESS=$(echo "$SIMPLE_DEPLOY" | grep "Deployed to:" | awk '{print $3}')

if [ -n "$SIMPLE_ADDRESS" ]; then
    echo -e "${GREEN}Simple Verifier deployed to: $SIMPLE_ADDRESS${NC}"
else
    echo -e "${RED}Failed to deploy Simple Verifier${NC}"
    echo "$SIMPLE_DEPLOY"
fi

echo ""
sleep 5  # Wait between deployments

# Deploy State Commitment Verifier
echo "Deploying State Commitment Verifier..."

STATE_DEPLOY=$(forge create --rpc-url $SEPOLIA_RPC_URL \
    --private-key $PRIVATE_KEY \
    src/StateCommitmentVerifier.sol:Groth16Verifier 2>&1)

STATE_ADDRESS=$(echo "$STATE_DEPLOY" | grep "Deployed to:" | awk '{print $3}')

if [ -n "$STATE_ADDRESS" ]; then
    echo -e "${GREEN}State Commitment Verifier deployed to: $STATE_ADDRESS${NC}"
else
    echo -e "${RED}Failed to deploy State Commitment Verifier${NC}"
    echo "$STATE_DEPLOY"
fi

echo ""
sleep 5

# Deploy Morph Validator Verifier
echo "Deploying Morph Validator Verifier..."

MORPH_DEPLOY=$(forge create --rpc-url $SEPOLIA_RPC_URL \
    --private-key $PRIVATE_KEY \
    src/MorphValidatorVerifier.sol:Groth16Verifier 2>&1)

MORPH_ADDRESS=$(echo "$MORPH_DEPLOY" | grep "Deployed to:" | awk '{print $3}')

if [ -n "$MORPH_ADDRESS" ]; then
    echo -e "${GREEN}Morph Validator Verifier deployed to: $MORPH_ADDRESS${NC}"
else
    echo -e "${RED}Failed to deploy Morph Validator Verifier${NC}"
    echo "$MORPH_DEPLOY"
fi

echo ""
sleep 5

# Deploy Universal Verifier
echo "Deploying Universal Verifier..."

UNIVERSAL_DEPLOY=$(forge create --rpc-url $SEPOLIA_RPC_URL \
    --private-key $PRIVATE_KEY \
    src/UniversalVerifier.sol:UniversalVerifier 2>&1)

UNIVERSAL_ADDRESS=$(echo "$UNIVERSAL_DEPLOY" | grep "Deployed to:" | awk '{print $3}')

if [ -n "$UNIVERSAL_ADDRESS" ]; then
    echo -e "${GREEN}Universal Verifier deployed to: $UNIVERSAL_ADDRESS${NC}"
else
    echo -e "${RED}Failed to deploy Universal Verifier${NC}"
    echo "$UNIVERSAL_DEPLOY"
fi

echo ""
sleep 5

# Deploy Morph Controller
echo "Deploying Morph Controller..."

if [ -n "$UNIVERSAL_ADDRESS" ]; then
    CONTROLLER_DEPLOY=$(forge create --rpc-url $SEPOLIA_RPC_URL \
        --private-key $PRIVATE_KEY \
        --constructor-args $UNIVERSAL_ADDRESS \
        src/MorphController.sol:MorphController 2>&1)
    
    CONTROLLER_ADDRESS=$(echo "$CONTROLLER_DEPLOY" | grep "Deployed to:" | awk '{print $3}')
    
    if [ -n "$CONTROLLER_ADDRESS" ]; then
        echo -e "${GREEN}Morph Controller deployed to: $CONTROLLER_ADDRESS${NC}"
    else
        echo -e "${RED}Failed to deploy Morph Controller${NC}"
        echo "$CONTROLLER_DEPLOY"
    fi
else
    echo -e "${RED}Skipping Morph Controller - Universal Verifier not deployed${NC}"
fi

echo ""
echo "DEPLOYMENT SUMMARY"
echo ""
echo "Simple Verifier:      ${SIMPLE_ADDRESS:-NOT DEPLOYED}"
echo "State Verifier:       ${STATE_ADDRESS:-NOT DEPLOYED}"
echo "Morph Verifier:       ${MORPH_ADDRESS:-NOT DEPLOYED}"
echo "Universal Verifier:   ${UNIVERSAL_ADDRESS:-NOT DEPLOYED}"
echo "Morph Controller:     ${CONTROLLER_ADDRESS:-NOT DEPLOYED}"
echo ""
echo "Save these addresses to your .env file!"
echo ""

# Save to a file
echo "# Deployment Addresses - $(date)" > ~/chameleon-zk/deployment_addresses.txt
echo "SIMPLE_VERIFIER_ADDRESS=$SIMPLE_ADDRESS" >> ~/chameleon-zk/deployment_addresses.txt
echo "STATE_VERIFIER_ADDRESS=$STATE_ADDRESS" >> ~/chameleon-zk/deployment_addresses.txt
echo "MORPH_VERIFIER_ADDRESS=$MORPH_ADDRESS" >> ~/chameleon-zk/deployment_addresses.txt
echo "UNIVERSAL_VERIFIER_ADDRESS=$UNIVERSAL_ADDRESS" >> ~/chameleon-zk/deployment_addresses.txt
echo "MORPH_CONTROLLER_ADDRESS=$CONTROLLER_ADDRESS" >> ~/chameleon-zk/deployment_addresses.txt

echo "Addresses saved to deployment_addresses.txt"