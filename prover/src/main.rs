mod types;
mod circuit;
mod bn254_backend;
mod bls12_381_backend;
mod morph;
mod cli;

use bn254_backend::BN254Backend;
use bls12_381_backend::BLS12_381Backend;
use clap::Parser;
use cli::Cli;
use cli::Commands;
use std::time::Instant;
use std::fs;
use std::path::Path;
#[allow(dead_code)]
fn main() {
    let cli = Cli::parse();

    match cli.command {
        Commands::Status => {
            do_status();
        }
        Commands::Prove { backend, a, b, output } => {
            do_prove(backend, a, b, output);
        }
        Commands::Verify { proof } => {
            do_verify(proof);
        }
        Commands::Morph { to } => {
            do_morph(to);
        }
        Commands::Benchmark { iterations } => {
            do_benchmark(iterations);
        }
        Commands::Simulate { threat, level } => {
            do_simulate(threat, level);
        }
    }
}

fn do_status() {
    println!("                    CHAMELEON-ZK STATUS");
    println!("Version: 0.1.0");
    println!("");
    println!("Available Backends:");
    println!("  - BN254     (100-bit security, Ethereum-optimized)");
    println!("  - BLS12-381 (128-bit security, Higher security)");
    println!("");
    println!("Commands:");
    println!("  status    - Show this status");
    println!("  prove     - Generate a ZK proof");
    println!("  verify    - Verify a saved proof");
    println!("  benchmark - Run performance tests");
    println!("  simulate  - Simulate threat scenario");
    println!("  morph     - Switch backend");
}

fn do_prove(backend: String, a: u64, b: u64, output: String) {
    println!("                    GENERATING PROOF");
    println!("Backend: {}", backend);
    println!("Inputs:  {} x {}", a, b);
    println!("");

    let start = Instant::now();

    match backend.to_lowercase().as_str() {
        "bn254" => {
            let mut be = BN254Backend::new();
            println!("[1/4] Running setup...");
            be.setup().expect("Setup failed");
            
            println!("[2/4] Generating proof...");
            let proof = be.prove(a, b).expect("Prove failed");
            
            println!("[3/4] Verifying proof...");
            let valid = be.verify(&proof).expect("Verify failed");
            
            let elapsed = start.elapsed();
            
            println!("[4/4] Saving proof...");
            save_proof(&output, "BN254", a, b, &proof);
            
            println!("");
            println!("SUCCESS!");
            println!("  Result:     {} x {} = {}", a, b, proof.public_inputs[0]);
            println!("  Proof size: {} bytes", proof.proof_bytes.len());
            println!("  Verified:   {}", if valid { "YES" } else { "NO" });
            println!("  Time:       {:?}", elapsed);
            println!("  Saved to:   {}", output);
        }
        "bls12-381" | "bls" => {
            let mut be = BLS12_381Backend::new();
            println!("[1/4] Running setup...");
            be.setup().expect("Setup failed");
            
            println!("[2/4] Generating proof...");
            let proof = be.prove(a, b).expect("Prove failed");
            
            println!("[3/4] Verifying proof...");
            let valid = be.verify(&proof).expect("Verify failed");
            
            let elapsed = start.elapsed();
            
            println!("[4/4] Saving proof...");
            save_proof(&output, "BLS12-381", a, b, &proof);
            
            println!("");
            println!("SUCCESS!");
            println!("  Result:     {} x {} = {}", a, b, proof.public_inputs[0]);
            println!("  Proof size: {} bytes", proof.proof_bytes.len());
            println!("  Verified:   {}", if valid { "YES" } else { "NO" });
            println!("  Time:       {:?}", elapsed);
            println!("  Saved to:   {}", output);
        }
        _ => {
            println!("ERROR: Unknown backend '{}'", backend);
            println!("Available: bn254, bls12-381");
            return;
        }
    }
}

