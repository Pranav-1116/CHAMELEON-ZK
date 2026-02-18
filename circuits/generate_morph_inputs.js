const { buildPoseidon } = require("circomlibjs");

async function main() {
    const poseidon = await buildPoseidon();
    
    // Test values
    const balance = BigInt(1000);
    const nonce = BigInt(5);
    const account_id = BigInt(12345);
    
    // Compute commitment with backend 0 (BN254)
    const old_backend_id = BigInt(0);
    const old_commitment = poseidon.F.toString(
        poseidon([balance, nonce, account_id, old_backend_id])
    );
    
    // Compute commitment with backend 1 (BLS12-381)
    const new_backend_id = BigInt(1);
    const new_commitment = poseidon.F.toString(
        poseidon([balance, nonce, account_id, new_backend_id])
    );
    
    const input = {
        balance: balance.toString(),
        nonce: nonce.toString(),
        account_id: account_id.toString(),
        old_backend_id: old_backend_id.toString(),
        new_backend_id: new_backend_id.toString(),
        old_commitment: old_commitment,
        new_commitment: new_commitment
    };
    
    console.log(JSON.stringify(input, null, 4));
}

main().catch(console.error);
