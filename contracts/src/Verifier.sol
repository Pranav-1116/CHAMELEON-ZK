// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

/**
 * @title BN254Verifier
 * @dev Groth16 verifier for BN254 curve (snarkJS generated with fixes)
 */
contract BN254Verifier {
    uint256 constant r = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 constant q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    uint256 constant ALPHAX = 3050421639393894609694100247362469476301594184194208660243717647327937608084;
    uint256 constant ALPHAY = 10570968496776547372902278874938397270085925787545262165721065498216990788862;
    uint256 constant BETAX1 = 21691111980123012323298500290421361848112563758657263962991588788225312145784;
    uint256 constant BETAX2 = 4216856901912371297629069257509223183173062360485498483168636816601708818350;
    uint256 constant BETAY1 = 4563169662782910687268173125798006935932702707712370780282685207883966408839;
    uint256 constant BETAY2 = 20270793118337942609509108123032858522765806053947340581216635283059651491912;
    uint256 constant GAMMAX1 = 11559732032986387107991004021392285783925812861821192530917403151452391805634;
    uint256 constant GAMMAX2 = 10857046999023057135944570762232829481370756359578518086990519993285655852781;
    uint256 constant GAMMAY1 = 4082367875863433681332203403145435568316851327593401208105741076214120093531;
    uint256 constant GAMMAY2 = 8495653923123431417604973247489272438418190587263600148770280649306958101930;
    uint256 constant DELTAX1 = 20874980964143094135623922854570022626156669955062732526986654889779547832248;
    uint256 constant DELTAX2 = 6046163544548078367336746503902456865550635825766207144779786789587701417262;
    uint256 constant DELTAY1 = 9524552770720849850195376709657775885757432640209543521494379477564183489775;
    uint256 constant DELTAY2 = 20358128633723773430130897660989917223689769489365993412775997822896731664949;

    uint256 constant IC0X = 19056523035422553766169810774113510056228115729396250221924004438607807295577;
    uint256 constant IC0Y = 6434160209108400177800562827211006454556058350975302169262208679394730586200;
    uint256 constant IC1X = 15766417984046639306008178178341214666349758951770586385321701896318076289576;
    uint256 constant IC1Y = 20392683127530141134300194747978275271479714075031770559205351470005978195116;

    uint16 constant P_VK = 0;
    uint16 constant PPAIRING = 128;
    uint16 constant PLASTMEM = 896;

    function verifyProof(
        uint256[2] calldata _pA,
        uint256[2][2] calldata _pB,
        uint256[2] calldata _pC,
        uint256[1] calldata _pubSignals
    ) public view returns (bool) {
        assembly {
            function checkField(v) {
                if iszero(lt(v, r)) {
                    mstore(0, 0)
                    return(0, 0x20)
                }
            }

            function g1_mulAccC(pR, x, y, s) {
                let success
                let mIn := mload(0x40)
                mstore(mIn, x)
                mstore(add(mIn, 32), y)
                mstore(add(mIn, 64), s)

                success := staticcall(sub(gas(), 2000), 7, mIn, 96, mIn, 64)

                if iszero(success) {
                    mstore(0, 0)
                    return(0, 0x20)
                }

                mstore(add(mIn, 64), mload(pR))
                mstore(add(mIn, 96), mload(add(pR, 32)))

                success := staticcall(sub(gas(), 2000), 6, mIn, 128, pR, 64)

                if iszero(success) {
                    mstore(0, 0)
                    return(0, 0x20)
                }
            }

            function checkPairing(pA, pB, pC, pubSignals, pMem) -> isOk {
                let _PPAIRING := add(pMem, PPAIRING)
                let _P_VK := add(pMem, P_VK)

                mstore(_P_VK, IC0X)
                mstore(add(_P_VK, 32), IC0Y)

                g1_mulAccC(_P_VK, IC1X, IC1Y, calldataload(add(pubSignals, 0)))

                mstore(_PPAIRING, calldataload(pA))
                mstore(add(_PPAIRING, 32), mod(sub(q, calldataload(add(pA, 32))), q))

                mstore(add(_PPAIRING, 64), calldataload(pB))
                mstore(add(_PPAIRING, 96), calldataload(add(pB, 32)))
                mstore(add(_PPAIRING, 128), calldataload(add(pB, 64)))
                mstore(add(_PPAIRING, 160), calldataload(add(pB, 96)))

                mstore(add(_PPAIRING, 192), ALPHAX)
                mstore(add(_PPAIRING, 224), ALPHAY)

                mstore(add(_PPAIRING, 256), BETAX1)
                mstore(add(_PPAIRING, 288), BETAX2)
                mstore(add(_PPAIRING, 320), BETAY1)
                mstore(add(_PPAIRING, 352), BETAY2)

                mstore(add(_PPAIRING, 384), mload(add(pMem, P_VK)))
                mstore(add(_PPAIRING, 416), mload(add(pMem, add(P_VK, 32))))

                mstore(add(_PPAIRING, 448), GAMMAX1)
                mstore(add(_PPAIRING, 480), GAMMAX2)
                mstore(add(_PPAIRING, 512), GAMMAY1)
                mstore(add(_PPAIRING, 544), GAMMAY2)

                mstore(add(_PPAIRING, 576), calldataload(pC))
                mstore(add(_PPAIRING, 608), calldataload(add(pC, 32)))

                mstore(add(_PPAIRING, 640), DELTAX1)
                mstore(add(_PPAIRING, 672), DELTAX2)
                mstore(add(_PPAIRING, 704), DELTAY1)
                mstore(add(_PPAIRING, 736), DELTAY2)

                let success := staticcall(sub(gas(), 2000), 8, _PPAIRING, 768, _PPAIRING, 0x20)

                isOk := and(success, mload(_PPAIRING))
            }

            let pMem := mload(0x40)
            mstore(0x40, add(pMem, PLASTMEM))

            checkField(calldataload(add(_pubSignals, 0)))

            let isValid := checkPairing(_pA, _pB, _pC, _pubSignals, pMem)

            mstore(0, isValid)
            return(0, 0x20)
        }
    }
}