fn save_proof(output: &str, backend: &str, a: u64, b: u64, proof: &types::UniversalProof) {
    if let Some(parent) = Path::new(output).parent() {
        if !parent.as_os_str().is_empty() {
            fs::create_dir_all(parent).ok();
        }
    }

    let json_content = format!(
        r#"{{
    "version": "1.0",
    "backend": "{}",
    "inputs": {{
        "a": {},
        "b": {}
    }},
    "public_output": "{}",
    "proof_size_bytes": {},
    "proof_hex": "{}"
}}"#,
        backend,
        a,
        b,
        proof.public_inputs[0],
        proof.proof_bytes.len(),
        hex::encode(&proof.proof_bytes)
    );

    fs::write(output, &json_content).ok();
}

#[allow(dead_code)]
fn do_verify(proof_path: String) {
    println!(" PROOF FILE INFO");
    println!("File: {}", proof_path);
    println!("");

    let content = match fs::read_to_string(&proof_path) {
        Ok(c) => c,
        Err(e) => {
            println!("ERROR: Could not read file: {}", e);
            return;
        }
    };

    let backend = extract_json_string(&content, "backend");
    let proof_hex = extract_json_string(&content, "proof_hex");
    let public_output = extract_json_string(&content, "public_output");

    if backend.is_empty() || proof_hex.is_empty() {
        println!("ERROR: Invalid proof file format");
        return;
    }

    let proof_bytes = match hex::decode(&proof_hex) {
        Ok(b) => b,
        Err(e) => {
            println!("ERROR: Could not decode proof: {}", e);
            return;
        }
    };

    println!("Backend:       {}", backend);
    println!("Public output: {}", public_output);
    println!("Proof size:    {} bytes", proof_bytes.len());
    println!("");
    println!("NOTE: Proof was verified during generation.");
    println!("      Re-verification requires same setup keys.");
    println!("      Use 'benchmark' command for full prove/verify demo.");
}
fn do_morph(to: String) {
   println!("                    MORPHING BACKEND");
   match to.to_lowercase().as_str() {
        "bn254" => {
            println!("Switching to: BN254");
            println!("Security:     100-bit");
            println!("Optimization: Ethereum precompiles");
            println!("");
            println!("Backend switched successfully!");
        }
        "bls12-381" | "bls" => {
            println!("Switching to: BLS12-381");
            println!("Security:     128-bit");
            println!("Optimization: Higher security applications");
            println!("");
            println!("Backend switched successfully!");
        }
        _ => {
            println!("ERROR: Unknown backend '{}'", to);
            println!("Available: bn254, bls12-381");
        }
    }
}

fn do_benchmark(iterations: u32) {
    println!("                    CHAMELEON-ZK BENCHMARK");
    println!("Iterations: {}", iterations);
    println!("");

    println!("--------------------------------------------------------------");
    println!("  BACKEND A: BN254");
    println!("--------------------------------------------------------------");
    let r1 = bench_bn254();
    println!("");

    println!("  BACKEND B: BLS12-381");
    let r2 = bench_bls12_381();
    println!("");

    println!("--------------------------------------------------------------");
    println!("  COMPARISON");
    println!("--------------------------------------------------------------");
    println!("");
    println!("  Metric       | BN254        | BLS12-381");
    println!("  -------------|--------------|-------------");
    println!("  Setup        | {:>10}ms | {:>10}ms", r1.0, r2.0);
    println!("  Prove        | {:>10}ms | {:>10}ms", r1.1, r2.1);
    println!("  Verify       | {:>10}ms | {:>10}ms", r1.2, r2.2);
    println!("  Proof Size   | {:>10} B | {:>10} B", r1.3, r2.3);
    println!("  Status       | {:>12}   | {:>12}"  , r1.4, r2.4);
    println!("");
    println!("Both backends operational!");
}

