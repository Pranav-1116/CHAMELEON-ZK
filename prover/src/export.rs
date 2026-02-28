// Proof export and import for Chameleon-ZK

use crate::types::UniversalProof;
use serde::{Deserialize, Serialize};
use std::fs;
use std::path::Path;

#[derive(Debug, Serialize, Deserialize)]
pub struct ExportedProof {
    pub version: String,
    pub timestamp: String,
    pub proof: UniversalProof,
    pub metadata: ProofMetadata,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ProofMetadata {
    pub circuit: String,
    pub prover_version: String,
    pub generation_time_ms: u128,
}

pub struct ProofExporter;

impl ProofExporter {
    /// Export proof to JSON file
    pub fn export(
        proof: &UniversalProof,
        path: &str,
        generation_time_ms: u128,
    ) -> Result<(), String> {
        // Ensure directory exists
        if let Some(parent) = Path::new(path).parent() {
            fs::create_dir_all(parent)
                .map_err(|e| format!("Failed to create directory: {}", e))?;
        }
        
        let exported = ExportedProof {
            version: "1.0".to_string(),
            timestamp: chrono::Utc::now().to_rfc3339(),
            proof: proof.clone(),
            metadata: ProofMetadata {
                circuit: "multiplier".to_string(),
                prover_version: env!("CARGO_PKG_VERSION").to_string(),
                generation_time_ms,
            },
        };
        
        let json = serde_json::to_string_pretty(&exported)
            .map_err(|e| format!("Failed to serialize: {}", e))?;
        
        fs::write(path, json)
            .map_err(|e| format!("Failed to write file: {}", e))?;
        
        Ok(())
    }
    
    /// Import proof from JSON file
    pub fn import(path: &str) -> Result<ExportedProof, String> {
        let content = fs::read_to_string(path)
            .map_err(|e| format!("Failed to read file: {}", e))?;
        
        serde_json::from_str(&content)
            .map_err(|e| format!("Failed to parse: {}", e))
    }
    
    /// List all proofs in directory
    pub fn list_proofs(directory: &str) -> Result<Vec<String>, String> {
        let path = Path::new(directory);
        
        if !path.exists() {
            return Ok(Vec::new());
        }
        
        let entries = fs::read_dir(path)
            .map_err(|e| format!("Failed to read directory: {}", e))?;
        
        let mut proofs = Vec::new();
        for entry in entries {
            if let Ok(entry) = entry {
                let path = entry.path();
                if path.extension().map_or(false, |e| e == "json") {
                    proofs.push(path.to_string_lossy().to_string());
                }
            }
        }
        
        Ok(proofs)
    }
}