/**
 * @title BLS12381Verifier
 * @dev Placeholder verifier for BLS12-381 curve (no Ethereum precompiles yet)
 */
contract BLS12381Verifier {
    mapping(bytes32 => bool) public submittedProofs;
    mapping(bytes32 => bool) public verifiedProofs;

    event ProofSubmitted(address indexed sender, bytes32 proofHash);
    event ProofVerified(address indexed sender, bytes32 proofHash, bool valid);

    function submitProof(bytes calldata proofData, uint256[] calldata publicInputs) external returns (bytes32) {
        bytes32 proofHash = keccak256(abi.encode(proofData, publicInputs));
        submittedProofs[proofHash] = true;
        emit ProofSubmitted(msg.sender, proofHash);
        return proofHash;
    }

    function markVerified(bytes32 proofHash, bool valid) external {
        require(submittedProofs[proofHash], "Not submitted");
        verifiedProofs[proofHash] = valid;
        emit ProofVerified(msg.sender, proofHash, valid);
    }

    function isSubmitted(bytes32 proofHash) external view returns (bool) {
        return submittedProofs[proofHash];
    }

    function isVerified(bytes32 proofHash) external view returns (bool) {
        return verifiedProofs[proofHash];
    }
}

/**
 * @title UniversalVerifier
 * @dev Routes proofs to correct backend verifier
 */
contract LegacyUniversalVerifier {
    enum Backend {
        BN254,
        BLS12_381
    }

    BN254Verifier public bn254Verifier;
    BLS12381Verifier public bls12381Verifier;

    address public owner;
    uint256 public totalVerifications;
    uint256 public bn254Verifications;
    uint256 public bls12381Verifications;

    event ProofVerified(Backend indexed backend, address indexed sender, bool valid);

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _onlyOwner() internal view {
        require(msg.sender == owner, "Not Owner");
    }

    constructor() {
        owner = msg.sender;
        bn254Verifier = new BN254Verifier();
        bls12381Verifier = new BLS12381Verifier();
    }

    function verifyBN254(
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c,
        uint256[1] calldata publicInputs
    ) external returns (bool valid) {
        valid = bn254Verifier.verifyProof(a, b, c, publicInputs);
        totalVerifications++;
        bn254Verifications++;
        emit ProofVerified(Backend.BN254, msg.sender, valid);
        return valid;
    }

    function submitBLS12381(bytes calldata proofData, uint256[] calldata publicInputs) external returns (bytes32) {
        bytes32 proofHash = bls12381Verifier.submitProof(proofData, publicInputs);
        totalVerifications++;
        bls12381Verifications++;
        emit ProofVerified(Backend.BLS12_381, msg.sender, false);
        return proofHash;
    }

    function getStats() external view returns (uint256 total, uint256 bn254Count, uint256 bls12381Count) {
        return (totalVerifications, bn254Verifications, bls12381Verifications);
    }
}

/**
 * @title MorphVerifier
 * @dev Validates backend transitions with proof verification
 */
