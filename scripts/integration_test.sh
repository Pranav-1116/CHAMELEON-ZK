#!/bin/bash

echo "       CHAMELEON-ZK INTEGRATION TEST                     "
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run a test
run_test() {
    local test_name=$1
    local test_command=$2
    
    echo -n "  Testing: $test_name... "
    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "${GREEN}PASSED${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}FAILED${NC}"
        ((TESTS_FAILED++))
    fi
}


echo ""
echo -e "  ${BLUE}SECTION 2: Circuit Files${NC}"

CIRCUITS_DIR=~/chameleon-zk/circuits

run_test "Simple circuit exists" "test -f $CIRCUITS_DIR/build/simple1.circom"
run_test "State commitment circuit exists" "test -f $CIRCUITS_DIR/state_commitment.circom"
run_test "Morph validator circuit exists" "test -f $CIRCUITS_DIR/morph_validator.circom"
run_test "Simple circuit compiled" "test -f $CIRCUITS_DIR/build/simple1.r1cs"
run_test "State commitment compiled" "test -f $CIRCUITS_DIR/build/state_commitment/state_commitment.r1cs"
run_test "Morph validator compiled" "test -f $CIRCUITS_DIR/build/morph_validator/morph_validator.r1cs"

echo ""
echo -e "  ${BLUE}SECTION 3: Trusted Setup Files${NC}"

run_test "Powers of Tau exists" "test -f $CIRCUITS_DIR/build/pot12_final.ptau"
run_test "Simple zkey exists" "test -f $CIRCUITS_DIR/build/simple_final.zkey"
run_test "State commitment zkey exists" "test -f $CIRCUITS_DIR/build/state_commitment/state_commitment_final.zkey"
run_test "Morph validator zkey exists" "test -f $CIRCUITS_DIR/build/morph_validator/morph_validator_final.zkey"

echo ""
echo -e "  ${BLUE}SECTION 4: Rust Prover${NC}"

PROVER_DIR=~/chameleon-zk/prover

run_test "Prover Cargo.toml exists" "test -f $PROVER_DIR/Cargo.toml"
run_test "BN254 backend exists" "test -f $PROVER_DIR/src/bn254_backend.rs"
run_test "BLS12-381 backend exists" "test -f $PROVER_DIR/src/bls12_381_backend.rs"
run_test "Types module exists" "test -f $PROVER_DIR/src/types.rs"
run_test "Morph module exists" "test -f $PROVER_DIR/src/morph.rs"

echo ""
echo -e "  ${YELLOW}Running Rust compilation (this may take a moment)...${NC}"
cd $PROVER_DIR
if cargo build --release > /dev/null 2>&1; then
    echo -e "  Rust compilation: ${GREEN}PASSED${NC}"
    ((TESTS_PASSED++))
else
    echo -e "  Rust compilation: ${RED}FAILED${NC}"
    ((TESTS_FAILED++))
fi

echo ""
echo -e "  ${YELLOW}Running Rust tests...${NC}"
if cargo test --release > /dev/null 2>&1; then
    echo -e "  Rust tests: ${GREEN}PASSED${NC}"
    ((TESTS_PASSED++))
else
    echo -e "  Rust tests: ${RED}FAILED${NC}"
    ((TESTS_FAILED++))
fi

echo ""
echo -e "  ${BLUE}SECTION 5: Solidity Contracts${NC}"

CONTRACTS_DIR=~/chameleon-zk/contracts

run_test "UniversalVerifier.sol exists" "test -f $CONTRACTS_DIR/src/UniversalVerifier.sol"
run_test "MorphController.sol exists" "test -f $CONTRACTS_DIR/src/MorphController.sol"

echo ""
echo -e "  ${YELLOW}Compiling Solidity contracts...${NC}"
cd $CONTRACTS_DIR
if forge build > /dev/null 2>&1; then
    echo -e "  Solidity compilation: ${GREEN}PASSED${NC}"
    ((TESTS_PASSED++))
else
    echo -e "  Solidity compilation: ${RED}FAILED${NC}"
    ((TESTS_FAILED++))
fi

echo ""
echo -e "  ${BLUE}SECTION 6: Proof Generation & Verification${NC}"

# Simple circuit proof
SIMPLE_DIR=$CIRCUITS_DIR/build
run_test "Simple proof exists" "test -f $SIMPLE_DIR/proof.json"
run_test "Simple public.json exists" "test -f $SIMPLE_DIR/public.json"

echo ""
echo -e "  ${YELLOW}Verifying simple circuit proof...${NC}"
cd $SIMPLE_DIR
if snarkjs groth16 verify verification_key.json public.json proof.json > /dev/null 2>&1; then
    echo -e "  Simple proof verification: ${GREEN}PASSED${NC}"
    ((TESTS_PASSED++))
else
    echo -e "  Simple proof verification: ${RED}FAILED${NC}"
    ((TESTS_FAILED++))
fi

# State commitment proof
STATE_DIR=$CIRCUITS_DIR/build/state_commitment
run_test "State commitment proof exists" "test -f $STATE_DIR/proof.json"

echo ""
echo -e "  ${YELLOW}Verifying state commitment proof...${NC}"
cd $STATE_DIR
if snarkjs groth16 verify verification_key.json public.json proof.json > /dev/null 2>&1; then
    echo -e "  State commitment verification: ${GREEN}PASSED${NC}"
    ((TESTS_PASSED++))
else
    echo -e "  State commitment verification: ${RED}FAILED${NC}"
    ((TESTS_FAILED++))
fi

# Morph validator proof
MORPH_DIR=$CIRCUITS_DIR/build/morph_validator
run_test "Morph validator proof exists" "test -f $MORPH_DIR/proof.json"

echo ""
echo -e "  ${YELLOW}Verifying morph validator proof...${NC}"
cd $MORPH_DIR
if snarkjs groth16 verify verification_key.json public.json proof.json > /dev/null 2>&1; then
    echo -e "  Morph validator verification: ${GREEN}PASSED${NC}"
    ((TESTS_PASSED++))
else
    echo -e "  Morph validator verification: ${RED}FAILED${NC}"
    ((TESTS_FAILED++))
fi

echo ""
echo -e "  ${BLUE}SECTION 7: Documentation${NC}"





echo ""
echo -e "  ${BLUE}TEST SUMMARY${NC}"
echo ""
echo -e "  Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "  Tests Failed: ${RED}$TESTS_FAILED${NC}"
TOTAL=$((TESTS_PASSED + TESTS_FAILED))
echo "  Total Tests:  $TOTAL"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "  ${GREEN}   ALL TESTS PASSED! Ready for deployment.  ${NC}"
else
    echo -e "  ${RED}   SOME TESTS FAILED! Please fix issues.     ${NC}"
fi
echo ""
