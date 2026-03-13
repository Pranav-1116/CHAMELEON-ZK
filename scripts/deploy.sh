
#!/bin/bash

echo "-----------------------------------------------------------"
echo "    CHAMELEON-ZK SEPOLIA DEPLOYMENT                        "
echo "-----------------------------------------------------------"

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

cd $CONTRACTS_DIR

# Step 1: Deploy BN254Verifier
echo "----------------------------------"
echo "Deploying BN254Verifier..."
echo "----------------------------------"

BN254_DEPLOY=$(forge create src/Verifier.sol:BN254Verifier \
    --rpc-url $SEPOLIA_RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast 2>&1)

BN254_ADDRESS=$(echo "$BN254_DEPLOY" | grep "Deployed to:" | awk '{print $3}')

if [ -n "$BN254_ADDRESS" ]; then
    echo -e "${GREEN}BN254Verifier deployed to: $BN254_ADDRESS${NC}"
else
    echo -e "${RED}Failed to deploy BN254Verifier${NC}"
    echo "$BN254_DEPLOY"
    exit 1
fi

echo ""
sleep 5

# Step 2: Deploy State Commitment Verifier
echo "----------------------------------"
echo "Deploying State Commitment Verifier..."
echo "Constructor arg: $BN254_ADDRESS"
echo "----------------------------------"

echo -e "${YELLOW}  Using cast send method (forge create has broadcast issue)...${NC}"

# Get compiled bytecode
BYTECODE=$(jq -r '.bytecode.object' out/StateCommitmentVerifier.sol/StateCommitmentVerifier.json)
CONSTRUCTOR_ARGS=$(cast abi-encode "constructor(address)" $BN254_ADDRESS)
FULL_BYTECODE="${BYTECODE}${CONSTRUCTOR_ARGS:2}"

# Deploy using cast send
STATE_DEPLOY=$(cast send --rpc-url $SEPOLIA_RPC_URL \
    --private-key $PRIVATE_KEY \
    --create $FULL_BYTECODE \
    --json 2>&1)

STATE_ADDRESS=$(echo "$STATE_DEPLOY" | jq -r '.contractAddress')

if [ -n "$STATE_ADDRESS" ]; then
    echo -e "${GREEN}State Commitment Verifier deployed to: $STATE_ADDRESS${NC}"
else
    echo -e "${RED}Failed to deploy State Commitment Verifier${NC}"
    echo "$STATE_DEPLOY"
fi

echo ""
sleep 5

# Step 3: Deploy Morph Validator Verifier
echo "----------------------------------"
echo "Deploying Morph Validator Verifier..."
echo "----------------------------------"

MORPH_DEPLOY=$(forge create src/MorphVerifier.sol:Groth16Verifier \
    --rpc-url $SEPOLIA_RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast 2>&1)

MORPH_ADDRESS=$(echo "$MORPH_DEPLOY" | grep "Deployed to:" | awk '{print $3}')

if [ -n "$MORPH_ADDRESS" ]; then
    echo -e "${GREEN}Morph Validator Verifier deployed to: $MORPH_ADDRESS${NC}"
else
    echo -e "${RED}Failed to deploy Morph Validator Verifier${NC}"
    echo "$MORPH_DEPLOY"
fi

echo ""
sleep 5

# Step 4: Deploy Universal Verifier
echo "----------------------------------"
echo "Deploying Universal Verifier..."
echo "----------------------------------"

UNIVERSAL_DEPLOY=$(forge create src/UniversalVerifier.sol:UniversalVerifier \
    --rpc-url $SEPOLIA_RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast 2>&1)

UNIVERSAL_ADDRESS=$(echo "$UNIVERSAL_DEPLOY" | grep "Deployed to:" | awk '{print $3}')

if [ -n "$UNIVERSAL_ADDRESS" ]; then
    echo -e "${GREEN}Universal Verifier deployed to: $UNIVERSAL_ADDRESS${NC}"
else
    echo -e "${RED}Failed to deploy Universal Verifier${NC}"
    echo "$UNIVERSAL_DEPLOY"
fi

echo ""
sleep 5

# Step 5: Deploy Morph Controller
# Step 5: Deploy Morph Controller
echo "----------------------------------"
echo "Deploying Morph Controller..."
echo "Constructor arg: $UNIVERSAL_ADDRESS"
echo "----------------------------------"

