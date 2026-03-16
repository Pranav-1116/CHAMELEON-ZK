pragma circom 2.1.6;

include "node_modules/circomlib/circuits/poseidon.circom";

/*
 * State Commitment Circuit
 * 
 * This circuit creates a commitment to user state that can be
 * verified regardless of which cryptographic backend is active.
 * 
 * Inputs:
 *   - balance: User's token balance (private)
 *   - nonce: Transaction counter (private)
 *   - account_id: Account identifier (private)
 *   - backend_id: Current backend (0=BN254, 1=BLS12-381) (public)
 * 
 * Outputs:
 *   - commitment: Poseidon hash of all inputs (public)
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
    
    // Backend ID must be 0 or 1
    signal backend_check;
    backend_check <== backend_id * (backend_id - 1);
    backend_check === 0;
    
    // Create commitment using Poseidon hash
    component hasher = Poseidon(4);
    hasher.inputs[0] <== balance;
    hasher.inputs[1] <== nonce;
    hasher.inputs[2] <== account_id;
    hasher.inputs[3] <== backend_id;
    
    commitment <== hasher.out;
}

component main {public [backend_id]} = StateCommitment();
