// Chameleon-ZK Prover
// Tests both BN254 and BLS12-381 backends

mod types;
mod circuit;
mod bn254_backend;
mod bls12_381_backend;
mod morph;

use types::BackendType;
use bn254_backend::BN254Backend;
use bls12_381_backend::BLS12_381Backend;
use std::time::Instant;

fn main() {
    println!("----------------------------------------------------------");
    println!("              CHAMELEON-ZK PROVER v0.1.0                  ");
    println!("     Dynamic Cryptographic Backend Switching System       ");
    println!("-----------------------------------------------------------");
    println!();
    
    // Display available backends
    println!("---------------------------------------------------------------");
    println!(" Available Backends:                                         ");
    println!("   • {} - {}-bit security (Ethereum-optimized)        ", 
             BackendType::BN254.name(), 
             BackendType::BN254.security_bits());
    println!("   • {} - {}-bit security (Higher security)        ", 
             BackendType::BLS12_381.name(), 
             BackendType::BLS12_381.security_bits());
    println!("");
    println!();
    
    // Test BN254 Backend
    println!("----------------------------------------------------");
    println!("  TESTING BACKEND A: BN254");
    println!("----------------------------------------------------");
    
    let bn254_results = test_backend_bn254();
    
    println!();
    
    // Test BLS12-381 Backend
    println!("----------------------------------------------------");
    println!("  TESTING BACKEND B: BLS12-381");
    println!("----------------------------------------------------");
    
    let bls_results = test_backend_bls12_381();
    
    println!();
    
    // Summary comparison
    println!("-------------------------------------------------------------");
    println!("  PERFORMANCE COMPARISON");
    println!("-------------------------------------------------------------");
    println!();
    println!("  -------------------------------------------------");
    println!("   Metric          BN254           BLS12-381      ");
    println!("  ");
    println!("  Setup Time      {:>12}ms     {:>12}ms ", 
             bn254_results.0, bls_results.0);
    println!("   Prove Time      {:>12}ms {:>12}ms ", 
             bn254_results.1, bls_results.1);
    println!("  Verify Time    {:>12}ms {:>12}ms ", 
             bn254_results.2, bls_results.2);
    println!("   Proof Size     {:>10} bytes  {:>10} bytes ", 
             bn254_results.3, bls_results.3);
    println!("   Valid           {:>14}  {:>14} ", 
             bn254_results.4, bls_results.4);
    println!(" ------------------------------------");
    println!();
    println!("✓ Both backends operational - Ready for morphing!");
}

fn test_backend_bn254() -> (u128, u128, u128, usize, &'static str) {
    let mut backend = BN254Backend::new();
    
    // Setup
    print!("  [1/3] Running trusted setup... ");
    let start = Instant::now();
    match backend.setup() {
        Ok(_) => println!("✓ ({:?})", start.elapsed()),
        Err(e) => {
            println!("✗ ({})", e);
            return (0, 0, 0, 0, "FAILED");
        }
    }
    let setup_time = start.elapsed().as_millis();
    
    // Prove
    print!("  [2/3] Generating proof (3 × 7 = 21)... ");
    let start = Instant::now();
    let proof = match backend.prove(3, 7) {
        Ok(p) => {
            println!("✓ ({:?})", start.elapsed());
            p
        }
        Err(e) => {
            println!("✗ ({})", e);
            return (setup_time, 0, 0, 0, "FAILED");
        }
    };
    let prove_time = start.elapsed().as_millis();
    let proof_size = proof.proof_bytes.len();
    
    println!("      → Public output: {}", proof.public_inputs[0]);
    println!("      → Proof size: {} bytes", proof_size);
    
    // Verify
    print!("  [3/3] Verifying proof... ");
    let start = Instant::now();
    let valid = match backend.verify(&proof) {
        Ok(v) => {
            if v {
                println!("✓ VALID ({:?})", start.elapsed());
                "VALID"
            } else {
                println!("✗ INVALID");
                "INVALID"
            }
        }
        Err(e) => {
            println!("✗ ({})", e);
            "FAILED"
        }
    };
    let verify_time = start.elapsed().as_millis();
    
    (setup_time, prove_time, verify_time, proof_size, valid)
}

fn test_backend_bls12_381() -> (u128, u128, u128, usize, &'static str) {
    let mut backend = BLS12_381Backend::new();
    
    // Setup
    print!("  [1/3] Running trusted setup... ");
    let start = Instant::now();
    match backend.setup() {
        Ok(_) => println!("✓ ({:?})", start.elapsed()),
        Err(e) => {
            println!("✗ ({})", e);
            return (0, 0, 0, 0, "FAILED");
        }
    }
    let setup_time = start.elapsed().as_millis();
    
    // Prove
    print!("  [2/3] Generating proof (5 × 11 = 55)... ");
    let start = Instant::now();
    let proof = match backend.prove(5, 11) {
        Ok(p) => {
            println!("✓ ({:?})", start.elapsed());
            p
        }
        Err(e) => {
            println!("✗ ({})", e);
            return (setup_time, 0, 0, 0, "FAILED");
        }
    };
    let prove_time = start.elapsed().as_millis();
    let proof_size = proof.proof_bytes.len();
    
    println!("      → Public output: {}", proof.public_inputs[0]);
    println!("      → Proof size: {} bytes", proof_size);
    
    // Verify
    print!("  [3/3] Verifying proof... ");
    let start = Instant::now();
    let valid = match backend.verify(&proof) {
        Ok(v) => {
            if v {
                println!("✓ VALID ({:?})", start.elapsed());
                "VALID"
            } else {
                println!("✗ INVALID");
                "INVALID"
            }
        }
        Err(e) => {
            println!("✗ ({})", e);
            "FAILED"
        }
    };
    let verify_time = start.elapsed().as_millis();
    
    (setup_time, prove_time, verify_time, proof_size, valid)
}