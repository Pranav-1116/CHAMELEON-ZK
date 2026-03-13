#!/usr/bin/env node
const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });

// Read deployment addresses
const deploymentFile = path.join(__dirname, '../deployment_addresses.txt');
const deploymentContent = fs.readFileSync(deploymentFile, 'utf-8');

function extractAddress(content, name) {
    const regex = new RegExp(`${name}=(.+)`, 'i');
    const match = content.match(regex);
    return match ? match[1].trim() : null;
}

const CONTRACTS = {
    state: extractAddress(deploymentContent, 'STATE_VERIFIER_ADDRESS'),
    morph: extractAddress(deploymentContent, 'MORPH_VERIFIER_ADDRESS'),
    universal: extractAddress(deploymentContent, 'UNIVERSAL_VERIFIER_ADDRESS'),
};

const RPC = process.env.SEPOLIA_RPC_URL;

console.log("---------------------------------------------------");
console.log("CHAMELEON-ZK ON-CHAIN VERIFICATION");
console.log("----------------------------------------------------");
console.log("");
console.log("Network: Sepolia Testnet");
console.log("RPC:", RPC ? RPC.substring(0, 50) + "..." : "NOT SET");
console.log("");
console.log("Contracts:");
console.log("  State Verifier:", CONTRACTS.state);
console.log("  Morph Verifier:", CONTRACTS.morph);
console.log("  Universal Verifier:", CONTRACTS.universal);
console.log("");

function verifyProof(name, contractAddr, proofPath, publicPath) {
    console.log(`  Verifying: ${name}`);
    console.log(`  Contract: ${contractAddr}`);
    console.log(`  Proof: ${path.basename(proofPath)}`);
    
    try {
        // Check if files exist
        if (!fs.existsSync(proofPath)) {
            console.log(`  Proof file not found: ${proofPath}`);
            return false;
        }
        if (!fs.existsSync(publicPath)) {
            console.log(`  Public file not found: ${publicPath}`);
            return false;
        }
        
        const proof = JSON.parse(fs.readFileSync(proofPath));
        const publicSignals = JSON.parse(fs.readFileSync(publicPath));
        
        console.log(`  Public signals: [${publicSignals.join(', ')}]`);
        
        // Generate calldata using snarkjs
        const calldataCmd = `cd ${path.dirname(publicPath)} && snarkjs zkey export soliditycalldata ${path.basename(publicPath)} ${path.basename(proofPath)}`;
        const calldata = execSync(calldataCmd, { encoding: 'utf-8' }).trim();
        
        console.log("  Calling contract...");
        
        // Call contract
        const sig = `verifyProof(uint256[2],uint256[2][2],uint256[2],uint256[])`;
        const cmd = `cast call ${contractAddr} "${sig}" ${calldata} --rpc-url ${RPC}`;
        
        const result = execSync(cmd, { encoding: 'utf-8' });
        
        if (result.includes("0000000000000000000000000000000000000000000000000000000000000001")) {
            console.log("  PROOF VERIFIED ON-CHAIN!");
            return true;
        } else {
            console.log("  Proof verification returned FALSE");
            return false;
        }
    } catch (e) {
        console.error("  Error:", e.message);
        return false;
    }
}

let passed = 0;
let failed = 0;

// Verify State Commitment
if (verifyProof(
    "State Commitment",
    CONTRACTS.state,
    path.join(__dirname, '../circuits/build/state_commitment/proof.json'),
    path.join(__dirname, '../circuits/build/state_commitment/public.json')
)) {
    passed++;
} else {
    failed++;
}

console.log("");

// Verify Morph Validator
if (verifyProof(
    "Morph Validator",
    CONTRACTS.morph,
    path.join(__dirname, '../circuits/build/morph_validator/proof.json'),
    path.join(__dirname, '../circuits/build/morph_validator/public.json')
)) {
    passed++;
} else {
    failed++;
}

console.log("");
console.log("  VERIFICATION SUMMARY");
console.log(`  Passed: ${passed}`);
console.log(`  Failed: ${failed}`);
console.log("");

if (failed === 0) {
    console.log("---------------------------------------------------");
    console.log("║  ALL PROOFS VERIFIED SUCCESSFULLY ON SEPOLIA!          ║");
    console.log("---------------------------------------------------");
} else {
    console.log(" Some verifications failed. Check errors above.");
}

process.exit(failed > 0 ? 1 : 0);