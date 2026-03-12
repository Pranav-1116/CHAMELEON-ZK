const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

// Contract addresses (update after deployment)
const CONTRACTS = {
    simple: "0x5FbDB2315678afecb367f032d93F642f64180aa3",
    state: "YOUR_STATE_VERIFIER_ADDRESS",
    morph: "YOUR_MORPH_VERIFIER_ADDRESS"
};

const RPC = "http://127.0.0.1:8545";

function verifyProof(name, contractAddr, proofPath, publicPath, pubCount) {
    console.log(`\n=== Verifying ${name} ===`);
    
    try {
        const proof = JSON.parse(fs.readFileSync(proofPath));
        const publicSignals = JSON.parse(fs.readFileSync(publicPath));
        
        console.log("Public signals:", publicSignals);
        
        // Format proof
        const a = `[${proof.pi_a[0]},${proof.pi_a[1]}]`;
        const b = `[[${proof.pi_b[0][1]},${proof.pi_b[0][0]}],[${proof.pi_b[1][1]},${proof.pi_b[1][0]}]]`;
        const c = `[${proof.pi_c[0]},${proof.pi_c[1]}]`;
        const pub = `[${publicSignals.join(',')}]`;
        
        const sig = `verifyProof(uint256[2],uint256[2][2],uint256[2],uint256[${pubCount}])`;
        const cmd = `cast call ${contractAddr} "${sig}" "${a}" "${b}" "${c}" "${pub}" --rpc-url ${RPC}`;
        
        const result = execSync(cmd, { encoding: 'utf-8' });
        
        if (result.includes("0000000000000000000000000000000000000000000000000000000000000001")) {
            console.log("✓ PROOF VERIFIED!");
            return true;
        } else {
            console.log("✗ Proof invalid");
            return false;
        }
    } catch (e) {
        console.error("Error:", e.message);
        return false;
    }
}

// Verify Simple (3 * 7 = 21)
verifyProof(
    "Simple Multiplier",
    CONTRACTS.simple,
    path.join(__dirname, '../circuits/build/proof.json'),
    path.join(__dirname, '../circuits/build/public.json'),
    1
);

// Verify State Commitment
verifyProof(
    "State Commitment",
    CONTRACTS.state,
    path.join(__dirname, '../circuits/build/state_commitment/proof.json'),
    path.join(__dirname, '../circuits/build/state_commitment/public.json'),
    2  // backend_id and commitment
);

// Verify Morph Validator
verifyProof(
    "Morph Validator",
    CONTRACTS.morph,
    path.join(__dirname, '../circuits/build/morph_validator/proof.json'),
    path.join(__dirname, '../circuits/build/morph_validator/public.json'),
    4  // old_backend, new_backend, old_commitment, new_commitment
);

console.log("\n=== All verifications complete ===");