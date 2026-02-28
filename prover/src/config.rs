// Configuration management for Chameleon-ZK

use serde::{Deserialize, Serialize};
use std::fs;
use std::path::Path;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    pub default_backend: String,
    pub backends: BackendsConfig,
    pub morph: MorphConfig,
    pub output: OutputConfig,
    pub benchmark: BenchmarkConfig,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BackendsConfig {
    #[serde(rename = "BN254")]
    pub bn254: BackendInfo,
    #[serde(rename = "BLS12_381")]
    pub bls12_381: BackendInfo,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BackendInfo {
    pub enabled: bool,
    pub security_bits: u32,
    pub description: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MorphConfig {
    pub auto_morph_enabled: bool,
    pub threat_threshold: u32,
    pub cooldown_seconds: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OutputConfig {
    pub proof_directory: String,
    pub benchmark_directory: String,
    pub report_directory: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BenchmarkConfig {
    pub iterations: u32,
    pub warmup_iterations: u32,
}

impl Config {
    /// Load config from file
    pub fn load(path: &str) -> Result<Self, String> {
        let content = fs::read_to_string(path)
            .map_err(|e| format!("Failed to read config: {}", e))?;
        
        serde_json::from_str(&content)
            .map_err(|e| format!("Failed to parse config: {}", e))
    }
    
    /// Load from default location
    pub fn load_default() -> Result<Self, String> {
        let paths = vec![
            "config/config.json",
            "../config/config.json",
            "config.json",
        ];
        
        for path in paths {
            if Path::new(path).exists() {
                return Self::load(path);
            }
        }
        
        // Return default config if no file found
        Ok(Self::default())
    }
    
    /// Create output directories
    pub fn ensure_directories(&self) -> Result<(), String> {
        fs::create_dir_all(&self.output.proof_directory)
            .map_err(|e| format!("Failed to create proof dir: {}", e))?;
        fs::create_dir_all(&self.output.benchmark_directory)
            .map_err(|e| format!("Failed to create benchmark dir: {}", e))?;
        fs::create_dir_all(&self.output.report_directory)
            .map_err(|e| format!("Failed to create report dir: {}", e))?;
        Ok(())
    }
}

impl Default for Config {
    fn default() -> Self {
        Self {
            default_backend: "BN254".to_string(),
            backends: BackendsConfig {
                bn254: BackendInfo {
                    enabled: true,
                    security_bits: 100,
                    description: "Ethereum-optimized".to_string(),
                },
                bls12_381: BackendInfo {
                    enabled: true,
                    security_bits: 128,
                    description: "Higher security".to_string(),
                },
            },
            morph: MorphConfig {
                auto_morph_enabled: true,
                threat_threshold: 70,
                cooldown_seconds: 300,
            },
            output: OutputConfig {
                proof_directory: "output/proofs".to_string(),
                benchmark_directory: "output/benchmarks".to_string(),
                report_directory: "output/reports".to_string(),
            },
            benchmark: BenchmarkConfig {
                iterations: 5,
                warmup_iterations: 1,
            },
        }
    }
}