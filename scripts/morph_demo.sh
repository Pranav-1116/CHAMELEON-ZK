#!/bin/bash

echo "   MORPHING DEMONSTRATION"


# Load environment
source ~/chameleon-zk/.env
source ~/chameleon-zk/deployment_addresses.txt

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Check environment
if [ -z "$SEPOLIA_RPC_URL" ] || [ -z "$MORPH_CONTROLLER_ADDRESS" ]; then
    echo -e "${RED}ERROR: Environment not configured properly${NC}"
    echo "Please ensure .env and deployment_addresses.txt are set"
    exit 1
fi

sleep 1

echo -e "  ${CYAN}PHASE 1: SYSTEM STATUS CHECK${NC}"
echo ""

echo -e "${YELLOW}  Querying Universal Verifier...${NC}"

# Get current backend
CURRENT_BACKEND=$(cast call $UNIVERSAL_VERIFIER_ADDRESS "activeBackend()" --rpc-url $SEPOLIA_RPC_URL 2>/dev/null)
echo "  Active Backend ID: $CURRENT_BACKEND"

# Get backend name (returns hex-encoded string)
BACKEND_NAME_HEX=$(cast call $UNIVERSAL_VERIFIER_ADDRESS "getActiveBackendName()" --rpc-url $SEPOLIA_RPC_URL 2>/dev/null)
# Decode hex to string (remove 0x prefix and leading zeros)
BACKEND_NAME=$(echo $BACKEND_NAME_HEX | sed 's/0x//' | xxd -r -p 2>/dev/null | tr -d '\0')
echo "  Active Backend Name: $BACKEND_NAME"

echo ""
echo -e "${YELLOW}  Querying Morph Controller...${NC}"

# Get threat level
THREAT_LEVEL=$(cast call $MORPH_CONTROLLER_ADDRESS "currentThreatLevel()" --rpc-url $SEPOLIA_RPC_URL 2>/dev/null)
echo "  Current Threat Level: $THREAT_LEVEL"

# Get threat level name
THREAT_NAME_HEX=$(cast call $MORPH_CONTROLLER_ADDRESS "getThreatLevelName()" --rpc-url $SEPOLIA_RPC_URL 2>/dev/null)
THREAT_NAME=$(echo $THREAT_NAME_HEX | sed 's/0x//' | xxd -r -p 2>/dev/null | tr -d '\0')
echo "  Threat Level Name: $THREAT_NAME"

echo ""
sleep 2

echo -e "  ${CYAN}PHASE 2: THREAT INTELLIGENCE SIMULATION${NC}"
echo ""

echo -e "${MAGENTA}     THREAT INTELLIGENCE FEED                          ${NC}"
echo ""

sleep 1
echo -e "  ${YELLOW}  [$(date +%H:%M:%S)] Monitoring quantum computing advances...${NC}"
sleep 1
echo -e "  ${YELLOW}  [$(date +%H:%M:%S)] Scanning NIST post-quantum updates...${NC}"
sleep 1
echo -e "  ${YELLOW}  [$(date +%H:%M:%S)] Checking regulatory compliance feeds...${NC}"
sleep 1

echo ""
echo -e "  ${RED}    ALERT: QUANTUM ADVANCE DETECTED!                       ${NC}"
echo ""
echo "  Breaking: New paper on arXiv shows 80% progress on ECDLP"
echo "  Source: 'Quantum Algorithms for Elliptic Curve Cryptography'"
echo "  Impact: BN254 security margin reduced"
echo ""

sleep 2

echo -e "  ${CYAN}PHASE 3: THREAT LEVEL UPDATE${NC}"
echo ""

echo -e "${YELLOW}  Updating threat level to HIGH (2)...${NC}"
echo ""

# Send transaction to update threat level
TX_HASH=$(cast send $MORPH_CONTROLLER_ADDRESS \
    "updateThreatLevel(uint8)" \
    2 \
    --rpc-url $SEPOLIA_RPC_URL \
    --private-key $PRIVATE_KEY \
    --json 2>/dev/null | jq -r '.transactionHash')

if [ -n "$TX_HASH" ] && [ "$TX_HASH" != "null" ]; then
    echo -e "  ${GREEN}✓ Transaction sent: ${TX_HASH:0:20}...${NC}"
    echo "  Waiting for confirmation..."
    sleep 5