contract MorphVerifier {
    struct MorphRecord {
        uint8 oldBackend;
        uint8 newBackend;
        uint256 oldCommitment;
        uint256 newCommitment;
        uint256 timestamp;
        bool verified;
    }

    BN254Verifier public bn254Verifier;
    BLS12381Verifier public bls12381Verifier;

    mapping(address => MorphRecord[]) public morphHistory;
    mapping(bytes32 => bool) public validTransitions;

    uint256 public totalMorphs;
    uint256 public successfulMorphs;

    event MorphRequested(address indexed user, uint8 oldBackend, uint8 newBackend, uint256 morphIndex);

    event MorphVerified(address indexed user, uint256 morphIndex, bool valid);

    constructor(address _bn254Verifier, address _bls12381Verifier) {
        bn254Verifier = BN254Verifier(_bn254Verifier);
        bls12381Verifier = BLS12381Verifier(_bls12381Verifier);
    }

    function requestMorph(uint8 oldBackend, uint8 newBackend, uint256 oldCommitment, uint256 newCommitment)
        external
        returns (uint256)
    {
        require(oldBackend != newBackend, "Same backend");
        require(oldBackend <= 1 && newBackend <= 1, "Invalid backend");

        MorphRecord memory record = MorphRecord({
            oldBackend: oldBackend,
            newBackend: newBackend,
            oldCommitment: oldCommitment,
            newCommitment: newCommitment,
            timestamp: block.timestamp,
            verified: false
        });

        morphHistory[msg.sender].push(record);
        uint256 morphIndex = morphHistory[msg.sender].length - 1;
        totalMorphs++;

        emit MorphRequested(msg.sender, oldBackend, newBackend, morphIndex);
        return morphIndex;
    }

    function verifyMorphBN254(
        uint256 morphIndex,
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c,
        uint256[1] calldata publicInputs
    ) external returns (bool) {
        require(morphIndex < morphHistory[msg.sender].length, "Invalid index");

        MorphRecord storage record = morphHistory[msg.sender][morphIndex];
        require(!record.verified, "Already verified");

        bool valid = bn254Verifier.verifyProof(a, b, c, publicInputs);

        if (valid) {
            record.verified = true;
            successfulMorphs++;
            // forge-lint: disable-next-line(asm-keccak256)
            bytes32 transitionHash =
                keccak256(abi.encode(record.oldBackend, record.newBackend, record.oldCommitment, record.newCommitment));
            validTransitions[transitionHash] = true;
        }

        emit MorphVerified(msg.sender, morphIndex, valid);
        return valid;
    }

    function verifyMorphBLS12381(uint256 morphIndex, bytes32 proofHash) external returns (bool) {
        require(morphIndex < morphHistory[msg.sender].length, "Invalid index");

        MorphRecord storage record = morphHistory[msg.sender][morphIndex];
        require(!record.verified, "Already verified");

        bool valid = bls12381Verifier.isVerified(proofHash);

        if (valid) {
            record.verified = true;
            successfulMorphs++;
            // forge-lint: disable-next-line(asm-keccak256)
            bytes32 transitionHash =
                keccak256(abi.encode(record.oldBackend, record.newBackend, record.oldCommitment, record.newCommitment));
            validTransitions[transitionHash] = true;
        }

        emit MorphVerified(msg.sender, morphIndex, valid);
        return valid;
    }

    function getMorphCount(address user) external view returns (uint256) {
        return morphHistory[user].length;
    }

    function getMorphRecord(address user, uint256 index)
        external
        view
        returns (
            uint8 oldBackend,
            uint8 newBackend,
            uint256 oldCommitment,
            uint256 newCommitment,
            uint256 timestamp,
            bool verified
        )
    {
        require(index < morphHistory[user].length, "Invalid index");
        MorphRecord memory record = morphHistory[user][index];
        return (
            record.oldBackend,
            record.newBackend,
            record.oldCommitment,
            record.newCommitment,
            record.timestamp,
            record.verified
        );
    }

    function isValidTransition(uint8 oldBackend, uint8 newBackend, uint256 oldCommitment, uint256 newCommitment)
        external
        view
        returns (bool)
    {
        // forge-lint: disable-next-line(asm-keccak256)
        bytes32 transitionHash = keccak256(abi.encode(oldBackend, newBackend, oldCommitment, newCommitment));
        return validTransitions[transitionHash];
    }

    function getStats() external view returns (uint256 total, uint256 successful) {
        return (totalMorphs, successfulMorphs);
    }
}
