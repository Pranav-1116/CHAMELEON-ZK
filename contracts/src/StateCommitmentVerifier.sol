// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {BN254Verifier} from "./Verifier.sol";

/**
 * @title StateCommitmentVerifier
 * @dev Manages state commitments for Chameleon-ZK morphing
 */
contract StateCommitmentVerifier {
    
    struct Commitment {
        uint256 commitment;
        uint8 backendId;
        uint256 timestamp;
        bool verified;
    }
    
    BN254Verifier public verifier;
    
    mapping(address => Commitment[]) public commitmentHistory;
    mapping(uint256 => bool) public commitmentExists;
    mapping(uint256 => address) public commitmentOwner;
    
    event CommitmentSubmitted(
        address indexed user,
        uint256 indexed commitment,
        uint8 backendId,
        uint256 index
    );
    
    event CommitmentVerified(
        address indexed user,
        uint256 indexed commitment,
        bool valid
    );
    
    constructor(address _verifier) {
        verifier = BN254Verifier(_verifier);
    }
    
    function submitCommitment(
        uint256 commitment,
        uint8 backendId
    ) external returns (uint256) {
        require(!commitmentExists[commitment], "Commitment exists");
        require(backendId <= 1, "Invalid backend");
        
        Commitment memory newCommitment = Commitment({
            commitment: commitment,
            backendId: backendId,
            timestamp: block.timestamp,
            verified: false
        });
        
        commitmentHistory[msg.sender].push(newCommitment);
        uint256 index = commitmentHistory[msg.sender].length - 1;
        
        commitmentExists[commitment] = true;
        commitmentOwner[commitment] = msg.sender;
        
        emit CommitmentSubmitted(msg.sender, commitment, backendId, index);
        return index;
    }
    
    function verifyCommitment(
        uint256 index,
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c,
        uint256[1] calldata publicInputs
    ) external returns (bool) {
        require(index < commitmentHistory[msg.sender].length, "Invalid index");
        
        Commitment storage commit = commitmentHistory[msg.sender][index];
        require(!commit.verified, "Already verified");
        
        bool valid = verifier.verifyProof(a, b, c, publicInputs);
        
        if (valid) {
            commit.verified = true;
        }
        
        emit CommitmentVerified(msg.sender, commit.commitment, valid);
        return valid;
    }
    
    function getCommitmentCount(address user) external view returns (uint256) {
        return commitmentHistory[user].length;
    }
    
    function getCommitment(address user, uint256 index) external view returns (
        uint256 commitment,
        uint8 backendId,
        uint256 timestamp,
        bool verified
    ) {
        require(index < commitmentHistory[user].length, "Invalid index");
        Commitment memory commit = commitmentHistory[user][index];
        return (
            commit.commitment,
            commit.backendId,
            commit.timestamp,
            commit.verified
        );
    }
    
    function isCommitmentVerified(uint256 commitment) external view returns (bool) {
        address owner = commitmentOwner[commitment];
        if (owner == address(0)) return false;
        
        for (uint256 i = 0; i < commitmentHistory[owner].length; i++) {
            if (commitmentHistory[owner][i].commitment == commitment) {
                return commitmentHistory[owner][i].verified;
            }
        }
        return false;
    }
}