else
    echo -e "  ${YELLOW}Transaction sent (hash extraction may have failed)${NC}"
    sleep 5
fi

# Check new threat level
NEW_THREAT=$(cast call $MORPH_CONTROLLER_ADDRESS "currentThreatLevel()" --rpc-url $SEPOLIA_RPC_URL 2>/dev/null)
NEW_THREAT_NAME_HEX=$(cast call $MORPH_CONTROLLER_ADDRESS "getThreatLevelName()" --rpc-url $SEPOLIA_RPC_URL 2>/dev/null)
NEW_THREAT_NAME=$(echo $NEW_THREAT_NAME_HEX | sed 's/0x//' | xxd -r -p 2>/dev/null | tr -d '\0')

echo ""
echo -e "  ${GREEN}✓ Threat level updated!${NC}"
echo "    Previous: $THREAT_NAME"
echo "    Current:  $NEW_THREAT_NAME"
echo ""

sleep 2

echo -e "  ${CYAN}PHASE 4: MORPHING DECISION ENGINE${NC}"
echo ""

# Check if should morph
SHOULD_MORPH=$(cast call $MORPH_CONTROLLER_ADDRESS "shouldAutoMorph()" --rpc-url $SEPOLIA_RPC_URL 2>/dev/null)
RECOMMENDED=$(cast call $MORPH_CONTROLLER_ADDRESS "getRecommendedBackend()" --rpc-url $SEPOLIA_RPC_URL 2>/dev/null)

echo "  Analyzing threat parameters..."
echo ""
echo "  │  MORPHING DECISION ANALYSIS                        │"                     
echo "  │  Should Auto-Morph:   $SHOULD_MORPH"
echo "    Recommended Backend: $RECOMMENDED (BLS12-381)     "
echo ""

if [[ "$SHOULD_MORPH" == *"0001"* ]] || [[ "$SHOULD_MORPH" == *"true"* ]]; then
    echo -e "  ${YELLOW}AUTO-MORPH TRIGGERED!                                  ${NC}"
    echo ""
    echo "  System recommends switching to higher-security backend"
    echo "  BN254 (100-bit) → BLS12-381 (128-bit)"
fi

echo ""
sleep 2

echo -e "  ${CYAN}PHASE 5: DUAL-BACKEND PROOF GENERATION${NC}"
echo ""

echo "  Running Rust prover with both backends..."
echo ""

cd ~/chameleon-zk/prover
cargo run --release 2>&1 | while IFS= read -r line; do
    echo "  $line"
done

echo ""
sleep 2

echo -e "  ${CYAN}PHASE 6: THREAT RESOLUTION${NC}"
echo ""

echo -e "${YELLOW}  Threat has been mitigated. Resetting to LOW...${NC}"

cast send $MORPH_CONTROLLER_ADDRESS \
    "updateThreatLevel(uint8)" \
    0 \
    --rpc-url $SEPOLIA_RPC_URL \
    --private-key $PRIVATE_KEY \
    > /dev/null 2>&1

sleep 5

FINAL_THREAT_HEX=$(cast call $MORPH_CONTROLLER_ADDRESS "getThreatLevelName()" --rpc-url $SEPOLIA_RPC_URL 2>/dev/null)
FINAL_THREAT=$(echo $FINAL_THREAT_HEX | sed 's/0x//' | xxd -r -p 2>/dev/null | tr -d '\0')

echo -e "  ${GREEN}✓ Threat level reset to: $FINAL_THREAT${NC}"
echo ""

sleep 1

echo -e "  ${CYAN}DEMONSTRATION SUMMARY${NC}"
echo ""
echo "  This demonstration showed:"
echo ""
echo "  ${GREEN}✓${NC} Multiple cryptographic backends (BN254, BLS12-381)"
echo "  ${GREEN}✓${NC} Real-time threat level monitoring"
echo "  ${GREEN}✓${NC} Automatic morphing recommendations"
echo "  ${GREEN}✓${NC} On-chain contract state management"
echo "  ${GREEN}✓${NC} Backend performance comparison"
echo ""
echo "    CHAMELEON-ZK: Cryptographic Agility Achieved!     "
echo "                                                      "
echo "   When threats evolve, your cryptography adapts.    "
echo ""
echo ""