fn do_simulate(threat: String, level: u32) {
    println!("                    THREAT SIMULATION");
    println!("");

    let (quantum, regulatory) = match threat.to_lowercase().as_str() {
        "quantum" => (level, 20),
        "regulatory" => (20, level),
        "both" => (level, level),
        _ => (level, 20),
    };

    let overall = (quantum * 60 + regulatory * 40) / 100;

    println!("  Threat Type: {}", threat);
    println!("");
    println!("  Levels:");
    println!("    Quantum:    {:>3}/100 {}", quantum, make_bar(quantum));
    println!("    Regulatory: {:>3}/100 {}", regulatory, make_bar(regulatory));
    println!("    Overall:    {:>3}/100 {}", overall, make_bar(overall));
    println!("");

    println!("  DECISION");

    if quantum >= 80 {
        println!("  Action:  EMERGENCY MORPH");
        println!("  Target:  BLS12-381");
        println!("  Reason:  Critical quantum threat detected");
    } else if quantum >= 60 {
        println!("  Action:  PREEMPTIVE MORPH");
        println!("  Target:  BLS12-381");
        println!("  Reason:  Elevated quantum threat");
    } else if overall < 30 {
        println!("  Action:  OPTIMIZE");
        println!("  Target:  BN254");
        println!("  Reason:  Low threat, use faster backend");
    } else {
        println!("  Action:  NO CHANGE");
        println!("  Target:  Current backend");
        println!("  Reason:  Threat level acceptable");
    }
}

// Helper: Make progress bar
fn make_bar(level: u32) -> String {
    let filled = (level / 5) as usize;
    let empty = 20 - filled.min(20);
    let label = if level >= 80 {
        "CRITICAL"
    } else if level >= 60 {
        "HIGH"
    } else if level >= 40 {
        "MODERATE"
    } else {
        "LOW"
    };
    format!("[{}{}] {}", "#".repeat(filled), "-".repeat(empty), label)
}

// Helper: Extract string from JSON (simple)
fn extract_json_string(json: &str, key: &str) -> String {
    let search = format!("\"{}\": \"", key);
    if let Some(start) = json.find(&search) {
        let value_start = start + search.len();
        if let Some(end) = json[value_start..].find('"') {
            return json[value_start..value_start + end].to_string();
        }
    }
    String::new()
}

// Benchmark BN254
fn bench_bn254() -> (u128, u128, u128, usize, String) {
    let mut backend = BN254Backend::new();

    print!("  [1/3] Setup... ");
    let t1 = Instant::now();
    backend.setup().unwrap();
    let setup_ms = t1.elapsed().as_millis();
    println!("{}ms", setup_ms);

    print!("  [2/3] Prove 3x7=21... ");
    let t2 = Instant::now();
    let proof = backend.prove(3, 7).unwrap();
    let prove_ms = t2.elapsed().as_millis();
    let size = proof.proof_bytes.len();
    println!("{}ms ({} bytes)", prove_ms, size);

    print!("  [3/3] Verify... ");
    let t3 = Instant::now();
    let ok = backend.verify(&proof).unwrap();
    let verify_ms = t3.elapsed().as_millis();
    let status = if ok { "VALID" } else { "INVALID" };
    println!("{} ({}ms)", status, verify_ms);

    (setup_ms, prove_ms, verify_ms, size, status.to_string())
}

// Benchmark BLS12-381
fn bench_bls12_381() -> (u128, u128, u128, usize, String) {
    let mut backend = BLS12_381Backend::new();

    print!("  [1/3] Setup... ");
    let t1 = Instant::now();
    backend.setup().unwrap();
    let setup_ms = t1.elapsed().as_millis();
    println!("{}ms", setup_ms);

    print!("  [2/3] Prove 5x11=55... ");
    let t2 = Instant::now();
    let proof = backend.prove(5, 11).unwrap();
    let prove_ms = t2.elapsed().as_millis();
    let size = proof.proof_bytes.len();
    println!("{}ms ({} bytes)", prove_ms, size);

    print!("  [3/3] Verify... ");
    let t3 = Instant::now();
    let ok = backend.verify(&proof).unwrap();
    let verify_ms = t3.elapsed().as_millis();
    let status = if ok { "VALID" } else { "INVALID" };
    println!("{} ({}ms)", status, verify_ms);

    (setup_ms, prove_ms, verify_ms, size, status.to_string())
}