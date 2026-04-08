pragma circom 2.1.6;

include "node_modules/circomlib/circuits/poseidon.circom";
include "node_modules/circomlib/circuits/comparators.circom";

/*
 * State Commitment Circuit
 * 
 * Creates a cryptographic commitment to user state.
 * 
 * INPUTS (Private):
 *   - balance: User's token balance (0 to 2^64-1 wei)
 *   - nonce: Transaction counter (0 to 2^32-1)
 *   - account_id: Account identifier
 * 
 * INPUTS (Public):
 *   - backend_id: Current backend (0=BN254, 1=BLS12-381)
 * 
 * OUTPUT (Public):
 *   - commitment: Poseidon hash of all inputs
 * 
 * SECURITY PROPERTIES:
 *   - Balance limited to 2^64 (prevents overflow)
 *   - Nonce limited to 2^32 (realistic max)
 *   - Backend must be 0 or 1 (validates input)
 *   - Commitment binds to backend (prevents replay)
 * 
 * ASSUMPTIONS:
 *   - account_id validated on-chain (non-zero, unique)
 *   - Poseidon hash is collision-resistant
 */

template StateCommitment() {
    // Private inputs
    signal input balance;
    signal input nonce;
    signal input account_id;
    
    // Public inputs
    signal input backend_id;
    
    // Output
    signal output commitment;
    
    // CONSTRAINT 1: Validate backend_id ∈ {0, 1}
    signal backend_check;
    backend_check <== backend_id * (backend_id - 1);
    backend_check === 0;
    
    // CONSTRAINT 2: Validate balance range (0 to 2^64-1)
    component balance_bits = Num2Bits(64);
    balance_bits.in <== balance;
    
    // CONSTRAINT 3: Validate nonce range (0 to 2^32-1)
    component nonce_bits = Num2Bits(32);
    nonce_bits.in <== nonce;
    
    // CONSTRAINT 4: Create commitment
    component hasher = Poseidon(4);
    hasher.inputs[0] <== balance;
    hasher.inputs[1] <== nonce;
    hasher.inputs[2] <== account_id;
    hasher.inputs[3] <== backend_id;
    
    commitment <== hasher.out;
}

component main {public [backend_id]} = StateCommitment();