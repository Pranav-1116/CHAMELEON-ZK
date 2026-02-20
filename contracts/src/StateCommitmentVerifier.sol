// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

contract Groth16Verifier {
    // Scalar field size
    uint256 constant R = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    // Base field size
    uint256 constant Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    // Verification Key data
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
    uint256 constant DELTAX1 = 20011642593787562741024803200431116787516881848773504353608204196729167933638;
    uint256 constant DELTAX2 = 13695330142089677106930281387828808759910711462943415422540377951831984508277;
    uint256 constant DELTAY1 = 7139392294836373810618692743689670117867475318694731876563133484192266220132;
    uint256 constant DELTAY2 = 17199196656111121953236260392405906439495561628541193217780885873455422740659;

    uint256 constant IC0X = 17900397931105359580519429457443122203050934900613733247870453942639108132930;
    uint256 constant IC0Y = 3222321671969538322754996048025694003125544954305114219397441683270275563195;
    uint256 constant IC1X = 20790331858609206542749046130600370819634284564872271743394583603920916536408;
    uint256 constant IC1Y = 18022276457710464833264132683316229160882096455107208388360136321823156429358;
    uint256 constant IC2X = 21353317962560629614237958362781491376079440862393921048776964567629993169097;
    uint256 constant IC2Y = 16374975795657499939874725136010244680670901980368986722211042220927347660169;

    // Memory data
    uint16 constant P_VK = 0;
    uint16 constant P_PAIRING = 128;
    uint16 constant P_LAST_MEM = 896;

    function verifyProof(
        uint[2] calldata _pA,
        uint[2][2] calldata _pB,
        uint[2] calldata _pC,
        uint[2] calldata _pubSignals
    ) public view returns (bool) {
        assembly {
            function checkField(v) {
                if iszero(lt(v, R)) {
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
                let _pPairing := add(pMem, P_PAIRING)
                let _pVk := add(pMem, P_VK)

                mstore(_pVk, IC0X)
                mstore(add(_pVk, 32), IC0Y)

                g1_mulAccC(_pVk, IC1X, IC1Y, calldataload(add(pubSignals, 0)))
                g1_mulAccC(_pVk, IC2X, IC2Y, calldataload(add(pubSignals, 32)))

                mstore(_pPairing, calldataload(pA))
                mstore(add(_pPairing, 32), mod(sub(Q, calldataload(add(pA, 32))), Q))

                mstore(add(_pPairing, 192), ALPHAX)
                mstore(add(_pPairing, 224), ALPHAY)

                mstore(add(_pPairing, 256), BETAX1)
                mstore(add(_pPairing, 288), BETAX2)
                mstore(add(_pPairing, 320), BETAY1)
                mstore(add(_pPairing, 352), BETAY2)

                mstore(add(_pPairing, 448), GAMMAX1)
                mstore(add(_pPairing, 480), GAMMAX2)
                mstore(add(_pPairing, 512), GAMMAY1)
                mstore(add(_pPairing, 544), GAMMAY2)

                mstore(add(_pPairing, 640), DELTAX1)
                mstore(add(_pPairing, 672), DELTAX2)
                mstore(add(_pPairing, 704), DELTAY1)
                mstore(add(_pPairing, 736), DELTAY2)

                let success := staticcall(sub(gas(), 2000), 8, _pPairing, 768, _pPairing, 0x20)
                isOk := and(success, mload(_pPairing))
            }

            let pMem := mload(0x40)
            mstore(0x40, add(pMem, P_LAST_MEM))

            checkField(calldataload(add(_pubSignals, 0)))
            checkField(calldataload(add(_pubSignals, 32)))

            let isValid := checkPairing(_pA, _pB, _pC, _pubSignals, pMem)

            mstore(0, isValid)
            return(0, 0x20)
        }
    }
}
