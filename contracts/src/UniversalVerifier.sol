// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title UniversalVerifier
 * @notice Verifies ZK proofs from multiple cryptographic backends
 * @dev Part of Chameleon-ZK: Dynamic Cryptographic Backend System
 */

interface IVerifier {
    function verifyProof(
        uint[2] calldata _pA,
        uint[2][2] calldata _pB,
        uint[2] calldata _pC,
        uint[] calldata _pubSignals
    ) external view returns (bool);
}

contract UniversalVerifier {
    
    // Backend identifiers
    uint8 public constant BACKEND_BN254 = 0;
    uint8 public constant BACKEND_BLS12_381 = 1;
    
    // Proof types
    uint8 public constant PROOF_TYPE_STATE_COMMITMENT = 0;
    uint8 public constant PROOF_TYPE_MORPH_VALIDATOR = 1;
    
    // Verifier contracts for each proof type
    mapping(uint8 => address) public stateCommitmentVerifiers;
    mapping(uint8 => address) public morphValidatorVerifiers;
    
    // Current active backend
    uint8 public activeBackend;
    
    // Morph history
    struct MorphEvent {
        uint8 fromBackend;
        uint8 toBackend;
        uint256 timestamp;
        bytes32 stateCommitment;
    }
    
    MorphEvent[] public morphHistory;
    
    // Events
    event BackendMorphed(
        uint8 indexed fromBackend,
        uint8 indexed toBackend,
        uint256 timestamp
    );
    
    event ProofVerified(
        uint8 indexed proofType,
        uint8 indexed backend,
        bool success
    );
    
    // Owner for admin functions
    address public owner;
    
    modifier onlyOwner() {
    _onlyOwner();
    _;
}

function _onlyOwner() internal view {
    require(msg.sender == owner, "Not owner");
}

    
    constructor() {
        owner = msg.sender;
        activeBackend = BACKEND_BN254;  // Start with BN254
    }
    
    /**
     * @notice Register a verifier for state commitment proofs
     * @param backend The backend ID (0 = BN254, 1 = BLS12-381)
     * @param verifier The verifier contract address
     */
    function setStateCommitmentVerifier(
        uint8 backend,
        address verifier
    ) external onlyOwner {
        require(backend <= BACKEND_BLS12_381, "Invalid backend");
        stateCommitmentVerifiers[backend] = verifier;
    }
    
    /**
     * @notice Register a verifier for morph validation proofs
     * @param backend The backend ID
     * @param verifier The verifier contract address
     */
    function setMorphValidatorVerifier(
        uint8 backend,
        address verifier
    ) external onlyOwner {
        require(backend <= BACKEND_BLS12_381, "Invalid backend");
        morphValidatorVerifiers[backend] = verifier;
    }
    
    /**
     * @notice Verify a state commitment proof
     * @param _pA Proof element A
     * @param _pB Proof element B
     * @param _pC Proof element C
     * @param _pubSignals Public signals (commitment, backend_id)
     * @return True if proof is valid
     */
    function verifyStateCommitment(
        uint[2] calldata _pA,
        uint[2][2] calldata _pB,
        uint[2] calldata _pC,
        uint[] calldata _pubSignals
    ) external returns (bool) {
        address verifier = stateCommitmentVerifiers[activeBackend];
        require(verifier != address(0), "Verifier not set");
        
        bool success = IVerifier(verifier).verifyProof(_pA, _pB, _pC, _pubSignals);
        
        emit ProofVerified(PROOF_TYPE_STATE_COMMITMENT, activeBackend, success);
        
        return success;
    }
    
    /**
     * @notice Verify a morph validation proof and execute the morph
     * @param _pA Proof element A
     * @param _pB Proof element B
     * @param _pC Proof element C
     * @param _pubSignals Public signals (old/new backend, old/new commitment)
     * @return True if morph is valid and executed
     */
    function verifyAndExecuteMorph(
        uint[2] calldata _pA,
        uint[2][2] calldata _pB,
        uint[2] calldata _pC,
        uint[] calldata _pubSignals
    ) external returns (bool) {
        // _pubSignals layout:
        // [0] = old_backend_id
        // [1] = new_backend_id
        // [2] = old_commitment
        // [3] = new_commitment
        
        require(_pubSignals.length >= 4, "Invalid public signals");
        
        uint8 oldBackend = uint8(_pubSignals[0]);
        uint8 newBackend = uint8(_pubSignals[1]);
        bytes32 newCommitment = bytes32(_pubSignals[3]);
        
        require(oldBackend == activeBackend, "Old backend mismatch");
        require(newBackend != oldBackend, "Must change backend");
        require(newBackend <= BACKEND_BLS12_381, "Invalid new backend");
        
        // Verify the morph proof with current backend's verifier
        address verifier = morphValidatorVerifiers[activeBackend];
        require(verifier != address(0), "Morph verifier not set");
        
        bool success = IVerifier(verifier).verifyProof(_pA, _pB, _pC, _pubSignals);
        require(success, "Invalid morph proof");
        
        // Execute the morph
        MorphEvent memory morphEvent = MorphEvent({
            fromBackend: activeBackend,
            toBackend: newBackend,
            timestamp: block.timestamp,
            stateCommitment: newCommitment
        });
        
        morphHistory.push(morphEvent);
        activeBackend = newBackend;
        
        emit BackendMorphed(oldBackend, newBackend, block.timestamp);
        emit ProofVerified(PROOF_TYPE_MORPH_VALIDATOR, oldBackend, true);
        
        return true;
    }
    
    /**
     * @notice Get the current active backend name
     */
    function getActiveBackendName() external view returns (string memory) {
        if (activeBackend == BACKEND_BN254) {
            return "BN254";
        } else if (activeBackend == BACKEND_BLS12_381) {
            return "BLS12-381";
        } else {
            return "Unknown";
        }
    }
    
    /**
     * @notice Get number of morphs that have occurred
     */
    function getMorphCount() external view returns (uint256) {
        return morphHistory.length;
    }
    
    /**
     * @notice Get details of a specific morph
     */
    function getMorphDetails(uint256 index) external view returns (
        uint8 fromBackend,
        uint8 toBackend,
        uint256 timestamp,
        bytes32 stateCommitment
    ) {
        require(index < morphHistory.length, "Invalid index");
        MorphEvent memory m = morphHistory[index];
        return (m.fromBackend, m.toBackend, m.timestamp, m.stateCommitment);
    }
}
