// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title AccessVault
 * @dev Stake ETH and earn yields - requires NovaClassTicket to withdraw
 */

interface INovaClassTicket {
    function hasAccess(address user) external view returns (bool);
}

contract AccessVault {
    
    INovaClassTicket public novaTicket;
    address public owner;
    
    // User deposits and rewards
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public depositTime;
    mapping(address => uint256) public lastRewardClaim;
    
    uint256 public totalDeposited;
    uint256 public yieldRate = 5; // 5% annual yield
    
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 reward);
    
    error NoAccess();
    error InsufficientBalance();
    error NotOwner();
    error TransferFailed();
    
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }
    
    constructor(address _novaTicket) {
        novaTicket = INovaClassTicket(_novaTicket);
        owner = msg.sender;
    }
    
    /// @notice Deposit ETH into vault
    function deposit() external payable {
        require(msg.value > 0, "Must deposit something");
        
        deposits[msg.sender] += msg.value;
        
        if (depositTime[msg.sender] == 0) {
            depositTime[msg.sender] = block.timestamp;
            lastRewardClaim[msg.sender] = block.timestamp;
        }
        
        totalDeposited += msg.value;
        emit Deposited(msg.sender, msg.value);
    }
    
    /// @notice Withdraw ETH - requires active NovaTicket
    function withdraw(uint256 amount) external {
        if (!novaTicket.hasAccess(msg.sender)) revert NoAccess();
        if (deposits[msg.sender] < amount) revert InsufficientBalance();
        
        deposits[msg.sender] -= amount;
        totalDeposited -= amount;
        
        (bool success, ) = msg.sender.call{value: amount}("");
        if (!success) revert TransferFailed();
        
        emit Withdrawn(msg.sender, amount);
    }
    
    /// @notice Claim yield rewards - requires active NovaTicket
    function claimRewards() external {
        if (!novaTicket.hasAccess(msg.sender)) revert NoAccess();
        
        uint256 reward = calculateRewards(msg.sender);
        require(reward > 0, "No rewards");
        require(address(this).balance >= reward, "Insufficient vault balance");
        
        lastRewardClaim[msg.sender] = block.timestamp;
        
        (bool success, ) = msg.sender.call{value: reward}("");
        if (!success) revert TransferFailed();
        
        emit RewardClaimed(msg.sender, reward);
    }
    
    /// @notice Calculate pending rewards
    function calculateRewards(address user) public view returns (uint256) {
        if (deposits[user] == 0) return 0;
        
        uint256 timeElapsed = block.timestamp - lastRewardClaim[user];
        uint256 annualReward = (deposits[user] * yieldRate) / 100;
        uint256 reward = (annualReward * timeElapsed) / 365 days;
        
        return reward;
    }
    
    /// @notice Get user vault info
    function getVaultInfo(address user) external view returns (
        uint256 deposited,
        uint256 pendingRewards,
        uint256 depositedAt,
        bool hasTicket
    ) {
        deposited = deposits[user];
        pendingRewards = calculateRewards(user);
        depositedAt = depositTime[user];
        hasTicket = novaTicket.hasAccess(user);
    }
    
    /// @notice Owner funds vault for rewards
    function fundVault() external payable onlyOwner {}
    
    /// @notice Update yield rate
    function updateYieldRate(uint256 newRate) external onlyOwner {
        require(newRate <= 20, "Rate too high");
        yieldRate = newRate;
    }
    
    receive() external payable {}
}