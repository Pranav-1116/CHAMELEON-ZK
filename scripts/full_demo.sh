#!/bin/bash

echo ""
echo "========================================"
echo "  CHAMELEON-ZK COMPLETE DEMONSTRATION"
echo "========================================"
echo ""
echo "  Press Enter at each step to continue."
echo ""

echo "  STEP 1: Dashboard (current system state)"
read -r
~/chameleon-zk/scripts/dashboard.sh

echo ""
echo "  STEP 2: Proof Size Tracker"
read -r
~/chameleon-zk/scripts/proof_size.sh

echo ""
echo "  STEP 3: Benchmarks"
read -r
~/chameleon-zk/benchmarks/run_benchmarks.sh

echo ""
echo "  STEP 4: Threat Simulator (auto-morph demo)"
echo "  This takes ~2 minutes. Watch the auto-morph trigger."
read -r
~/chameleon-zk/scripts/threat_simulator.sh

echo ""
echo "  STEP 5: Final Dashboard (post-simulation)"
read -r
~/chameleon-zk/scripts/dashboard.sh

echo ""
echo "========================================"
echo "  DEMONSTRATION COMPLETE"
echo "========================================"
echo ""
