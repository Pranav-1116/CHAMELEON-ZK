// morph.rs
#[allow(dead_code)]

use crate::types::{BackendType, MorphResult,UniversalProof};
use crate::bn254_backend::BN254Backend;
use crate::bls12_381_backend::BLS12_381Backend;
use std::time::Instant;

// ... rest of the code

pub struct MorphController {
    current_backend: BackendType,
    bn254: Option<BN254Backend>,
    bls12_381: Option<BLS12_381Backend>,
}
#[allow(dead_code)]
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

// At the bottom of morph.rs

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_morph_controller_new() {
        let controller = MorphController::new(BackendType::BN254);
        assert_eq!(controller.current_backend(), BackendType::BN254);
    }

    #[test]
    fn test_morph_controller_initialize() {
        let mut controller = MorphController::new(BackendType::BN254);
        let result = controller.initialize();
        assert!(result.is_ok());
    }

    #[test]
    fn test_morph_bn254_to_bls12_381() {
        let mut controller = MorphController::new(BackendType::BN254);
        controller.initialize().expect("Init should succeed");
        
        let result = controller.morph(BackendType::BLS12_381);
        assert!(result.is_ok());
        
        let morph_result = result.unwrap();
        assert!(morph_result.success);
        assert_eq!(morph_result.old_backend, BackendType::BN254);
        assert_eq!(morph_result.new_backend, BackendType::BLS12_381);
    }

    #[test]
    fn test_morph_to_same_backend_fails() {
        let mut controller = MorphController::new(BackendType::BN254);
        controller.initialize().expect("Init should succeed");
        
        let result = controller.morph(BackendType::BN254);
        assert!(result.is_err());
        assert_eq!(result.unwrap_err(), "Cannot morph to same backend");
    }

    #[test]
    fn test_round_trip_morph() {
        let mut controller = MorphController::new(BackendType::BN254);
        controller.initialize().expect("Init should succeed");
        
        // BN254 -> BLS12-381
        controller.morph(BackendType::BLS12_381).expect("First morph should succeed");
        assert_eq!(controller.current_backend(), BackendType::BLS12_381);
        
        // BLS12-381 -> BN254
        controller.morph(BackendType::BN254).expect("Second morph should succeed");
        assert_eq!(controller.current_backend(), BackendType::BN254);
    }
}