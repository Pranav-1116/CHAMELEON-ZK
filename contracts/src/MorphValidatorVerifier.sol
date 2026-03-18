// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {BN254Verifier, BLS12381Verifier, MorphVerifier} from "../src/Verifier.sol";
import {StateCommitmentVerifier} from "../src/StateCommitmentVerifier.sol";

contract VerifierTest is Test {
    
    BN254Verifier public bn254;
    BLS12381Verifier public bls12381;
    MorphVerifier public morph;
    StateCommitmentVerifier public stateVerifier;
    
    address public user1 = address(0x1);
    address public user2 = address(0x2);
    
    function setUp() public {
        bn254 = new BN254Verifier();
        bls12381 = new BLS12381Verifier();
        morph = new MorphVerifier(address(bn254), address(bls12381));
        stateVerifier = new StateCommitmentVerifier(address(bn254));
    }
    
    // ==================== Deployment Tests ====================
    
    function testBN254Deployed() public view {
        assertTrue(address(bn254) != address(0), "BN254 not deployed");
    }
    
    function testBLS12381Deployed() public view {
        assertTrue(address(bls12381) != address(0), "BLS12381 not deployed");
    }
    
    function testMorphDeployed() public view {
        assertTrue(address(morph) != address(0), "Morph not deployed");
    }
    
    function testStateVerifierDeployed() public view {
        assertTrue(address(stateVerifier) != address(0), "StateVerifier not deployed");
    }
    
    // ==================== Morph Tests ====================
    
    function testMorphRequest() public {
        uint256 oldCommit = uint256(keccak256("old"));
        uint256 newCommit = uint256(keccak256("new"));
        
        uint256 morphIndex = morph.requestMorph(0, 1, oldCommit, newCommit);
        
        assertEq(morphIndex, 0, "First morph should be index 0");
    }
    
    function testMorphCount() public {
        uint256 oldCommit = uint256(keccak256("old"));
        uint256 newCommit = uint256(keccak256("new"));
        
        morph.requestMorph(0, 1, oldCommit, newCommit);
        
        uint256 count = morph.getMorphCount(address(this));
        assertEq(count, 1, "Should have 1 morph");
    }
    
    function testCannotMorphToSameBackend() public {
        uint256 oldCommit = uint256(keccak256("old"));
        uint256 newCommit = uint256(keccak256("new"));
        
        vm.expectRevert("Same backend");
        morph.requestMorph(0, 0, oldCommit, newCommit);
    }
    
    function testCannotMorphInvalidBackend() public {
        uint256 oldCommit = uint256(keccak256("old"));
        uint256 newCommit = uint256(keccak256("new"));
        
        vm.expectRevert("Invalid backend");
        morph.requestMorph(0, 2, oldCommit, newCommit);
    }
    
    function testMultipleMorphRequests() public {
        uint256 commit1 = uint256(keccak256("state1"));
        uint256 commit2 = uint256(keccak256("state2"));
        uint256 commit3 = uint256(keccak256("state3"));
        
        uint256 index1 = morph.requestMorph(0, 1, commit1, commit2);
        uint256 index2 = morph.requestMorph(1, 0, commit2, commit3);
        
        assertEq(index1, 0, "First morph index should be 0");
        assertEq(index2, 1, "Second morph index should be 1");
        assertEq(morph.getMorphCount(address(this)), 2, "Should have 2 morphs");
    }
    
    // ==================== BLS12-381 Tests ====================
    
    function testBLSProofSubmit() public {
        bytes memory proofData = hex"1234567890";
        uint256[] memory inputs = new uint256[](1);
        inputs[0] = 21;
        
        bytes32 proofHash = bls12381.submitProof(proofData, inputs);
        
        assertTrue(bls12381.isSubmitted(proofHash), "Proof should be submitted");
        assertFalse(bls12381.isVerified(proofHash), "Proof should not be verified yet");
    }
    
    function testBLSProofVerify() public {
        bytes memory proofData = hex"abcdef";
        uint256[] memory inputs = new uint256[](1);
        inputs[0] = 42;
        
        bytes32 proofHash = bls12381.submitProof(proofData, inputs);
        bls12381.markVerified(proofHash, true);
        
        assertTrue(bls12381.isVerified(proofHash), "Proof should be verified");
    }
    
    function testCannotVerifyUnsubmittedProof() public {
        // forge-lint: disable-next-line(asm-keccak256)
        bytes32 fakeHash = keccak256("fake");
        
        vm.expectRevert("Not submitted");
        bls12381.markVerified(fakeHash, true);
    }
    
    // ==================== Morph with BLS Proof Tests ====================
    
    function testMorphWithBLSProof() public {
        // Request morph
        uint256 oldCommit = uint256(keccak256("old_state"));
        uint256 newCommit = uint256(keccak256("new_state"));
        uint256 morphIndex = morph.requestMorph(0, 1, oldCommit, newCommit);
        
        // Submit and verify BLS proof
        bytes memory proofData = hex"1234";
        uint256[] memory inputs = new uint256[](1);
        inputs[0] = 100;
        bytes32 proofHash = bls12381.submitProof(proofData, inputs);
        bls12381.markVerified(proofHash, true);
        
        // Verify morph with BLS proof
        bool valid = morph.verifyMorphBLS12381(morphIndex, proofHash);
        assertTrue(valid, "Morph should be valid");
    }
    
    function testCannotVerifyMorphTwice() public {
        uint256 oldCommit = uint256(keccak256("old"));
        uint256 newCommit = uint256(keccak256("new"));
        uint256 morphIndex = morph.requestMorph(0, 1, oldCommit, newCommit);
        
        // Submit and verify BLS proof
        bytes memory proofData = hex"5678";
        uint256[] memory inputs = new uint256[](1);
        inputs[0] = 200;
        bytes32 proofHash = bls12381.submitProof(proofData, inputs);
        bls12381.markVerified(proofHash, true);
        
        // First verification
        morph.verifyMorphBLS12381(morphIndex, proofHash);
        
        // Second verification should fail
        vm.expectRevert("Already verified");
        morph.verifyMorphBLS12381(morphIndex, proofHash);
    }
    
    // ==================== State Commitment Tests ====================
    
    function testStateCommitmentSubmit() public {
        uint256 commitment = uint256(keccak256("test_state"));
        
        uint256 index = stateVerifier.submitCommitment(commitment, 0);
        
        assertEq(index, 0, "First commitment should be index 0");
    }
    
    function testStateCommitmentCount() public {
        uint256 commitment = uint256(keccak256("test_state"));
        
        stateVerifier.submitCommitment(commitment, 0);
        
        uint256 count = stateVerifier.getCommitmentCount(address(this));
        assertEq(count, 1, "Should have 1 commitment");
    }
    
    function testCannotSubmitDuplicateCommitment() public {
        uint256 commitment = uint256(keccak256("duplicate"));
        
        stateVerifier.submitCommitment(commitment, 0);
        
        vm.expectRevert("Commitment exists");
        stateVerifier.submitCommitment(commitment, 0);
    }
    
    function testCannotSubmitInvalidBackend() public {
        uint256 commitment = uint256(keccak256("invalid_backend"));
        
        vm.expectRevert("Invalid backend");
        stateVerifier.submitCommitment(commitment, 2);
    }
    
    function testMultipleCommitments() public {
        uint256 commit1 = uint256(keccak256("state1"));
        uint256 commit2 = uint256(keccak256("state2"));
        
        uint256 index1 = stateVerifier.submitCommitment(commit1, 0);
        uint256 index2 = stateVerifier.submitCommitment(commit2, 1);
        
        assertEq(index1, 0, "First commitment index should be 0");
        assertEq(index2, 1, "Second commitment index should be 1");
    }
    
    function testGetCommitmentDetails() public {
        uint256 commitment = uint256(keccak256("detailed_state"));
        
        stateVerifier.submitCommitment(commitment, 1);
        
        (uint256 storedCommit, uint8 backendId, uint256 timestamp, bool verified) = 
            stateVerifier.getCommitment(address(this), 0);
        
        assertEq(storedCommit, commitment, "Commitment mismatch");
        assertEq(backendId, 1, "Backend ID mismatch");
        assertTrue(timestamp > 0, "Timestamp should be set");
        assertFalse(verified, "Should not be verified yet");
    }
    
    // ==================== Morph Stats Tests ====================
    
    function testMorphStats() public {
        uint256 oldCommit = uint256(keccak256("old"));
        uint256 newCommit = uint256(keccak256("new"));
        
        morph.requestMorph(0, 1, oldCommit, newCommit);
        morph.requestMorph(1, 0, newCommit, oldCommit);
        
        (uint256 total, uint256 successful) = morph.getStats();
        
        assertEq(total, 2, "Should have 2 total morphs");
        assertEq(successful, 0, "Should have 0 successful morphs");
    }
    
    function testMorphStatsAfterVerification() public {
        uint256 oldCommit = uint256(keccak256("old"));
        uint256 newCommit = uint256(keccak256("new"));
        uint256 morphIndex = morph.requestMorph(0, 1, oldCommit, newCommit);
        
        // Submit and verify BLS proof
        bytes memory proofData = hex"9999";
        uint256[] memory inputs = new uint256[](1);
        inputs[0] = 999;
        bytes32 proofHash = bls12381.submitProof(proofData, inputs);
        bls12381.markVerified(proofHash, true);
        
        // Verify morph
        morph.verifyMorphBLS12381(morphIndex, proofHash);
        
        (uint256 total, uint256 successful) = morph.getStats();
        
        assertEq(total, 1, "Should have 1 total morph");
        assertEq(successful, 1, "Should have 1 successful morph");
    }
    
    // ==================== Multi-User Tests ====================
    
    function testMultiUserMorphs() public {
        uint256 commit1 = uint256(keccak256("user1_state"));
        uint256 commit2 = uint256(keccak256("user2_state"));
        
        vm.prank(user1);
        morph.requestMorph(0, 1, commit1, commit2);
        
        vm.prank(user2);
        morph.requestMorph(1, 0, commit2, commit1);
        
        assertEq(morph.getMorphCount(user1), 1, "User1 should have 1 morph");
        assertEq(morph.getMorphCount(user2), 1, "User2 should have 1 morph");
    }
    
    function testMorphRecordRetrieval() public {
        uint256 oldCommit = uint256(keccak256("old_record"));
        uint256 newCommit = uint256(keccak256("new_record"));
        
        morph.requestMorph(0, 1, oldCommit, newCommit);
        
        (
            uint8 oldBackend,
            uint8 newBackend,
            uint256 storedOldCommit,
            uint256 storedNewCommit,
            uint256 timestamp,
            bool verified
        ) = morph.getMorphRecord(address(this), 0);
        
        assertEq(oldBackend, 0, "Old backend mismatch");
        assertEq(newBackend, 1, "New backend mismatch");
        assertEq(storedOldCommit, oldCommit, "Old commitment mismatch");
        assertEq(storedNewCommit, newCommit, "New commitment mismatch");
        assertTrue(timestamp > 0, "Timestamp should be set");
        assertFalse(verified, "Should not be verified");
    }
    
    // ==================== Valid Transition Tests ====================
    
    function testValidTransitionTracking() public {
        uint256 oldCommit = uint256(keccak256("tracking_old"));
        uint256 newCommit = uint256(keccak256("tracking_new"));
        uint256 morphIndex = morph.requestMorph(0, 1, oldCommit, newCommit);
        
        // Before verification
        assertFalse(
            morph.isValidTransition(0, 1, oldCommit, newCommit),
            "Should not be valid before verification"
        );
        
        // Verify
        bytes memory proofData = hex"aaaa";
        uint256[] memory inputs = new uint256[](1);
        inputs[0] = 111;
        bytes32 proofHash = bls12381.submitProof(proofData, inputs);
        bls12381.markVerified(proofHash, true);
        morph.verifyMorphBLS12381(morphIndex, proofHash);
        
        // After verification
        assertTrue(
            morph.isValidTransition(0, 1, oldCommit, newCommit),
            "Should be valid after verification"
        );
    }
}