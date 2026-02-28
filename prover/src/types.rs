use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum BackendType {
    BN254,
    BLS12_381,
}
#[allow(dead_code)]
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

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UniversalProof {
    pub backend: BackendType,
    pub proof_bytes: Vec<u8>,
    pub public_inputs: Vec<String>,
}

#[allow(dead_code)]
#[derive(Debug, Clone)]
pub struct MorphResult {
    pub success: bool,
    pub old_backend: BackendType,
    pub new_backend: BackendType,
    pub duration_ms: u128,
}