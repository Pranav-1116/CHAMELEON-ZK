// Chameleon-ZK Prover
// Main entry point

mod types;
mod circuit;
mod bn254_backend;
mod bls12_381_backend;
mod morph;

use types::BackendType;

fn main() {
    println!("=== Chameleon-ZK Prover ===");
    println!();
    
    // Display available backends
    println!("Available Backends:");
    println!("  1. {} ({}-bit security)", 
             BackendType::BN254.name(), 
             BackendType::BN254.security_bits());
    println!("  2. {} ({}-bit security)", 
             BackendType::BLS12_381.name(), 
             BackendType::BLS12_381.security_bits());
    println!();
    
    println!("Prover initialized successfully.");
}