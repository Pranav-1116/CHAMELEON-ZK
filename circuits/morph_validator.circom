pragma circom 2.1.6;

include "node_modules/circomlib/circuits/poseidon.circom";
include "node_modules/circomlib/circuits/comparators.circom";

/*
 * Morph Validator Circuit
 * 
 * Validates that a backend morph preserves state integrity.
 * Proves that the same underlying data produces consistent
 * commitments even when the backend changes.
 * 
 * Inputs (Private):
 *   - balance: User's balance
 *   - nonce: Transaction nonce
 *   - account_id: Account identifier
 * 
 * Inputs (Public):
 *   - old_backend_id: Previous backend (0 or 1)
 *   - new_backend_id: New backend (0 or 1)
 *   - old_commitment: Expected commitment with old backend
 *   - new_commitment: Expected commitment with new backend
 * 
 * The circuit verifies:
 *   1. old_commitment = Hash(balance, nonce, account_id, old_backend_id)
 *   2. new_commitment = Hash(balance, nonce, account_id, new_backend_id)
 *   3. old_backend_id != new_backend_id (actually changing backends)
 */

template MorphValidator() {
    // Private inputs (the actual state data)
    signal input balance;
    signal input nonce;
    signal input account_id;
    
    // Public inputs
    signal input old_backend_id;
    signal input new_backend_id;
    signal input old_commitment;
    signal input new_commitment;
    
    // Verify old_backend_id is valid (0 or 1)
    signal old_backend_check;
    old_backend_check <== old_backend_id * (old_backend_id - 1);
    old_backend_check === 0;
    
    // Verify new_backend_id is valid (0 or 1)
    signal new_backend_check;
    new_backend_check <== new_backend_id * (new_backend_id - 1);
    new_backend_check === 0;
    
    // Verify backends are different
    component not_equal = IsEqual();
    not_equal.in[0] <== old_backend_id;
    not_equal.in[1] <== new_backend_id;
    not_equal.out === 0;  // Must NOT be equal
    
    // Compute old commitment
    component old_hasher = Poseidon(4);
    old_hasher.inputs[0] <== balance;
    old_hasher.inputs[1] <== nonce;
    old_hasher.inputs[2] <== account_id;
    old_hasher.inputs[3] <== old_backend_id;
    
    // Verify old commitment matches
    old_hasher.out === old_commitment;
    
    // Compute new commitment
    component new_hasher = Poseidon(4);
    new_hasher.inputs[0] <== balance;
    new_hasher.inputs[1] <== nonce;
    new_hasher.inputs[2] <== account_id;
    new_hasher.inputs[3] <== new_backend_id;
    
    // Verify new commitment matches
    new_hasher.out === new_commitment;
}

component main {public [old_backend_id, new_backend_id, old_commitment, new_commitment]} = MorphValidator();
