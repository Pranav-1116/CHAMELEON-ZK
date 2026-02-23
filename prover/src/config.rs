//! Configuration system for Chameleon-ZK
//!
//! Allows customization of backend behavior, security levels, and features.

use serde::{Deserialize, Serialize};
use std::path::PathBuf;

/// Main configuration structure
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChameleonConfig {
    /// Backend configurations
    pub backends: BackendConfig,
    
    /// Security settings
    pub security: SecurityConfig,
    
    /// Performance settings
    pub performance: PerformanceConfig,
    
    /// Storage settings
    pub storage: StorageConfig,
    
    /// Logging settings
    pub logging: LoggingConfig,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BackendConfig {
    /// Default backend to use
    pub default_backend: String,
    
    /// Enable BN254 backend
    pub enable_bn254: bool,
    
    /// Enable BLS12-381 backend
    pub enable_bls12_381: bool,
    
    /// Auto-select backend based on security requirements
    pub auto_select: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SecurityConfig {
    /// Minimum security bits required
    pub minimum_security_bits: u32,
    
    /// Enable proof binding (prevents proof reuse)
    pub proof_binding: bool,
    
    /// Enable timestamp in proofs
    pub include_timestamp: bool,
    
    /// Maximum proof age in seconds (0 = no limit)
    pub max_proof_age_seconds: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PerformanceConfig {
    /// Number of threads for parallel proving
    pub num_threads: usize,
    
    /// Enable proof caching
    pub enable_caching: bool,
    
    /// Maximum cache size in MB
    pub cache_size_mb: usize,
    
    /// Batch proving threshold
    pub batch_size: usize,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StorageConfig {
    /// Directory for storing keys
    pub keys_directory: PathBuf,
    
    /// Directory for storing proofs
    pub proofs_directory: PathBuf,
    
    /// Use compressed serialization
    pub compress: bool,
    
    /// Export format (json, bincode, cbor)
    pub export_format: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LoggingConfig {
    /// Log level (trace, debug, info, warn, error)
    pub level: String,
    
    /// Log to file
    pub log_to_file: bool,
    
    /// Log file path
    pub log_file: PathBuf,
    
    /// Include timestamps in logs
    pub timestamps: bool,
}

impl Default for ChameleonConfig {
    fn default() -> Self {
        Self {
            backends: BackendConfig {
                default_backend: "BN254".to_string(),
                enable_bn254: true,
                enable_bls12_381: true,
                auto_select: false,
            },
            security: SecurityConfig {
                minimum_security_bits: 100,
                proof_binding: true,
                include_timestamp: true,
                max_proof_age_seconds: 3600, // 1 hour
            },
            performance: PerformanceConfig {
                num_threads: num_cpus::get().unwrap_or(4),
                enable_caching: true,
                cache_size_mb: 100,
                batch_size: 10,
            },
            storage: StorageConfig {
                keys_directory: PathBuf::from("./keys"),
                proofs_directory: PathBuf::from("./proofs"),
                compress: true,
                export_format: "json".to_string(),
            },
            logging: LoggingConfig {
                level: "info".to_string(),
                log_to_file: false,
                log_file: PathBuf::from("./chameleon.log"),
                timestamps: true,
            },
        }
    }
}

impl ChameleonConfig {
    /// Load configuration from file
    pub fn load(path: &str) -> Result<Self, String> {
        let content = std::fs::read_to_string(path)
            .map_err(|e| format!("Failed to read config file: {}", e))?;
        
        serde_json::from_str(&content)
            .map_err(|e| format!("Failed to parse config: {}", e))
    }
    
    /// Save configuration to file
    pub fn save(&self, path: &str) -> Result<(), String> {
        let content = serde_json::to_string_pretty(self)
            .map_err(|e| format!("Failed to serialize config: {}", e))?;
        
        std::fs::write(path, content)
            .map_err(|e| format!("Failed to write config file: {}", e))
    }
    
    /// Create directories if they don't exist
    pub fn ensure_directories(&self) -> Result<(), String> {
        std::fs::create_dir_all(&self.storage.keys_directory)
            .map_err(|e| format!("Failed to create keys directory: {}", e))?;
        
        std::fs::create_dir_all(&self.storage.proofs_directory)
            .map_err(|e| format!("Failed to create proofs directory: {}", e))?;
        
        Ok(())
    }
    
    /// Validate configuration
    pub fn validate(&self) -> Result<(), String> {
        if self.security.minimum_security_bits < 80 {
            return Err("Security bits too low (minimum 80)".to_string());
        }
        
        if !self.backends.enable_bn254 && !self.backends.enable_bls12_381 {
            return Err("At least one backend must be enabled".to_string());
        }
        
        Ok(())
    }
}

// Helper function to get number of CPUs
mod num_cpus {
    pub fn get() -> Option<usize> {
        std::thread::available_parallelism()
            .map(|n| n.get())
            .ok()
    }
}