# Security Analysis

## Security Properties

| Property | How Achieved |
|----------|-------------|
| Data integrity during morph | state_commitment hash before/after |
| Authorized switching only | morph_validator proof required |
| Both backends work | Rust benchmark proves both valid |
| On-chain record | Sepolia transactions are permanent |

## Attack Scenarios

### Attack 1: Modify data during curve switch
Defense: state_commitment hash before morph is compared to hash after morph. Any change is detected.

### Attack 2: Unauthorized curve switch
Defense: morph_validator circuit requires authorization key. Without valid proof, switch is blocked.

### Attack 3: Replay old proof on new curve
Defense: BN254 points are 254-bit, BLS12-381 points are 381-bit. Math fails automatically.

## Limitations

| Limitation | Impact |
|-----------|--------|
| No post-quantum backend | Cannot resist quantum attacks |
| Single owner controls morphing | Centralization risk |
| Threat scores are simulated | Acceptable for demo |