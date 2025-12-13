// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title PassRegistry
 * @dev Registers pass purchases and verifies through NovaClassTicket
 * Creates transaction records on NovaClassTicket contract
 */

interface INovaClassTicket {
    function hasAccess(address user) external view returns (bool);
    function passExpiry(address user) external view returns (uint256);
    function getTimeRemaining(address user) external view returns (uint256);
    function myAccess() external view returns (bool);
    function buyPass() external payable;
}

contract PassRegistry {
    
    INovaClassTicket public novaTicket;
    address public admin;
    
    mapping(address => bool) public isRegistered;
    mapping(address => uint256) public registrationTime;
    mapping(address => uint256) public verificationCount;
    
    uint256 public totalRegistered;
    address[] public registeredUsers;
    
    event UserRegistered(address indexed user, uint256 timestamp);
    event PassVerified(address indexed user, uint256 count, uint256 expiry);
    event PassPurchasedViaRegistry(address indexed user, uint256 amount);
    
    error NotAdmin();
    error AlreadyRegistered();
    error NotRegistered();
    error NoActivePass();
    
    modifier onlyAdmin() {
        if (msg.sender != admin) revert NotAdmin();
        _;
    }
    
    constructor(address _novaTicket) {
        novaTicket = INovaClassTicket(_novaTicket);
        admin = msg.sender;
    }
    
    /// @notice Register by verifying your NovaClassTicket pass
    /// This calls NovaClassTicket contract creating a transaction record
    function registerWithPass() external {
        if (isRegistered[msg.sender]) revert AlreadyRegistered();
        
        // This creates a transaction to NovaClassTicket
        bool hasPass = novaTicket.hasAccess(msg.sender);
        if (!hasPass) revert NoActivePass();
        
        isRegistered[msg.sender] = true;
        registrationTime[msg.sender] = block.timestamp;
        registeredUsers.push(msg.sender);
        totalRegistered++;
        
        emit UserRegistered(msg.sender, block.timestamp);
        
        // Verify and record expiry
        _verifyPass();
    }
    
    /// @notice Verify your pass status (creates transaction to NovaClassTicket)
    function verifyMyPass() external {
        if (!isRegistered[msg.sender]) revert NotRegistered();
        _verifyPass();
    }
    
    /// @notice Buy pass through this contract (creates transaction to NovaClassTicket)
    function buyPassThroughRegistry() external payable {
        // This forwards the call to NovaClassTicket, creating a transaction record
        novaTicket.buyPass{value: msg.value}();
        
        emit PassPurchasedViaRegistry(msg.sender, msg.value);
        
        // Auto-register if not already registered
        if (!isRegistered[msg.sender]) {
            isRegistered[msg.sender] = true;
            registrationTime[msg.sender] = block.timestamp;
            registeredUsers.push(msg.sender);
            totalRegistered++;
            emit UserRegistered(msg.sender, block.timestamp);
        }
    }
    
    /// @notice Internal verification that interacts with NovaClassTicket
    function _verifyPass() internal {
        uint256 expiry = novaTicket.passExpiry(msg.sender);
        uint256 timeRemaining = novaTicket.getTimeRemaining(msg.sender);
        
        require(timeRemaining > 0, "Pass expired");
        
        verificationCount[msg.sender]++;
        emit PassVerified(msg.sender, verificationCount[msg.sender], expiry);
    }
    
    /// @notice Check registration status
    function getRegistrationInfo(address user) external view returns (
        bool registered,
        uint256 registeredAt,
        uint256 verifications,
        bool hasActivePass
    ) {
        registered = isRegistered[user];
        registeredAt = registrationTime[user];
        verifications = verificationCount[user];
        hasActivePass = novaTicket.hasAccess(user);
    }
    
    /// @notice Get all registered users
    function getAllRegistered() external view returns (address[] memory) {
        return registeredUsers;
    }
    
    // /// @notice Batch verify multiple users
    // function batchVerify(address[] memory users) external onlyAdmin {
    //     for (uint256 i = 0; i < users.length; i++) {
    //         if (isRegistered[users[i]]) {
    //             novaTicket.hasAccess(users[i]);
    //         }
    //     }
    // }
}