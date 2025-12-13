// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title ActivityTracker
 * @dev Tracks user activity streaks based on NovaClassTicket access
 */

interface INovaClassTicket {
    function hasAccess(address user) external view returns (bool);
    function passExpiry(address user) external view returns (uint256);
}

contract ActivityTracker {
    
    INovaClassTicket public novaTicket;
    address public owner;
    
    // Track user activity
    mapping(address => uint256) public lastCheckIn;
    mapping(address => uint256) public streakCount;
    mapping(address => uint256) public totalCheckIns;
    
    uint256 public streakWindow = 1 days;
    
    event CheckedIn(address indexed user, uint256 streak, uint256 timestamp);
    event StreakLost(address indexed user);
    
    error NoAccess();
    error TooEarly();
    error NotOwner();
    
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }
    
    constructor(address _novaTicket) {
        novaTicket = INovaClassTicket(_novaTicket);
        owner = msg.sender;
    }
    
    /// @notice Check in to maintain streak - requires active NovaTicket
    function checkIn() external {
        if (!novaTicket.hasAccess(msg.sender)) revert NoAccess();
        
        uint256 timeSinceLastCheckIn = block.timestamp - lastCheckIn[msg.sender];
        
        // First check-in ever
        if (lastCheckIn[msg.sender] == 0) {
            streakCount[msg.sender] = 1;
        }
        // Too early to check in again
        else if (timeSinceLastCheckIn < streakWindow) {
            revert TooEarly();
        }
        // Within streak window
        else if (timeSinceLastCheckIn <= streakWindow * 2) {
            streakCount[msg.sender]++;
        }
        // Streak broken, restart
        else {
            emit StreakLost(msg.sender);
            streakCount[msg.sender] = 1;
        }
        
        lastCheckIn[msg.sender] = block.timestamp;
        totalCheckIns[msg.sender]++;
        
        emit CheckedIn(msg.sender, streakCount[msg.sender], block.timestamp);
    }
    
    /// @notice Get user's current streak status
    function getStreakStatus(address user) external view returns (
        uint256 currentStreak,
        uint256 lastCheck,
        uint256 totalChecks,
        bool isActive,
        bool hasTicket
    ) {
        currentStreak = streakCount[user];
        lastCheck = lastCheckIn[user];
        totalChecks = totalCheckIns[user];
        
        uint256 timeSince = block.timestamp - lastCheck;
        isActive = (timeSince <= streakWindow * 2) && (lastCheck != 0);
        hasTicket = novaTicket.hasAccess(user);
    }
    
    /// @notice Leaderboard: Get top streak holders
    function getTopStreaks(address[] memory users) external view returns (
        address[] memory topUsers,
        uint256[] memory topStreaks
    ) {
        topUsers = new address[](users.length);
        topStreaks = new uint256[](users.length);
        
        for (uint256 i = 0; i < users.length; i++) {
            topUsers[i] = users[i];
            topStreaks[i] = streakCount[users[i]];
        }
        
        return (topUsers, topStreaks);
    }
    
    /// @notice Update streak window
    function updateStreakWindow(uint256 _hours) external onlyOwner {
        streakWindow = _hours * 1 hours;
    }
}