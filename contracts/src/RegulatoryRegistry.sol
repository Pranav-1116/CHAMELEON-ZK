// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title RegulatoryRegistry
 * @notice On-chain registry mapping jurisdictions to approved cryptographic curves
 */
contract RegulatoryRegistry {
    struct JurisdictionConfig {
        string name;
        string regionCode;
        bool isActive;
        uint8[] approvedBackends;
        uint8 preferredBackend;
        string regulatoryBody;
        string complianceStandard;
        uint256 lastUpdated;
    }

    struct CurveInfo {
        uint8 backendId;
        string curveName;
        string standardRef;
        bool isApproved;
        uint8 securityLevel;
    }

    address public owner;
    mapping(bytes32 => JurisdictionConfig) public jurisdictions;
    bytes32[] public jurisdictionKeys;
    mapping(uint8 => CurveInfo) public curves;
    uint8 public curveCount;
    bytes32 public activeJurisdiction;

    event JurisdictionAdded(string regionCode, string name);
    event JurisdictionUpdated(string regionCode);
    event ActiveJurisdictionChanged(string regionCode);
    event CurveRegistered(uint8 backendId, string curveName);

    constructor() {
        owner = msg.sender;
        _registerCurve(0, "BN254", "alt_bn128", 100);
        _registerCurve(1, "BLS12-381", "BLS12-381", 128);
        _registerCurve(2, "P-256", "NIST P-256 / secp256r1", 128);
        _registerCurve(3, "SM2", "GM/T 0003-2012", 128);
        _registerCurve(4, "Curve25519", "RFC 7748", 128);
        _addDefaultJurisdictions();
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _onlyOwner() internal view {
        require(msg.sender == owner, "Not owner");
    }

    function _registerCurve(uint8 _backendId, string memory _name, string memory _standardRef, uint8 _securityLevel)
        internal
    {
        curves[_backendId] = CurveInfo({
            backendId: _backendId,
            curveName: _name,
            standardRef: _standardRef,
            isApproved: true,
            securityLevel: _securityLevel
        });
        curveCount++;
        emit CurveRegistered(_backendId, _name);
    }

    function _addDefaultJurisdictions() internal {
        uint8[] memory usBackends = new uint8[](3);
        usBackends[0] = 0;
        usBackends[1] = 1;
        usBackends[2] = 2;
        _addJurisdiction("US", "United States", usBackends, 2, "NIST", "FIPS 140-3");

        uint8[] memory euBackends = new uint8[](3);
        euBackends[0] = 0;
        euBackends[1] = 1;
        euBackends[2] = 4;
        _addJurisdiction("EU", "European Union", euBackends, 1, "ENISA", "eIDAS");

        uint8[] memory cnBackends = new uint8[](1);
        cnBackends[0] = 3;
        _addJurisdiction("CN", "China", cnBackends, 3, "OSCCA", "GM/T 0003");

        uint8[] memory sgBackends = new uint8[](4);
        sgBackends[0] = 0;
        sgBackends[1] = 1;
        sgBackends[2] = 2;
        sgBackends[3] = 4;
        _addJurisdiction("SG", "Singapore", sgBackends, 0, "MAS", "MAS TRM");

        uint8[] memory globalBackends = new uint8[](5);
        globalBackends[0] = 0;
        globalBackends[1] = 1;
        globalBackends[2] = 2;
        globalBackends[3] = 3;
        globalBackends[4] = 4;
        _addJurisdiction("GLOBAL", "Global (No Restriction)", globalBackends, 0, "None", "None");

        activeJurisdiction = keccak256(abi.encodePacked("GLOBAL"));
    }

    function _addJurisdiction(
        string memory _regionCode,
        string memory _name,
        uint8[] memory _approvedBackends,
        uint8 _preferredBackend,
        string memory _regulatoryBody,
        string memory _complianceStandard
    ) internal {
        bytes32 key = keccak256(abi.encodePacked(_regionCode));
        jurisdictions[key] = JurisdictionConfig({
            name: _name,
            regionCode: _regionCode,
            isActive: true,
            approvedBackends: _approvedBackends,
            preferredBackend: _preferredBackend,
            regulatoryBody: _regulatoryBody,
            complianceStandard: _complianceStandard,
            lastUpdated: block.timestamp
        });
        jurisdictionKeys.push(key);
        emit JurisdictionAdded(_regionCode, _name);
    }

    function setActiveJurisdiction(string calldata _regionCode) external onlyOwner {
        bytes32 key = keccak256(abi.encode(_regionCode));
        require(jurisdictions[key].isActive, "Jurisdiction not found");
        activeJurisdiction = key;
        emit ActiveJurisdictionChanged(_regionCode);
    }

    function isBackendApproved(uint8 _backendId) external view returns (bool) {
        JurisdictionConfig storage config = jurisdictions[activeJurisdiction];
        for (uint256 i = 0; i < config.approvedBackends.length; i++) {
            if (config.approvedBackends[i] == _backendId) return true;
        }
        return false;
    }

    function getPreferredBackend() external view returns (uint8) {
        return jurisdictions[activeJurisdiction].preferredBackend;
    }

    function getActiveJurisdictionName() external view returns (string memory) {
        return jurisdictions[activeJurisdiction].name;
    }

    function getActiveRegulatoryBody() external view returns (string memory) {
        return jurisdictions[activeJurisdiction].regulatoryBody;
    }

    function getActiveComplianceStandard() external view returns (string memory) {
        return jurisdictions[activeJurisdiction].complianceStandard;
    }

    function getApprovedBackends() external view returns (uint8[] memory) {
        return jurisdictions[activeJurisdiction].approvedBackends;
    }

    function getCurveName(uint8 _backendId) external view returns (string memory) {
        return curves[_backendId].curveName;
    }

    function getJurisdictionCount() external view returns (uint256) {
        return jurisdictionKeys.length;
    }

    function addJurisdiction(
        string calldata _regionCode,
        string calldata _name,
        uint8[] calldata _approvedBackends,
        uint8 _preferredBackend,
        string calldata _regulatoryBody,
        string calldata _complianceStandard
    ) external onlyOwner {
        _addJurisdiction(_regionCode, _name, _approvedBackends, _preferredBackend, _regulatoryBody, _complianceStandard);
    }

    function getJurisdictionDetails(string calldata _regionCode)
        external
        view
        returns (
            string memory name,
            bool isActive,
            uint8 preferredBackend,
            string memory regulatoryBody,
            string memory complianceStandard
        )
    {
        // forge-lint: disable-next-line(asm-keccak256)
        bytes32 key = keccak256(abi.encode(_regionCode));
        JurisdictionConfig storage config = jurisdictions[key];
        return (config.name, config.isActive, config.preferredBackend, config.regulatoryBody, config.complianceStandard);
    }
}
