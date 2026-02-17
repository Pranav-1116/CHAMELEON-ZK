// BN254 Backend Implementation
// Uses ark-bn254 for curve operations

use crate::types::{BackendType, UniversalProof};

/// BN254 Backend handler
pub struct BN254Backend {
    pub initialized: bool,
}

impl BN254Backend {
    pub fn new() -> Self {
        Self { initialized: true }
    }
    
    pub fn backend_type(&self) -> BackendType {
        BackendType::BN254
    }
}