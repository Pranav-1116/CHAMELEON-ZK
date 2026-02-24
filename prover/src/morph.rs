use crate::types::{BackendType, MorphResult, UniversalProof};
use crate::bn254_backend::BN254Backend;
use crate::bls12_381_backend::BLS12_381Backend;
use std::time::Instant;

pub struct MorphController {
    current_backend: BackendType,
    bn254: Option<BN254Backend>,
    bls12_381: Option<BLS12_381Backend>,
}

impl MorphController {
    pub fn new(initial_backend: BackendType) -> Self {
        Self {
            current_backend: initial_backend,
            bn254: None,
            bls12_381: None,
        }
    }
    
    pub fn initialize(&mut self) -> Result<(), String> {
        let mut bn254 = BN254Backend::new();
        bn254.setup()?;
        self.bn254 = Some(bn254);
        
        let mut bls = BLS12_381Backend::new();
        bls.setup()?;
        self.bls12_381 = Some(bls);
        
        Ok(())
    }
    
    pub fn current_backend(&self) -> BackendType {
        self.current_backend
    }
    
    pub fn morph(&mut self, target_backend: BackendType) -> Result<MorphResult, String> {
        let start = Instant::now();
        
        if target_backend == self.current_backend {
            return Err("Cannot morph to same backend".to_string());
        }
        
        let old_backend = self.current_backend;
        self.current_backend = target_backend;
        
        let duration = start.elapsed().as_millis();
        
        Ok(MorphResult {
            success: true,
            old_backend,
            new_backend: target_backend,
            duration_ms: duration,
        })
    }
    
    #[allow(dead_code)]
    pub fn prove(&self, a: u64, b: u64) -> Result<UniversalProof, String> {
        match self.current_backend {
            BackendType::BN254 => {
                let backend = self.bn254.as_ref().ok_or("BN254 not initialized")?;
                backend.prove(a, b)
            }
            BackendType::BLS12_381 => {
                let backend = self.bls12_381.as_ref().ok_or("BLS12-381 not initialized")?;
                backend.prove(a, b)
            }
        }
    }
    
    #[allow(dead_code)]
    pub fn verify(&self, proof: &UniversalProof) -> Result<bool, String> {
        match proof.backend {
            BackendType::BN254 => {
                let backend = self.bn254.as_ref().ok_or("BN254 not initialized")?;
                backend.verify(proof)
            }
            BackendType::BLS12_381 => {
                let backend = self.bls12_381.as_ref().ok_or("BLS12-381 not initialized")?;
                backend.verify(proof)
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_morph() {
        let mut controller = MorphController::new(BackendType::BN254);
        controller.initialize().expect("Init should succeed");
        
        let result = controller.morph(BackendType::BLS12_381).expect("Morph should succeed");
        assert!(result.success);
        assert_eq!(controller.current_backend(), BackendType::BLS12_381);
    }
}