// Benchmarking suite for Chameleon-ZK

use crate::bn254_backend::BN254Backend;
use crate::bls12_381_backend::BLS12_381Backend;
use crate::types::BackendType;
use serde::{Deserialize, Serialize};
use std::time::{Duration, Instant};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BenchmarkResult {
    pub backend: String,
    pub setup_time_ms: u128,
    pub prove_time_ms: u128,
    pub verify_time_ms: u128,
    pub proof_size_bytes: usize,
    pub iterations: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BenchmarkReport {
    pub timestamp: String,
    pub results: Vec<BenchmarkResult>,
    pub comparison: ComparisonSummary,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ComparisonSummary {
    pub fastest_prove: String,
    pub fastest_verify: String,
    pub smallest_proof: String,
    pub highest_security: String,
}

pub struct Benchmarker {
    pub iterations: u32,
    pub warmup: u32,
}

impl Benchmarker {
    pub fn new(iterations: u32, warmup: u32) -> Self {
        Self { iterations, warmup }
    }
    
    /// Run benchmarks for a single backend
    fn benchmark_backend<F, G, H>(
        &self,
        name: &str,
        setup_fn: F,
        prove_fn: G,
        verify_fn: H,
    ) -> BenchmarkResult
    where
        F: Fn() -> Result<(), String>,
        G: Fn() -> Result<(Vec<u8>, usize), String>,
        H: Fn(&[u8]) -> Result<bool, String>,
    {
        // Warmup
        for _ in 0..self.warmup {
            let _ = setup_fn();
            let _ = prove_fn();
        }
        
        // Measure setup
        let start = Instant::now();
        for _ in 0..self.iterations {
            let _ = setup_fn();
        }
        let setup_time = start.elapsed().as_millis() / self.iterations as u128;
        
        // Setup once for prove/verify
        let _ = setup_fn();
        
        // Measure prove
        let mut proof_data = Vec::new();
        let mut proof_size = 0;
        let start = Instant::now();
        for _ in 0..self.iterations {
            if let Ok((data, size)) = prove_fn() {
                proof_data = data;
                proof_size = size;
            }
        }
        let prove_time = start.elapsed().as_millis() / self.iterations as u128;
        
        // Measure verify
        let start = Instant::now();
        for _ in 0..self.iterations {
            let _ = verify_fn(&proof_data);
        }
        let verify_time = start.elapsed().as_millis() / self.iterations as u128;
        
        BenchmarkResult {
            backend: name.to_string(),
            setup_time_ms: setup_time,
            prove_time_ms: prove_time,
            verify_time_ms: verify_time,
            proof_size_bytes: proof_size,
            iterations: self.iterations,
        }
    }
    
    /// Run all benchmarks
    pub fn run_all(&self) -> BenchmarkReport {
        println!("Running benchmarks ({} iterations each)...\n", self.iterations);
        
        let mut results = Vec::new();
        
        // BN254 Benchmark
        println!("Benchmarking BN254...");
        let mut bn254 = BN254Backend::new();
        let bn254_result = self.benchmark_backend(
            "BN254",
            || bn254.setup(),
            || {
                let proof = bn254.prove(3, 7)?;
                Ok((proof.proof_bytes.clone(), proof.proof_bytes.len()))
            },
            |data| {
                let proof = crate::types::UniversalProof {
                    backend: BackendType::BN254,
                    proof_bytes: data.to_vec(),
                    public_inputs: vec!["21".to_string()],
                };
                bn254.verify(&proof)
            },
        );
        results.push(bn254_result);
        
        // BLS12-381 Benchmark
        println!("Benchmarking BLS12-381...");
        let mut bls = BLS12_381Backend::new();
        let bls_result = self.benchmark_backend(
            "BLS12-381",
            || bls.setup(),
            || {
                let proof = bls.prove(3, 7)?;
                Ok((proof.proof_bytes.clone(), proof.proof_bytes.len()))
            },
            |data| {
                let proof = crate::types::UniversalProof {
                    backend: BackendType::BLS12_381,
                    proof_bytes: data.to_vec(),
                    public_inputs: vec!["21".to_string()],
                };
                bls.verify(&proof)
            },
        );
        results.push(bls_result);
        
        // Generate comparison
        let comparison = self.generate_comparison(&results);
        
        BenchmarkReport {
            timestamp: chrono::Utc::now().to_rfc3339(),
            results,
            comparison,
        }
    }
    
    fn generate_comparison(&self, results: &[BenchmarkResult]) -> ComparisonSummary {
        let fastest_prove = results
            .iter()
            .min_by_key(|r| r.prove_time_ms)
            .map(|r| r.backend.clone())
            .unwrap_or_default();
        
        let fastest_verify = results
            .iter()
            .min_by_key(|r| r.verify_time_ms)
            .map(|r| r.backend.clone())
            .unwrap_or_default();
        
        let smallest_proof = results
            .iter()
            .min_by_key(|r| r.proof_size_bytes)
            .map(|r| r.backend.clone())
            .unwrap_or_default();
        
        ComparisonSummary {
            fastest_prove,
            fastest_verify,
            smallest_proof,
            highest_security: "BLS12-381".to_string(),
        }
    }
    
    /// Print results as table
    pub fn print_results(&self, report: &BenchmarkReport) {
        println!("BENCHMARK RESULTS");
        println!("Backend     │ Setup (ms) │ Prove (ms) │ Verify (ms) │ Proof Size ");
        
        for r in &report.results {
            println!(
                "║ {:11} │ {:10} │ {:10} │ {:11} │ {:10} ║",
                r.backend,
                r.setup_time_ms,
                r.prove_time_ms,
                r.verify_time_ms,
                format!("{} B", r.proof_size_bytes)
            );
        }
        
        println!("SUMMARY ");
        println!("Fastest Prove:  {:47} ", report.comparison.fastest_prove);
        println!("Fastest Verify: {:47} ", report.comparison.fastest_verify);
        println!("Smallest Proof: {:47} ", report.comparison.smallest_proof);
        println!("Highest Security: {:45} ", report.comparison.highest_security);
    }
}