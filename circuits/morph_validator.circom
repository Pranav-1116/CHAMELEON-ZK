pragma circom 2.1.6;

include "node_modules/circomlib/circuits/poseidon.circom";
include "node_modules/circomlib/circuits/comparators.circom";

/*
 * Morph Validator Circuit
 * 
 * Proves that a backend morph preserves state integrity.
 * 
 * INPUTS (Private):
 *   - balance: User's balance (must match old commitment)
 *   - nonce: Transaction nonce (must match old commitment)
 *   - account_id: Account identifier
 * 
 * INPUTS (Public):
 *   - old_backend_id: Previous backend (0 or 1)
 *   - new_backend_id: New backend (0 or 1, must differ)
 *   - old_commitment: Commitment before morph
 *   - new_commitment: Commitment after morph
 * 
 * PROOF STATEMENT:
 *   "I know (balance, nonce, account_id) such that:
 *     1. Hash(balance, nonce, account_id, old_backend_id) = old_commitment
 *     2. Hash(balance, nonce, account_id, new_backend_id) = new_commitment
 *     3. old_backend_id ≠ new_backend_id"
 * 
 * This proves the morph preserves state without revealing actual values.
 * 
 * SECURITY PROPERTIES:
 *   - Cannot fake a morph (must know preimage)
 *   - Cannot morph to same backend (explicit check)
 *   - Cannot overflow balance/nonce (range checks)
 *   - Cannot reuse old proofs (commitments differ)
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
    
    // CONSTRAINT 1: Validate old_backend_id ∈ {0, 1}
    signal old_backend_check;
    old_backend_check <== old_backend_id * (old_backend_id - 1);
    old_backend_check === 0;
    
    // CONSTRAINT 2: Validate new_backend_id ∈ {0, 1}
    signal new_backend_check;
    new_backend_check <== new_backend_id * (new_backend_id - 1);
    new_backend_check === 0;
    
    // CONSTRAINT 3: Ensure backends are different (prevents fake morphs)
    component backends_equal = IsEqual();
    backends_equal.in[0] <== old_backend_id;
    backends_equal.in[1] <== new_backend_id;
    backends_equal.out === 0;  // Must NOT be equal
    
    // CONSTRAINT 4: Validate balance range (same as StateCommitment)
    component balance_bits = Num2Bits(64);
    balance_bits.in <== balance;
    
    // CONSTRAINT 5: Validate nonce range (same as StateCommitment)
    component nonce_bits = Num2Bits(32);
    nonce_bits.in <== nonce;
    
    // CONSTRAINT 6: Verify old commitment
    component old_hasher = Poseidon(4);
    old_hasher.inputs[0] <== balance;
    old_hasher.inputs[1] <== nonce;
    old_hasher.inputs[2] <== account_id;
    old_hasher.inputs[3] <== old_backend_id;
    old_hasher.out === old_commitment;
    
    // CONSTRAINT 7: Verify new commitment
    component new_hasher = Poseidon(4);
    new_hasher.inputs[0] <== balance;
    new_hasher.inputs[1] <== nonce;
    new_hasher.inputs[2] <== account_id;
    new_hasher.inputs[3] <== new_backend_id;
    new_hasher.out === new_commitment;
}

component main {public [old_backend_id, new_backend_id, old_commitment, new_commitment]} = MorphValidator();