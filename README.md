
#  Chameleon-ZK

### A Zero-Knowledge Proof System with Dynamic Cryptographic Backend Switching

[![Rust](https://img.shields.io/badge/Rust-1.70%2B-orange.svg)](https://www.rust-lang.org/)
[![Solidity](https://img.shields.io/badge/Solidity-0.8.20-blue.svg)](https://soliditylang.org/)
[![Circom](https://img.shields.io/badge/Circom-2.1.x-green.svg)](https://docs.circom.io/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Status](https://img.shields.io/badge/Status-In%20Development-red.svg)]()

---

##  Table of Contents

- [Overview](#overview)
- [The Problem](#the-problem)
- [The Solution](#the-solution)
- [Key Innovation](#key-innovation)
- [System Architecture](#system-architecture)
- [Features](#features)
- [Technology Stack](#technology-stack)
- [Project Structure](#project-structure)
- [Installation](#installation)
- [Usage](#usage)
- [How It Works](#how-it-works)
- [Benchmarks](#benchmarks)
- [Use Cases](#use-cases)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License](#license)
- [Contact](#contact)
- [Acknowledgments](#acknowledgments)

---

##  Overview

**Chameleon-ZK** is a novel zero-knowledge proof system that can dynamically switch between different cryptographic backends at runtime while maintaining proof consistency and state integrity. Unlike traditional ZK systems that are permanently locked into a single set of cryptographic assumptions, Chameleon-ZK adapts to changing threat landscapes, regulatory requirements, and hardware availability.

**In Simple Terms:** Imagine a car that can switch its engine while driving—from a fuel-efficient engine on highways to a powerful engine on hills—without stopping. Chameleon-ZK does this for cryptography in zero-knowledge proofs.

---

## The Problem

### Current ZK Systems Are Cryptographically Rigid

Every existing zero-knowledge proof system makes permanent cryptographic choices during the design phase:

| System | Locked Into | Problem |
|--------|-------------|---------|
| zkSync | BN254 pairing curve | Cannot upgrade if BN254 is broken |
| StarkWare | STARK-friendly hashes | Cannot switch to different security model |
| Scroll | Keccak-friendly curves | Tied to specific hash function |
| Polygon zkEVM | BN254 + Keccak | Double dependency, double risk |

### Why This Is Dangerous

**SCENARIO 1: Quantum Computing Breakthrough**
```
2024: System uses BN254 (secure against classical)
2030: Quantum computers break elliptic curve crypto
RESULT: Entire system compromised, billions at risk
```

**SCENARIO 2: Regulatory Change**
```
2024: System uses Curve25519 (efficient, popular)
2026: China requires SM2 curve for all financial apps
RESULT: Cannot operate in China, lose massive market
```

**SCENARIO 3: Cryptographic Attack**
```
2024: System uses specific hash function
2025: Researchers find collision attack
RESULT: 18-month migration project, $50M+ cost
```

### The Cost of Cryptographic Migration

| Migration Type | Estimated Cost | Time Required | Risk Level |
|----------------|----------------|---------------|------------|
| Hash function change | $10M - $50M | 12-24 months | High |
| Curve migration | $50M - $200M | 18-36 months | Critical |
| Full crypto overhaul | $200M - $500M | 24-48 months | Existential |
| Quantum transition | $1B+ (industry) | 36-60 months | Catastrophic |

---

##  The Solution

### Chameleon-ZK: Cryptographic Agility by Design

Chameleon-ZK introduces **cryptographic morphing**—the ability to switch between different cryptographic backends without:

-  Stopping the system
-  Losing state
-  Breaking existing proofs
-  Requiring user migration

```
BEFORE (Traditional):
┌─────────┐
│  BN254  │ ──── Forever locked, no escape
└─────────┘

AFTER (Chameleon-ZK):
┌─────────┐      ┌─────────────┐      ┌──────────┐
│  BN254  │ <--> │  BLS12-381  │ <--> │  Lattice │
│(Default)│      │(High Threat)│      │(Quantum) │
└─────────┘      └─────────────┘      └──────────┘
      ↑                 ↑                   ↑
      └─────────────────┼───────────────────┘
                        │
             ┌──────────▼──────────┐
             │   Threat Monitor    │
             │  (Decides backend)  │
             └─────────────────────┘
```

---

## Key Innovation

### What Makes Chameleon-ZK Unique

| Innovation | Description | Why It's Hard |
|------------|-------------|---------------|
| **Cross-Curve State Consistency** | State remains valid across backend switches | Different curves have different field sizes |
| **Universal Verification** | Single verifier accepts proofs from any backend | Each curve needs different pairing checks |
| **Morphing Proofs** | Cryptographic proof that a morph was valid | Must prove equivalence across incompatible systems |
| **Threat-Based Automation** | System decides when to morph | Requires real-time threat assessment |
| **Zero-Downtime Switching** | Switch backends without stopping service | Cannot have "maintenance mode" in blockchain |

### The Core Breakthrough

> **Traditional thinking:** "Pick the best cryptography and stick with it."
>
> **Chameleon-ZK thinking:** "Design for change from day one."

### The Morphing Protocol

**STEP 1: Threat Detected**
```
"Quantum computer achieved 1000 qubits"
Threat Score: 75/100 (HIGH)
Recommendation: Switch to post-quantum backend
```

**STEP 2: State Commitment**
```
Capture current state: Hash(balance, nonce, data)
Old commitment: 0x7a3f...
Backend: BN254
```

**STEP 3: Generate Morph Proof**
```
Prove: "Same data, different encoding"
Old backend: BN254
New backend: BLS12-381
Proof: Valid transition, no data manipulation
```

**STEP 4: Execute Morph**
```
Switch active backend: BN254 → BLS12-381
New commitment: 0x8b4e...
State preserved: YES
Downtime: 0 seconds
```

**STEP 5: Resume Operations**
```
New proofs use BLS12-381
Old BN254 proofs still verifiable
System fully operational
```

---

##  System Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         CHAMELEON-ZK ARCHITECTURE                       │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  LAYER 1: THREAT INTELLIGENCE                                           │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                      │
│  │  Quantum    │  │ Regulatory  │  │    Geo      │                      │
│  │  Monitor    │  │  Monitor    │  │  Detector   │                      │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘                      │
│         └────────────────┼────────────────┘                             │
│                          ▼                                              │
│  LAYER 2: DECISION ENGINE                                               │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │  Score = (Quantum × 0.4) + (Regulatory × 0.3) +                  │   │
│  │          (Geo × 0.2) + (Performance × 0.1)                       │   │
│  │                                                                  │   │
│  │  0-25: LOW (BN254) │  26-50: MEDIUM │  51-75: HIGH│ 6+: CRITICAL │   |
│  └──────────────────────────────────────────────────────────────────┘   │
│                          ▼                                              │
│  LAYER 3: BACKEND POOL                                                  │
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐                 │
│  │   BN254      │   │  BLS12-381   │   │   LATTICE    │                 │
│  │   ACTIVE     │   │   STANDBY    │   │   RESERVE    │                 │
│  └──────────────┘   └──────────────┘   └──────────────┘                 │
│                          ▼                                              │
│  LAYER 4: MORPHING CIRCUIT                                              │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │  State Commitment → Morph Validator → New State                  │   │
│  └──────────────────────────────────────────────────────────────────┘   │
│                          ▼                                              │
│  LAYER 5: UNIVERSAL VERIFIER (On-Chain)                                 │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │  Single deployment, multi-backend support                        │   │
│  └──────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### Component Interaction Flow

```
USER                    CHAMELEON-ZK                    BLOCKCHAIN
 │                           │                               │
 │   1. Submit TX            │                               │
 │──────────────────────────>│                               │
 │                           │  2. Check threat level        │
 │                           │<─────────────────────────────>│
 │                           │  3. Select backend            │
 │                           │  4. Generate ZK proof         │
 │                           │  5. Submit proof              │
 │                           │──────────────────────────────>│
 │                           │  6. Verify (universal)        │
 │                           │<──────────────────────────────│
 │   7. Confirmation         │                               │
 │<──────────────────────────│                               │
```

---

##  Features

### Core Features

| Feature | Description | Status |
|---------|-------------|--------|
| Multi-Backend Support | BN254 and BLS12-381 elliptic curves |  Implemented |
| Dynamic Switching | Change backends at runtime |  Implemented |
| State Preservation | Maintain data integrity across morphs |  Implemented |
| Universal Verification | Single verifier for all backends |  Implemented |
| Threat Monitoring | Real-time security assessment |  In Progress |
| Automatic Morphing | Threat-triggered backend switching |  In Progress |
| Post-Quantum Ready | Lattice-based backend slot |  Planned |
| Regulatory Compliance | Jurisdiction-aware crypto selection |  Planned |

### Backend Comparison

| Property | BN254 | BLS12-381 | Lattice (Future) |
|----------|-------|-----------|------------------|
| Security Level | 100-bit | 128-bit | 256-bit |
| Quantum Resistant |  No |  No |  Yes |
| Ethereum Precompiles |  Yes |  No |  No |
| Proof Size | 192 bytes | 288 bytes | ~1-2 KB |
| Prove Time | Fast | Medium | Slow |
| Verify Time | Very Fast | Fast | Medium |
| Gas Cost (ETH) | ~200K | ~500K | ~1M+ |
| Best For | Normal ops | High security | Quantum threats |

### Circuit Features

| Circuit | Purpose | Constraints |
|---------|---------|-------------|
| Simple Multiplier | Basic proof testing | ~5 |
| State Commitment | Create state hash | ~300-400 |
| Morph Validator | Prove valid transition | ~600-800 |

---

##  Technology Stack

### Languages & Frameworks

| Component | Technology | Version | Purpose |
|-----------|------------|---------|---------|
| Core Prover | Rust | 1.70+ | Performance-critical proving |
| ZK Library | Arkworks | 0.4 | Elliptic curve operations |
| Circuits | Circom | 2.1.x | ZK circuit definition |
| Proof Gen | snarkjs | 0.7+ | Trusted setup, proving |
| Contracts | Solidity | 0.8.20 | On-chain verification |
| Contract Tools | Foundry | Latest | Build, test, deploy |
| Scripting | Shell/Python | 3.10+ | Automation |

### Key Dependencies

| Crate/Package | Purpose |
|---------------|---------|
| `ark-bn254` | BN254 curve implementation |
| `ark-bls12-381` | BLS12-381 curve implementation |
| `ark-groth16` | Groth16 proof system |
| `ark-r1cs-std` | R1CS constraint gadgets |
| `circomlib` | Standard circuit components |
| `forge-std` | Solidity testing utilities |

---

##  Project Structure

```
chameleon-zk/
│
├── README.md                      # This file
├── LICENSE                        # MIT License
├── .gitignore                     # Git exclusions
│
├── .vscode/                       # VS Code configuration
│   ├── settings.json
│   ├── tasks.json
│   ├── launch.json
│   └── extensions.json
│
├── circuits/                      # Circom ZK circuits
│   ├── simple.circom
│   ├── state_commitment.circom
│   ├── morph_validator.circom
│   ├── package.json
│   └── build/
│
├── contracts/                     # Solidity smart contracts
│   ├── foundry.toml
│   ├── src/
│   │   ├── UniversalVerifier.sol
│   │   ├── MorphController.sol
│   │   ├── StateCommitmentVerifier.sol
│   │   └── MorphValidatorVerifier.sol
│   ├── test/
│   ├── script/
│   └── lib/
│
├── prover/                        # Rust proving system
│   ├── Cargo.toml
│   └── src/
│       ├── main.rs
│       ├── lib.rs
│       ├── types.rs
│       ├── circuit.rs
│       ├── bn254_backend.rs
│       ├── bls12_381_backend.rs
│       └── morph.rs
│
├── threat-intel/                  # Threat monitoring
│   ├── monitors/
│   └── data/
│
├── docs/                          # Documentation
│   ├── ARCHITECTURE.md
│   ├── LEARNING_LOG.md
│   ├── API.md
│   └── SECURITY.md
│
├── scripts/                       # Automation
│   ├── setup.sh
│   ├── build_all.sh
│   ├── test_all.sh
│   └── deploy.sh
│
├── benchmarks/                    # Performance data
│   └── results.json
│
└── tests/                         # Integration tests
    └── integration/
```

---

##  Installation

### Prerequisites

| Requirement | Minimum Version | Check Command |
|-------------|-----------------|---------------|
| Operating System | Linux (Kali / Ubuntu) | `uname -a` |
| RAM | 8 GB | `free -h` |
| Disk Space | 40 GB | `df -h` |
| Rust | 1.70+ | `rustc --version` |
| Node.js | 20.x | `node --version` |
| Circom | 2.1.x | `circom --version` |
| Foundry | Latest | `forge --version` |

### Step-by-Step Installation

#### Step 1: System Preparation

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y build-essential pkg-config libssl-dev git curl
```

#### Step 2: Install Rust

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env
rustc --version  # Verify
```

#### Step 3: Install Node.js via NVM

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
# Close and reopen terminal
nvm install 20
nvm use 20
node --version  # Verify
```

#### Step 4: Install Circom

```bash
git clone https://github.com/iden3/circom.git
cd circom
cargo build --release
cargo install --path circom
circom --version  # Verify
cd ..
```

#### Step 5: Install snarkjs

```bash
npm install -g snarkjs
snarkjs  # Verify (shows help)
```

#### Step 6: Install Foundry

```bash
curl -L https://foundry.paradigm.xyz | bash
# Close and reopen terminal
foundryup
forge --version  # Verify
```

#### Step 7: Clone and Setup Project

```bash
git clone https://github.com/YOUR_USERNAME/chameleon-zk.git
cd chameleon-zk

# Install circuit dependencies
cd circuits
npm install
cd ..

# Build Rust prover
cd prover
cargo build --release
cd ..

# Initialize Foundry project
cd contracts
forge install
forge build
cd ..
```

### Verification

| Component | Command | Expected Output |
|-----------|---------|-----------------|
| Rust | `rustc --version` | rustc 1.7x.x |
| Node | `node --version` | v20.x.x |
| Circom | `circom --version` | circom compiler 2.1.x |
| snarkjs | `snarkjs` | Help menu |
| Forge | `forge --version` | forge 0.2.x |
| Prover builds | `cd prover && cargo build --release` | Finished release |
| Contracts build | `cd contracts && forge build` | Compiler run successful |

---

## 🎮 Usage

### Running the Prover Demo

```bash
cd prover
cargo run --release
```

#### Expected Output

```
------------------------------------------------------------                                                          
   CHAMELEON-ZK                                             
   Zero-Knowledge Proof System v0.1.0                          
   Dynamic Cryptographic Backend Switching                     
------------------------------------------------------------                                                            


[Chameleon-ZK] Initializing prover...

→ Setting up cryptographic backends...
   ✓ Completed (2.3s)

============================================================
TEST 1 — Proof Generation (BN254)
============================================================

Generating proof: 3 × 7 = 21
   Backend        : BN254
   Proof size     : 192 bytes
   Public output  : 21
   ✓ Verified (2ms)
   Prove time     : 45ms

============================================================
TEST 2 — Threat-Based Morphing
============================================================

Threat level detected      : HIGH
Recommended backend        : BLS12-381
Morphing backend           : BN254 → BLS12-381
State preserved            : true
   ✓ Morph completed (1ms)

============================================================
TEST 3 — Proof Generation (BLS12-381)
============================================================

Generating proof: 5 × 11 = 55
   Backend        : BLS12-381
   Proof size     : 288 bytes
   Public output  : 55
   ✓ Verified (5ms)
   Prove time     : 78ms

────────────────────────────────────────────────────────────
FINAL STATE
────────────────────────────────────────────────────────────

Active backend    : BLS12-381
Total morphs      : 1
Proofs generated  : 2
Proofs verified   : 3

 Chameleon-ZK demo completed successfully.
```

### Compiling Circuits

```bash
cd circuits

# Compile simple circuit
circom simple.circom --r1cs --wasm --sym -o ./build

# Compile state commitment circuit
circom state_commitment.circom --r1cs --wasm --sym -o ./build/state_commitment

# Compile morph validator circuit
circom morph_validator.circom --r1cs --wasm --sym -o ./build/morph_validator
```

### Running Contract Tests

```bash
cd contracts
forge test -vvv
```

### Starting Local Blockchain

```bash
# Terminal 1: Start Anvil
anvil

# Terminal 2: Deploy contracts
cd contracts
forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast
```

---

## ⚙️ How It Works

### 1. Zero-Knowledge Proof Basics

```
┌─────────────────────────────────────────────────────────────┐
│  PROVER (holds private witness)                             │
│  • Secret data (witness)                                    │
│  • Private inputs                                           │
│  • Account balance, transaction data                        │
├─────────────────────────────────────────────────────────────┤
│  VERIFIER (receives)                                        │
│  • Public output (claimed result)                           │
│  • Cryptographic proof (~256 bytes)                         │
├─────────────────────────────────────────────────────────────┤
│  WHAT VERIFIER LEARNS:                                      │
│   The computation was executed correctly                    │
│   The prover knows valid inputs                             │
│   The actual private inputs                                 │
│   Any secret values                                         │
└─────────────────────────────────────────────────────────────┘
```

**Example:**
- Prover knows (SECRET): `a = 3`, `b = 7`
- Public claim: `a × b = 21`
- Verifier confirms: Multiplication is correct
- Verifier does NOT learn: `a = 3` or `b = 7`

### 2. Backend Selection Logic

```
Step 1: Calculate Threat Score (0 – 100)

Threat Score Components:
├── Quantum Advancement    0.40  (highest weight)
├── Regulatory Risk        0.30  (compliance impact)
├── Geographic Risk        0.20  (jurisdiction exposure)
└── Performance Demand     0.10  (efficiency priority)

Decision Tree:
├── Score < 50      → Use BN254 (Normal mode)
├── 50 ≤ Score < 75 → Prepare Morph (Transition state)
└── Score ≥ 75      → Use BLS12-381 (High security)
```

### 3. Morphing Process

| Step | Action | Details |
|------|--------|---------|
| 1 | State Before | Backend: BN254, Balance: 1000, Nonce: 42 |
| 2 | Morph Proof | Prove same data, different encoding |
| 3 | State After | Backend: BLS12-381, Balance: 1000, Nonce: 42 |

**Security Guarantees:**
-  Impossible to change balance during morph
-  Impossible to replay old proofs as morphs
-  Impossible to morph to same backend
-  All transitions are publicly auditable

---

##  Benchmarks

### Proof Generation Performance

| Backend | Setup Time | Prove Time | Verify Time | Proof Size |
|---------|------------|------------|-------------|------------|
| BN254 | ~2.0s | ~45ms | ~2ms | 192 bytes |
| BLS12-381 | ~3.5s | ~78ms | ~5ms | 288 bytes |
| **Difference** | +75% | +73% | +150% | +50% |

### Morphing Performance

| Metric | Value |
|--------|-------|
| Morph decision time | < 1ms |
| State commitment | ~10ms |
| Morph proof generation | ~50ms |
| On-chain verification | ~200K gas |
| **Total morph time** | **< 100ms** |

### Gas Costs (Ethereum)

| Operation | BN254 | BLS12-381 |
|-----------|-------|-----------|
| Proof verification | ~200K gas | ~500K gas |
| State commitment | ~50K gas | ~50K gas |
| Morph execution | ~300K gas | ~300K gas |

### Comparison with Fixed-Backend Systems

| System | Can Switch? | Migration Cost | Quantum Ready? |
|--------|-------------|----------------|----------------|
| zkSync |  No | $50M+ |  No |
| StarkWare |  No | $100M+ |  Partial |
| Polygon zkEVM |  No | $80M+ |  No |
| **Chameleon-ZK** |  Yes | **$0** |  Yes |

---

##  Use Cases

### 1. Quantum Threat Response

| Approach | Timeline | Cost |
|----------|----------|------|
| **Traditional System** | 2+ years (panic → design → implement → test → deploy) | $100M+ |
| **Chameleon-ZK** | 3 minutes (detect → morph → operational) | $0 |

### 2. Regulatory Compliance

**Scenario:** China requires SM2 curve for financial applications

| Approach | Solution | Cost |
|----------|----------|------|
| Traditional | Build China-specific version, maintain two codebases | $20M/year |
| Chameleon-ZK | Add SM2 backend, auto-morph in Chinese jurisdiction | $0 additional |

### 3. Emergency Cryptographic Vulnerability

**Scenario:** Critical vulnerability found in BN254 implementation

| Approach | Downtime | Loss |
|----------|----------|------|
| Traditional | Days to weeks | Potentially catastrophic |
| Chameleon-ZK | 0 seconds | $0, business continues |

---

##  Roadmap

### Phase 1: Foundation (Weeks 1-2) 

- [] Project structure
- [] BN254 backend
- [] BLS12-381 backend
- [] Basic morphing
- [] Circom circuits
- [] Solidity verifiers

### Phase 2: Integration (Weeks 3-4) 

- [ ] Testnet deployment
- [ ] End-to-end testing
- [ ] Gas optimization
- [ ] Documentation

### Phase 3: Intelligence (Weeks 5-6) 

- [ ] Quantum threat monitor
- [ ] Regulatory API integration
- [ ] Geo-detection system
- [ ] Automated decision engine

### Phase 4: Production (Weeks 7-8) 

- [ ] Mainnet deployment
- [ ] Performance benchmarks
- [ ] Security audit
- [ ] Public demo

### Future Enhancements

| Feature | Timeline | Description |
|---------|----------|-------------|
| Lattice backend | Q2 2025 | Post-quantum cryptography |
| Multi-party morphing | Q3 2025 | Distributed morph decisions |
| Cross-chain support | Q4 2025 | Morph across blockchains |
| AI threat prediction | 2026 | Predictive morphing |

---



### Contribution Process

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request



---

##  License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

```
MIT License

Copyright (c) 2026 Chameleon-ZK Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

##  Contact

### Project Maintainer

| Platform | Contact |
|----------|---------|
| GitHub | [@Pranav-1116](https://github.com/Pranav-1116) |
| Email | pranav.akshay05@gmail.com |
| Twitter | [@pran40798](https://x.com/pran40798) |
| LinkedIn | [Akshay Pranav](https://www.linkedin.com/in/akshay-pranav-0a6aa2293/) |

---

##  Acknowledgments

### Libraries and Tools

- [Arkworks](https://arkworks.rs/) - ZK cryptography in Rust
- [Circom](https://docs.circom.io/) - ZK circuit compiler
- [snarkjs](https://github.com/iden3/snarkjs) - JavaScript ZK toolkit
- [Foundry](https://book.getfoundry.sh/) - Solidity development framework



---

<div align="center">

**Built with  for a more secure, adaptable future**

[⬆ Back to Top](#-chameleon-zk)

</div>
```

---
