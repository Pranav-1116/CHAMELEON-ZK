#!/bin/bash

echo ""
echo "========================================"
echo "  CHAMELEON-ZK THREAT SIMULATOR"
echo "  Dynamic Curve Morphing Demo"
echo "========================================"
echo ""

CONFIG=~/chameleon-zk/simulator/threat_config.json
LOG_FILE=~/chameleon-zk/simulator/logs/threat_log.txt
HISTORY_FILE=~/chameleon-zk/simulator/logs/morph_history.json

if ! command -v jq &> /dev/null; then
    echo "ERROR: jq not installed. Run: sudo apt install jq"
    exit 1
fi

if [ ! -f "$CONFIG" ]; then
    echo "ERROR: Config not found at $CONFIG"
    exit 1
fi

MORPH_THRESHOLD=$(jq -r '.morph_threshold' $CONFIG)
RECOVERY_THRESHOLD=$(jq -r '.recovery_threshold' $CONFIG)
INTERVAL=$(jq -r '.check_interval_seconds' $CONFIG)
TOTAL_CYCLES=$(jq -r '.total_cycles' $CONFIG)
PATTERN=$(jq -r '.threat_pattern' $CONFIG)
DEFAULT_BACKEND=$(jq -r '.backends.default' $CONFIG)
UPGRADE_BACKEND=$(jq -r '.backends.upgrade' $CONFIG)

echo "Simulation started at $(date)" > $LOG_FILE
echo '[]' > $HISTORY_FILE

CURRENT_BACKEND="$DEFAULT_BACKEND"
MORPHED=false
MORPH_COUNT=0

echo "  Config:"
echo "    Morph Threshold:    $MORPH_THRESHOLD"
echo "    Recovery Threshold: $RECOVERY_THRESHOLD"
echo "    Interval:           ${INTERVAL}s"
echo "    Cycles:             $TOTAL_CYCLES"
echo "    Pattern:            $PATTERN"
echo "    Default Backend:    $DEFAULT_BACKEND"
echo "    Upgrade Backend:    $UPGRADE_BACKEND"
echo ""

# Show Rust prover status
echo "  --- Rust Prover Status ---"
cd ~/chameleon-zk/prover
cargo run --release -- status 2>&1 | while IFS= read -r line; do
    echo "    $line"
done
echo ""
echo "  --- Rust Threat Analysis ---"
cargo run --release -- simulate 2>&1 | while IFS= read -r line; do
    echo "    $line"
done
echo ""

echo "  Circuits used during morphing:"
echo "    state_commitment  — proves data integrity before/after morph"
echo "    morph_validator   — proves curve switch is authorized"
echo ""
echo "  Rust commands used during morphing:"
echo "    morph --to bls12-381    — switch to higher security curve"
echo "    prove --backend bls12-381 — generate proof on new curve"
echo "    morph --to bn254        — switch back to default curve"
echo "    prove --backend bn254   — generate proof on restored curve"
echo ""
echo "  Score above $MORPH_THRESHOLD  -> auto-morph to $UPGRADE_BACKEND"
echo "  Score below $RECOVERY_THRESHOLD -> auto-morph back to $DEFAULT_BACKEND"
echo ""
echo "========================================"
echo ""

get_scores() {
    local cycle=$1
    local total=$2
    local mid=$((total / 2))

    case "$PATTERN" in
        "rising_falling")
            if [ $cycle -le $mid ]; then
                Q=$((cycle * 100 / mid))
                R=$((cycle * 60 / mid))
                G=$((cycle * 40 / mid))
            else
                local past=$((cycle - mid))
                local remain=$((total - mid))
                Q=$((100 - past * 100 / remain))
                R=$((60 - past * 60 / remain))
                G=$((40 - past * 40 / remain))
            fi
            P=20
            ;;
        "sudden_spike")
            local spike_start=$((total * 40 / 100))
            local spike_end=$((total * 70 / 100))
            if [ $cycle -lt $spike_start ]; then
                Q=10; R=5; G=5
            elif [ $cycle -lt $spike_end ]; then
                Q=95; R=80; G=70
            else
                Q=8; R=5; G=3
            fi
            P=15
            ;;
        "random")
            Q=$((RANDOM % 101))
            R=$((RANDOM % 101))
            G=$((RANDOM % 101))
            P=$((RANDOM % 101))
            ;;
        *)
            Q=$((cycle * 100 / total))
            R=$((cycle * 50 / total))
            G=$((cycle * 30 / total))
            P=20
            ;;
    esac

    [ $Q -lt 0 ] && Q=0; [ $Q -gt 100 ] && Q=100
    [ $R -lt 0 ] && R=0; [ $R -gt 100 ] && R=100
    [ $G -lt 0 ] && G=0; [ $G -gt 100 ] && G=100
    [ $P -lt 0 ] && P=0; [ $P -gt 100 ] && P=100
}

