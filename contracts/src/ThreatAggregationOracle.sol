// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title CryptoHealthOracle
 * @notice On-chain oracle for cryptographic health monitoring
 * @dev Accepts threat scores from authorized reporters and aggregates them
 *      into a unified threat assessment for the Chameleon-ZK system
 */
contract CryptoHealthOracle {

    enum ThreatCategory {
        CRYPTOGRAPHIC_WEAKNESS,
        IMPLEMENTATION_VULN,
        REGULATORY_CHANGE,
        NETWORK_ATTACK,
        HARDWARE_COMPROMISE
    }

    struct ThreatReport {
        address reporter;
        ThreatCategory category;
        uint8 score;
        uint256 timestamp;
        string description;
    }

    struct AggregatedThreat {
        uint8 averageScore;
        uint8 maxScore;
        uint8 reportCount;
        uint256 lastUpdated;
    }

    address public owner;
    mapping(address => bool) public isReporter;
    address[] public reporters;
    mapping(ThreatCategory => mapping(address => ThreatReport)) public latestReports;
    mapping(ThreatCategory => AggregatedThreat) public aggregatedThreats;
    uint8 public overallThreatScore;
    mapping(ThreatCategory => uint8) public categoryWeights;
    uint8[] public scoreHistory;
    uint256[] public scoreTimestamps;
    uint8 public morphThreshold;
    uint256 public reportCooldown;

    event ReporterAdded(address indexed reporter);
    event ReporterRemoved(address indexed reporter);
    event ThreatReported(
        address indexed reporter,
        ThreatCategory indexed category,
        uint8 score,
        string description
    );
    event OverallScoreUpdated(uint8 newScore, uint256 timestamp);
    event MorphRecommended(uint8 score, string reason);

    constructor(uint8 _morphThreshold) {
        owner = msg.sender;
        morphThreshold = _morphThreshold;
        reportCooldown = 0;
        categoryWeights[ThreatCategory.CRYPTOGRAPHIC_WEAKNESS] = 35;
        categoryWeights[ThreatCategory.IMPLEMENTATION_VULN] = 25;
        categoryWeights[ThreatCategory.REGULATORY_CHANGE] = 20;
        categoryWeights[ThreatCategory.NETWORK_ATTACK] = 15;
        categoryWeights[ThreatCategory.HARDWARE_COMPROMISE] = 5;
        isReporter[msg.sender] = true;
        reporters.push(msg.sender);
    }

    modifier onlyOwner() {
       _onlyOwner();
        _;
    }
    function _onlyOwner () internal view {
         require(msg.sender == owner, "Not owner");
    }

    modifier onlyReporter() {
       _onlyRepoter();
        _;
    }
 function _onlyRepoter () internal view {
     require(isReporter[msg.sender], "Not authorized reporter");
 }
    function addReporter(address _reporter) external onlyOwner {
        require(!isReporter[_reporter], "Already a reporter");
        isReporter[_reporter] = true;
        reporters.push(_reporter);
        emit ReporterAdded(_reporter);
    }

    function removeReporter(address _reporter) external onlyOwner {
        require(isReporter[_reporter], "Not a reporter");
        require(_reporter != owner, "Cannot remove owner");
        isReporter[_reporter] = false;
        emit ReporterRemoved(_reporter);
    }

    function getReporterCount() external view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < reporters.length; i++) {
            if (isReporter[reporters[i]]) count++;
        }
        return count;
    }

    function reportThreat(
        ThreatCategory _category,
        uint8 _score,
        string calldata _description
    ) external onlyReporter {
        require(_score <= 100, "Score must be 0-100");
        ThreatReport storage existing = latestReports[_category][msg.sender];
        if (existing.timestamp > 0) {
            require(
                block.timestamp >= existing.timestamp + reportCooldown,
                "Report cooldown active"
            );
        }
        latestReports[_category][msg.sender] = ThreatReport({
            reporter: msg.sender,
            category: _category,
            score: _score,
            timestamp: block.timestamp,
            description: _description
        });
        emit ThreatReported(msg.sender, _category, _score, _description);
        _aggregateCategory(_category);
        _calculateOverallScore();
    }

    function reportMultipleThreats(
        ThreatCategory[] calldata _categories,
        uint8[] calldata _scores,
        string[] calldata _descriptions
    ) external onlyReporter {
        require(
            _categories.length == _scores.length &&
            _scores.length == _descriptions.length,
            "Array length mismatch"
        );
        for (uint256 i = 0; i < _categories.length; i++) {
            require(_scores[i] <= 100, "Score must be 0-100");
            latestReports[_categories[i]][msg.sender] = ThreatReport({
                reporter: msg.sender,
                category: _categories[i],
                score: _scores[i],
                timestamp: block.timestamp,
                description: _descriptions[i]
            });
            emit ThreatReported(msg.sender, _categories[i], _scores[i], _descriptions[i]);
            _aggregateCategory(_categories[i]);
        }
        _calculateOverallScore();
    }

    function _aggregateCategory(ThreatCategory _category) internal {
        uint256 totalScore = 0;
        uint8 maxScore = 0;
        uint8 reportCount = 0;
        for (uint256 i = 0; i < reporters.length; i++) {
            if (!isReporter[reporters[i]]) continue;
            ThreatReport storage report = latestReports[_category][reporters[i]];
            if (report.timestamp == 0) continue;
            totalScore += report.score;
            if (report.score > maxScore) maxScore = report.score;
            reportCount++;
        }
        // casting to uint8 is safe because score is capped at 100
        // forge-lint: disable-next-line(unsafe-typecast)
        uint8 avgScore = reportCount > 0 ? uint8(totalScore / reportCount) : 0;
        aggregatedThreats[_category] = AggregatedThreat({
            averageScore: avgScore,
            maxScore: maxScore,
            reportCount: reportCount,
            lastUpdated: block.timestamp
        });
    }

    function _calculateOverallScore() internal {
        uint256 weightedSum = 0;
        for (uint8 i = 0; i < 5; i++) {
            ThreatCategory cat = ThreatCategory(i);
            uint256 catScore = aggregatedThreats[cat].averageScore;
            uint256 weight = categoryWeights[cat];
            weightedSum += catScore * weight;
        }
        // casting to uint8 is safe because score is bounded to 0–100
// forge-lint: disable-next-line(unsafe-typecast)
        overallThreatScore = uint8(weightedSum / 100);
        scoreHistory.push(overallThreatScore);
        scoreTimestamps.push(block.timestamp);
        emit OverallScoreUpdated(overallThreatScore, block.timestamp);
        if (overallThreatScore >= morphThreshold) {
            emit MorphRecommended(overallThreatScore, "Threat score exceeds morph threshold");
        }
    }

    function isMorphRecommended() external view returns (bool) {
        return overallThreatScore >= morphThreshold;
    }

    function getRecommendedBackend() external view returns (uint8 backendId) {
        if (overallThreatScore >= morphThreshold) return 1;
        return 0;
    }

    function getRecommendedBackendName() external view returns (string memory) {
        if (overallThreatScore >= morphThreshold) return "BLS12-381";
        return "BN254";
    }

    function getThreatLevelString() external view returns (string memory) {
        if (overallThreatScore >= 75) return "CRITICAL";
        if (overallThreatScore >= 50) return "HIGH";
        if (overallThreatScore >= 25) return "MEDIUM";
        return "LOW";
    }

    function getAllCategoryScores() external view returns (
        uint8 cryptographic,
        uint8 implementation,
        uint8 regulatory,
        uint8 networkAttack,
        uint8 hardware
    ) {
        cryptographic = aggregatedThreats[ThreatCategory.CRYPTOGRAPHIC_WEAKNESS].averageScore;
        implementation = aggregatedThreats[ThreatCategory.IMPLEMENTATION_VULN].averageScore;
        regulatory = aggregatedThreats[ThreatCategory.REGULATORY_CHANGE].averageScore;
        networkAttack = aggregatedThreats[ThreatCategory.NETWORK_ATTACK].averageScore;
        hardware = aggregatedThreats[ThreatCategory.HARDWARE_COMPROMISE].averageScore;
    }

    function getScoreHistoryLength() external view returns (uint256) {
        return scoreHistory.length;
    }

    function getHistoricalScore(uint256 index) external view returns (uint8 score, uint256 timestamp) {
        require(index < scoreHistory.length, "Index out of bounds");
        return (scoreHistory[index], scoreTimestamps[index]);
    }

    function getReport(
        ThreatCategory _category,
        address _reporter
    ) external view returns (
        uint8 score,
        uint256 timestamp,
        string memory description
    ) {
        ThreatReport storage report = latestReports[_category][_reporter];
        return (report.score, report.timestamp, report.description);
    }

    function updateMorphThreshold(uint8 _newThreshold) external onlyOwner {
        require(_newThreshold <= 100, "Threshold must be 0-100");
        morphThreshold = _newThreshold;
    }

    function updateCategoryWeight(ThreatCategory _category, uint8 _weight) external onlyOwner {
        categoryWeights[_category] = _weight;
    }

    function updateReportCooldown(uint256 _cooldown) external onlyOwner {
        reportCooldown = _cooldown;
    }

    function emergencyReset() external onlyOwner {
        for (uint8 i = 0; i < 5; i++) {
            ThreatCategory cat = ThreatCategory(i);
            aggregatedThreats[cat] = AggregatedThreat({
                averageScore: 0,
                maxScore: 0,
                reportCount: 0,
                lastUpdated: block.timestamp
            });
        }
        overallThreatScore = 0;
        scoreHistory.push(0);
        scoreTimestamps.push(block.timestamp);
        emit OverallScoreUpdated(0, block.timestamp);
    }
}