// Simple threat simulator for Chameleon-ZK

use crate::types::BackendType;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ThreatLevel {
    pub quantum: u32,    // 0-100
    pub regulatory: u32, // 0-100
    pub overall: u32,    // calculated
}

impl ThreatLevel {
    pub fn new(quantum: u32, regulatory: u32) -> Self {
        let overall = (quantum * 60 + regulatory * 40) / 100;
        Self {
            quantum,
            regulatory,
            overall,
        }
    }

    pub fn normal() -> Self {
        Self::new(10, 15)
    }

    pub fn elevated() -> Self {
        Self::new(45, 30)
    }

    pub fn high() -> Self {
        Self::new(70, 50)
    }

    pub fn critical() -> Self {
        Self::new(95, 80)
    }
}

#[derive(Debug, Clone)]
pub struct MorphDecision {
    pub should_morph: bool,
    pub recommended_backend: BackendType,
    pub reason: String,
}

pub struct ThreatSimulator {
    pub current_backend: BackendType,
    pub threat_threshold: u32,
}

impl ThreatSimulator {
    pub fn new(initial_backend: BackendType, threshold: u32) -> Self {
        Self {
            current_backend: initial_backend,
            threat_threshold: threshold,
        }
    }

    /// Evaluate threat and decide if morph needed
    pub fn evaluate(&self, threat: &ThreatLevel) -> MorphDecision {
        if threat.quantum >= 80 {
            return MorphDecision {
                should_morph: self.current_backend != BackendType::BLS12_381,
                recommended_backend: BackendType::BLS12_381,
                reason: "CRITICAL: Quantum threat level requires maximum security".to_string(),
            };
        }

        if threat.quantum >= 60 {
            return MorphDecision {
                should_morph: self.current_backend == BackendType::BN254,
                recommended_backend: BackendType::BLS12_381,
                reason: "WARNING: Elevated quantum threat, recommend higher security".to_string(),
            };
        }

        if threat.overall < 30 && self.current_backend != BackendType::BN254 {
            return MorphDecision {
                should_morph: true,
                recommended_backend: BackendType::BN254,
                reason: "LOW THREAT: Can optimize for speed with BN254".to_string(),
            };
        }

        MorphDecision {
            should_morph: false,
            recommended_backend: self.current_backend,
            reason: "Current backend is appropriate for threat level".to_string(),
        }
    }

    /// Simulate a threat scenario
    pub fn simulate(&mut self, scenario: &str) -> (ThreatLevel, MorphDecision) {
        let threat = match scenario.to_lowercase().as_str() {
            "quantum" | "quantum_emergency" => ThreatLevel::critical(),
            "elevated" => ThreatLevel::elevated(),
            "high" => ThreatLevel::high(),
            "normal" | "low" => ThreatLevel::normal(),
            _ => ThreatLevel::normal(),
        };

        let decision = self.evaluate(&threat);

        if decision.should_morph {
            self.current_backend = decision.recommended_backend;
        }

        (threat, decision)
    }

    /// Print simulation results
    pub fn print_simulation(&self, threat: &ThreatLevel, decision: &MorphDecision) {
        println!("                     THREAT SIMULATION                        ");
        println!("Threat Levels:");
        println!(
            "  Quantum:    {:3}/100  {}",
            threat.quantum,
            self.threat_bar(threat.quantum)
        );
        println!(
            "  Regulatory: {:3}/100  {}",
            threat.regulatory,
            self.threat_bar(threat.regulatory)
        );
        println!(
            "  Overall:    {:3}/100  {}",
            threat.overall,
            self.threat_bar(threat.overall)
        );
        println!(
            "Decision: {}",
            if decision.should_morph {
                "MORPH REQUIRED"
            } else {
                "NO MORPH NEEDED"
            }
        );
        println!("Backend:  {:?}", decision.recommended_backend);
        println!("Reason:   {}", decision.reason);
    }

    fn threat_bar(&self, level: u32) -> String {
        let filled = (level / 5) as usize;
        let empty = 20 - filled;
        format!("[{}{}]", "#".repeat(filled), "-".repeat(empty))
    }
}
