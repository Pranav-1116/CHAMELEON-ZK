// Types shared across all backends

use serde::{Deserialize, Serialize};

/// Identifies which cryptographic backend is active
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum BackendType {
    BN254,
    BLS12_381,
}

impl BackendType {
    pub fn name(&self) -> &'static str {
        match self {
            BackendType::BN254 => "BN254",
            BackendType::BLS12_381 => "BLS12-381",
        }
    }
    
    pub fn security_bits(&self) -> u32 {
        match self {
            BackendType::BN254 => 100,
            BackendType::BLS12_381 => 128,
        }
    }
}

/// State commitment that works across backends
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StateCommitment {
    pub hash: [u8; 32],
    pub backend: BackendType,
    pub timestamp: u64,
}

/// Result of a morphing operation
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct _MorphResult {
    pub success: bool,
    pub old_backend: BackendType,
    pub new_backend: BackendType,
    pub state_preserved: bool,
    pub proof_data: Vec<u8>,
}

/// Generic proof wrapper
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UniversalProof {
    pub backend: BackendType,
    pub proof_bytes: Vec<u8>,
    pub public_inputs: Vec<String>,
}