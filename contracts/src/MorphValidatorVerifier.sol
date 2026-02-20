// SPDX-License-Identifier: GPL-3.0
/*
    Copyright 2026 0KIMS association.
    This file is generated with [snarkJS](https://github.com/iden3/snarkjs).

    snarkJS is a free software: you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    snarkJS is distributed in the hope that it will be useful, but WITHOUT
    ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public
    License for more details.

    You should have received a copy of the GNU General Public License
    along with snarkJS. If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity >=0.7.0 <0.9.0;

contract Groth16Verifier {
    // Scalar field size
    uint256 constant r    = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    // Base field size
    uint256 constant q   = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    // Verification Key data
    uint256 constant ALPHAX  = 3050421639393894609694100247362469476301594184194208660243717647327937608084;
    uint256 constant ALPHAY  = 10570968496776547372902278874938397270085925787545262165721065498216990788862;
    uint256 constant BETAX1  = 21691111980123012323298500290421361848112563758657263962991588788225312145784;
    uint256 constant BETAX2  = 4216856901912371297629069257509223183173062360485498483168636816601708818350;
    uint256 constant BETAY1  = 4563169662782910687268173125798006935932702707712370780282685207883966408839;
    uint256 constant BETAY2  = 20270793118337942609509108123032858522765806053947340581216635283059651491912;
    uint256 constant GAMMAX1 = 11559732032986387107991004021392285783925812861821192530917403151452391805634;
    uint256 constant GAMMAX2 = 10857046999023057135944570762232829481370756359578518086990519993285655852781;
    uint256 constant GAMMAY1 = 4082367875863433681332203403145435568316851327593401208105741076214120093531;
    uint256 constant GAMMAY2 = 8495653923123431417604973247489272438418190587263600148770280649306958101930;
    uint256 constant DELTAX1 = 8015758070419226651652001523312074173757953150230852725787698684642522182879;
    uint256 constant DELTAX2 = 17280718934443988503302136588059884394573383471380985923379518187472764502850;
    uint256 constant DELTAY1 = 17940180404375462993749773111150630102443424426314010844370940044289770093360;
    uint256 constant DELTAY2 = 21221829802419819553697275816550557864537352963471280606040202401359281973141;

    
    uint256 constant IC0X = 4330896101261327931562894222304268907005630367277661418240976629349999434;
    uint256 constant IC0Y = 19997158488710195389006109539486318001138730795830822891269578160878833292296;
    
    uint256 constant IC1X = 5884790233945144456835786709185480620191886079201270112598989400779947080097;
    uint256 constant IC1Y = 7753638646293425949442237084470669943195647866179890881666447434852366108174;
    
    uint256 constant IC2X = 3111468173117182385088039053307551782915738539700109360203239853912727799418;
    uint256 constant IC2Y = 1215203918928959422692924005958635099664657458128909371858839425066204742317;
    
    uint256 constant IC3X = 2297451708450523864156881426943996729308355969589882314526557016000994226674;
    uint256 constant IC3Y = 3678370412405661836157728963973702620532096259993717115138320768283660304490;
    
    uint256 constant IC4X = 387256210787584577913315239850335881940610232554516473662530369917182383073;
    uint256 constant IC4Y = 5834205663288724696918314961286589077794243120413574472177033587451436867947;
    
 
    // Memory data
    uint16 constant PVK = 0;
    uint16 constant PPAIRING = 128;

    uint16 constant PLASTMEM = 896;

    function verifyProof(uint[2] calldata _pA, uint[2][2] calldata _pB, uint[2] calldata _pC, uint[4] calldata _pubSignals) public view returns (bool) {
        assembly {
            function checkField(v) {
                if iszero(lt(v, r)) {
                    mstore(0, 0)
                    return(0, 0x20)
                }
            }
            
            // G1 function to multiply a G1 value(x,y) to value in an address
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
                let _pPairing := add(pMem, PPAIRING)
                let _pVk := add(pMem, PVK)

                mstore(_pVk, IC0X)
                mstore(add(_pVk, 32), IC0Y)

                // Compute the linear combination vk_x
                
                g1_mulAccC(_pVk, IC1X, IC1Y, calldataload(add(pubSignals, 0)))
                
                g1_mulAccC(_pVk, IC2X, IC2Y, calldataload(add(pubSignals, 32)))
                
                g1_mulAccC(_pVk, IC3X, IC3Y, calldataload(add(pubSignals, 64)))
                
                g1_mulAccC(_pVk, IC4X, IC4Y, calldataload(add(pubSignals, 96)))
                

                // -A
                mstore(_pPairing, calldataload(pA))
                mstore(add(_pPairing, 32), mod(sub(q, calldataload(add(pA, 32))), q))

                // B
                mstore(add(_pPairing, 64), calldataload(pB))
                mstore(add(_pPairing, 96), calldataload(add(pB, 32)))
                mstore(add(_pPairing, 128), calldataload(add(pB, 64)))
                mstore(add(_pPairing, 160), calldataload(add(pB, 96)))

                // alpha1
                mstore(add(_pPairing, 192), ALPHAX)
                mstore(add(_pPairing, 224), ALPHAY)

                // beta2
                mstore(add(_pPairing, 256), BETAX1)
                mstore(add(_pPairing, 288), BETAX2)
                mstore(add(_pPairing, 320), BETAY1)
                mstore(add(_pPairing, 352), BETAY2)

                // vk_x
                mstore(add(_pPairing, 384), mload(add(pMem, PVK)))
                mstore(add(_pPairing, 416), mload(add(pMem, add(PVK, 32))))


                // gamma2
                mstore(add(_pPairing, 448), GAMMAX1)
                mstore(add(_pPairing, 480), GAMMAX2)
                mstore(add(_pPairing, 512), GAMMAY1)
                mstore(add(_pPairing, 544), GAMMAY2)

                // C
                mstore(add(_pPairing, 576), calldataload(pC))
                mstore(add(_pPairing, 608), calldataload(add(pC, 32)))

                // delta2
                mstore(add(_pPairing, 640), DELTAX1)
                mstore(add(_pPairing, 672), DELTAX2)
                mstore(add(_pPairing, 704), DELTAY1)
                mstore(add(_pPairing, 736), DELTAY2)


                let success := staticcall(sub(gas(), 2000), 8, _pPairing, 768, _pPairing, 0x20)

                isOk := and(success, mload(_pPairing))
            }

            let pMem := mload(0x40)
            mstore(0x40, add(pMem, PLASTMEM))

            // Validate that all evaluations ∈ F
            
            checkField(calldataload(add(_pubSignals, 0)))
            
            checkField(calldataload(add(_pubSignals, 32)))
            
            checkField(calldataload(add(_pubSignals, 64)))
            
            checkField(calldataload(add(_pubSignals, 96)))
            

            // Validate all evaluations
            let isValid := checkPairing(_pA, _pB, _pC, _pubSignals, pMem)

            mstore(0, isValid)
             return(0, 0x20)
         }
     }
 }
