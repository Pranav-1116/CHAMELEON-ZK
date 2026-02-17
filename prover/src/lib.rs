// Chameleon-ZK Library
// Exports all modules for external use

pub mod types;
pub mod circuit;
pub mod bn254_backend;
pub mod bls12_381_backend;
pub mod morph;

// Re-export commonly used types
pub use types::{BackendType, StateCommitment, _MorphResult, UniversalProof};