for CYCLE in $(seq 1 $TOTAL_CYCLES); do

    get_scores $CYCLE $TOTAL_CYCLES

    SCORE=$(( (Q * 40 + R * 30 + G * 20 + P * 10) / 100 ))

    if [ $SCORE -ge 75 ]; then
        LEVEL="CRITICAL"
    elif [ $SCORE -ge 50 ]; then
        LEVEL="HIGH"
    elif [ $SCORE -ge 25 ]; then
        LEVEL="MEDIUM"
    else
        LEVEL="LOW"
    fi

    BAR=""
    BAR_LEN=$((SCORE / 5))
    for i in $(seq 1 20); do
        if [ $i -le $BAR_LEN ]; then BAR="${BAR}#"; else BAR="${BAR}-"; fi
    done

    TIME=$(date +%H:%M:%S)
    printf "  [%s] %2d/%d | Q:%3d R:%3d G:%3d | Score:%3d [%s] %-8s | %s" \
        "$TIME" "$CYCLE" "$TOTAL_CYCLES" "$Q" "$R" "$G" "$SCORE" "$BAR" "$LEVEL" "$CURRENT_BACKEND"

    echo "[$TIME] Cycle=$CYCLE Q=$Q R=$R G=$G Score=$SCORE Level=$LEVEL Backend=$CURRENT_BACKEND" >> $LOG_FILE

    if [ $SCORE -ge $MORPH_THRESHOLD ] && [ "$MORPHED" = false ]; then
        echo ""
        echo ""
        echo "  !!! THRESHOLD EXCEEDED (Score $SCORE >= $MORPH_THRESHOLD) !!!"
        echo "  !!! AUTO-MORPH: $DEFAULT_BACKEND --> $UPGRADE_BACKEND !!!"
        echo ""

        bash ~/chameleon-zk/scripts/auto_morph.sh 2 1

        if [ $? -eq 0 ]; then
            CURRENT_BACKEND="$UPGRADE_BACKEND"
            MORPHED=true
            ((MORPH_COUNT++))
            echo ""
            echo "  >>> MORPH DONE — Now on $UPGRADE_BACKEND"
            echo ""
        fi

    elif [ $SCORE -lt $RECOVERY_THRESHOLD ] && [ "$MORPHED" = true ]; then
        echo ""
        echo ""
        echo "  <<< THREAT SUBSIDED (Score $SCORE < $RECOVERY_THRESHOLD) <<<"
        echo "  <<< AUTO-MORPH BACK: $UPGRADE_BACKEND --> $DEFAULT_BACKEND <<<"
        echo ""

        bash ~/chameleon-zk/scripts/auto_morph_back.sh

        if [ $? -eq 0 ]; then
            CURRENT_BACKEND="$DEFAULT_BACKEND"
            MORPHED=false
            ((MORPH_COUNT++))
            echo ""
            echo "  <<< RECOVERY DONE — Back on $DEFAULT_BACKEND"
            echo ""
        fi

    elif [ "$MORPHED" = true ]; then
        echo "  (morphed, monitoring)"
    else
        echo ""
    fi

    sleep $INTERVAL
done

echo ""
echo "========================================"
echo "  SIMULATION COMPLETE"
echo "========================================"
echo ""
echo "  Cycles:       $TOTAL_CYCLES"
echo "  Total morphs: $MORPH_COUNT"
echo "  Final:        $CURRENT_BACKEND"
echo ""

if [ -f "$HISTORY_FILE" ]; then
    COUNT=$(jq length $HISTORY_FILE 2>/dev/null)
    if [ "$COUNT" -gt 0 ] 2>/dev/null; then
        echo "  Morph History:"
        jq -r '.[] | "    \(.time) \(.direction): \(.from) -> \(.to) (\(.total_ms // "N/A")ms)"' $HISTORY_FILE
    fi
fi

echo ""

if [ "$MORPHED" = true ]; then
    echo "  Resetting..."
    bash ~/chameleon-zk/scripts/auto_morph_back.sh
fi

echo "  Done."