if [ -n "$UNIVERSAL_ADDRESS" ]; then
    echo -e "${YELLOW}  Using cast send method...${NC}"
    
    # Get compiled bytecode
    BYTECODE=$(jq -r '.bytecode.object' out/MorphController.sol/MorphController.json)
    CONSTRUCTOR_ARGS=$(cast abi-encode "constructor(address)" $UNIVERSAL_ADDRESS)
    FULL_BYTECODE="${BYTECODE}${CONSTRUCTOR_ARGS:2}"
    
    # Deploy using cast send
    CONTROLLER_DEPLOY=$(cast send --rpc-url $SEPOLIA_RPC_URL \
        --private-key $PRIVATE_KEY \
        --create $FULL_BYTECODE \
        --json 2>&1)
    
    CONTROLLER_ADDRESS=$(echo "$CONTROLLER_DEPLOY" | jq -r '.contractAddress')
    
    if [ -n "$CONTROLLER_ADDRESS" ] && [ "$CONTROLLER_ADDRESS" != "null" ]; then
        echo -e "${GREEN}Morph Controller deployed to: $CONTROLLER_ADDRESS${NC}"
    else
        echo -e "${RED}Failed to deploy Morph Controller${NC}"
        echo "$CONTROLLER_DEPLOY"
    fi
else
    echo -e "${RED}Skipping Morph Controller - Universal Verifier not deployed${NC}"
fi

echo ""
echo "----------------------------------"
echo -e "${GREEN}DEPLOYMENT SUMMARY${NC}"
echo "----------------------------------"
echo ""
echo "BN254 Verifier:       ${BN254_ADDRESS:-NOT DEPLOYED}"
echo "State Verifier:       ${STATE_ADDRESS:-NOT DEPLOYED}"
echo "Morph Verifier:       ${MORPH_ADDRESS:-NOT DEPLOYED}"
echo "Universal Verifier:   ${UNIVERSAL_ADDRESS:-NOT DEPLOYED}"
echo "Morph Controller:     ${CONTROLLER_ADDRESS:-NOT DEPLOYED}"
echo ""

# Save to a file
cat > ~/chameleon-zk/deployment_addresses.txt << EOF
# Deployment Addresses - $(date)
# Network: Sepolia Testnet

BN254_VERIFIER_ADDRESS=$BN254_ADDRESS
STATE_VERIFIER_ADDRESS=$STATE_ADDRESS
MORPH_VERIFIER_ADDRESS=$MORPH_ADDRESS
UNIVERSAL_VERIFIER_ADDRESS=$UNIVERSAL_ADDRESS
MORPH_CONTROLLER_ADDRESS=$CONTROLLER_ADDRESS
EOF

echo -e "${GREEN}Addresses saved to deployment_addresses.txt${NC}"
echo ""

# Step 6: Configure Universal Verifier (Register Backends)
# Step 6: Configure Universal Verifier (Register Verifiers)
echo "----------------------------------"
echo -e "${YELLOW}Registering verifiers in Universal Verifier...${NC}"
echo "----------------------------------"

if [ -n "$UNIVERSAL_ADDRESS" ] && [ -n "$BN254_ADDRESS" ]; then
    # Register BN254 as State Commitment Verifier (backend 0)
    echo "Registering BN254 State Commitment Verifier..."
    STATE_REG=$(cast send $UNIVERSAL_ADDRESS \
        "setStateCommitmentVerifier(uint8,address)" \
        0 \
        $STATE_ADDRESS \
        --rpc-url $SEPOLIA_RPC_URL \
        --private-key $PRIVATE_KEY \
        --json 2>&1)
    
    if [[ $STATE_REG == *"transactionHash"* ]]; then
        echo -e "${GREEN}✓ BN254 State Commitment Verifier registered${NC}"
    else
        echo -e "${YELLOW}⚠ State verifier registration may have failed${NC}"
        echo "$STATE_REG"
    fi
    sleep 3
    
    # Register BN254 as Morph Validator Verifier (backend 0)
    echo "Registering BN254 Morph Validator Verifier..."
    MORPH_REG=$(cast send $UNIVERSAL_ADDRESS \
        "setMorphValidatorVerifier(uint8,address)" \
        0 \
        $MORPH_ADDRESS \
        --rpc-url $SEPOLIA_RPC_URL \
        --private-key $PRIVATE_KEY \
        --json 2>&1)
    
    if [[ $MORPH_REG == *"transactionHash"* ]]; then
        echo -e "${GREEN}✓ BN254 Morph Validator Verifier registered${NC}"
    else
        echo -e "${YELLOW}⚠ Morph verifier registration may have failed${NC}"
        echo "$MORPH_REG"
    fi
    sleep 3
fi

echo ""
echo "-------------------------------------------------------------"
echo "           DEPLOYMENT COMPLETE!                              "
echo "-------------------------------------------------------------"
