// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./UniversalVerifier.sol";

/**
 * @title MorphController
 * @notice High-level controller for Chameleon-ZK morphing operations
 * @dev Manages threat levels and automatic morph triggers
 */
contract MorphController {
    
    UniversalVerifier public verifier;
    
    // Threat levels
    uint8 public constant THREAT_LOW = 0;
    uint8 public constant THREAT_MEDIUM = 1;
    uint8 public constant THREAT_HIGH = 2;
    uint8 public constant THREAT_CRITICAL = 3;
    
    // Current threat assessment
    uint8 public currentThreatLevel;
    uint256 public lastThreatUpdate;
    
    // Threat thresholds for auto-morph
    uint8 public autoMorphThreshold;
    
    // Events
    event ThreatLevelUpdated(uint8 oldLevel, uint8 newLevel, uint256 timestamp);
    event AutoMorphTriggered(uint8 fromBackend, uint8 toBackend, uint8 threatLevel);
    
    address public owner;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    constructor(address _verifier) {
        owner = msg.sender;
        verifier = UniversalVerifier(_verifier);
        currentThreatLevel = THREAT_LOW;
        autoMorphThreshold = THREAT_HIGH;
        lastThreatUpdate = block.timestamp;
    }
    
    /**
     * @notice Update the current threat level
     * @param newLevel The new threat level (0-3)
     */
    function updateThreatLevel(uint8 newLevel) external onlyOwner {
        require(newLevel <= THREAT_CRITICAL, "Invalid threat level");
        
        uint8 oldLevel = currentThreatLevel;
        currentThreatLevel = newLevel;
        lastThreatUpdate = block.timestamp;
        
        emit ThreatLevelUpdated(oldLevel, newLevel, block.timestamp);
    }
    
    /**
     * @notice Set the threshold for automatic morphing
     * @param threshold Threat level that triggers auto-morph
     */
    function setAutoMorphThreshold(uint8 threshold) external onlyOwner {
        require(threshold <= THREAT_CRITICAL, "Invalid threshold");
        autoMorphThreshold = threshold;
    }
    
    /**
     * @notice Check if auto-morph should be triggered
     */
    function shouldAutoMorph() public view returns (bool) {
        return currentThreatLevel >= autoMorphThreshold;
    }
    
    /**
     * @notice Get recommended backend based on threat level
     * @return Recommended backend ID
     */
    function getRecommendedBackend() public view returns (uint8) {
        // Higher threat = use more secure backend (BLS12-381)
        if (currentThreatLevel >= THREAT_HIGH) {
            return verifier.BACKEND_BLS12_381();
        } else {
            return verifier.BACKEND_BN254();
        }
    }
    
    /**
     * @notice Get threat level name
     */
    function getThreatLevelName() external view returns (string memory) {
        if (currentThreatLevel == THREAT_LOW) return "LOW";
        if (currentThreatLevel == THREAT_MEDIUM) return "MEDIUM";
        if (currentThreatLevel == THREAT_HIGH) return "HIGH";
        if (currentThreatLevel == THREAT_CRITICAL) return "CRITICAL";
        return "UNKNOWN";
    }
    
    /**
     * @notice Get time since last threat update
     */
    function timeSinceLastUpdate() external view returns (uint256) {
        return block.timestamp - lastThreatUpdate;
    }
}