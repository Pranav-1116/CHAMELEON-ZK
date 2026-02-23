//! Custom error types for Chameleon-ZK
//! 
//! Provides detailed, typed errors for better debugging and handling.

use thiserror::Error;

/// Main error type for Chameleon-ZK operations
#[derive(Error, Debug)]
pub enum ChameleonError {
    // Setup errors
    #[error("Setup not performed for backend {backend}")]
    SetupNotPerformed { backend: String },
    
    #[error("Setup failed: {reason}")]
    SetupFailed { reason: String },
    
    #[error("Invalid setup parameters: {details}")]
    InvalidSetupParams { details: String },
    
    // Proving errors
    #[error("Proof generation failed: {reason}")]
    ProvingFailed { reason: String },
    
    #[error("Invalid witness: {field} - {reason}")]
    InvalidWitness { field: String, reason: String },
    
    #[error("Circuit constraint violation: {constraint}")]
    ConstraintViolation { constraint: String },
    
    // Verification errors
    #[error("Proof verification failed: {reason}")]
    VerificationFailed { reason: String },
    
    #[error("Invalid proof format: {details}")]
    InvalidProofFormat { details: String },
    
    #[error("Public input mismatch: expected {expected}, got {got}")]
    PublicInputMismatch { expected: String, got: String },
    
    // Morphing errors
    #[error("Morph failed: {reason}")]
    MorphFailed { reason: String },
    
    #[error("Invalid backend transition: {from} -> {to}")]
    InvalidBackendTransition { from: String, to: String },
    
    #[error("State commitment mismatch during morph")]
    StateCommitmentMismatch,
    
    // Serialization errors
    #[error("Serialization failed: {reason}")]
    SerializationFailed { reason: String },
    
    #[error("Deserialization failed: {reason}")]
    DeserializationFailed { reason: String },
    
    // IO errors
    #[error("File operation failed: {path} - {reason}")]
    FileError { path: String, reason: String },
    
    // Configuration errors
    #[error("Invalid configuration: {field} - {reason}")]
    ConfigError { field: String, reason: String },
}

/// Result type alias for Chameleon operations
pub type ChameleonResult<T> = Result<T, ChameleonError>;

/// Proof verification result with details
#[derive(Debug, Clone)]
pub struct VerificationResult {
    pub valid: bool,
    pub backend: String,
    pub verification_time_ms: u128,
    pub public_inputs_verified: Vec<String>,
    pub error_message: Option<String>,
}

impl VerificationResult {
    pub fn success(backend: &str, time_ms: u128, inputs: Vec<String>) -> Self {
        Self {
            valid: true,
            backend: backend.to_string(),
            verification_time_ms: time_ms,
            public_inputs_verified: inputs,
            error_message: None,
        }
    }
    
    pub fn failure(backend: &str, time_ms: u128, error: &str) -> Self {
        Self {
            valid: false,
            backend: backend.to_string(),
            verification_time_ms: time_ms,
            public_inputs_verified: vec![],
            error_message: Some(error.to_string()),
        }
    }
}