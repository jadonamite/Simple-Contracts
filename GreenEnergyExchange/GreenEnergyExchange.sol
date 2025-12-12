// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title GreenEnergyExchange
 * @dev Trade, sell, and donate carbon credits from renewable energy production
 * 1 Credit = 1 kWh of green energy produced
 */
contract GreenEnergyExchange {
    
    struct CreditListing {
        address seller;
        uint256 amount;
        uint256 pricePerCredit; // in wei
        bool active;
    }
    
    struct Producer {
        string name;
        uint256 totalProduced;
        uint256 totalDonated;
        bool verified;
    }
    
    // State variables
    mapping(address => uint256) public creditBalance;
    mapping(address => Producer) public producers;
    mapping(uint256 => CreditListing) public listings;
    
    uint256 public listingCounter;
    uint256 public totalCreditsIssued;
    uint256 public totalCreditsDonated;
    address public admin;
    
    // Events
    event CreditsIssued(address indexed producer, uint256 amount, string reason);
    event ListingCreated(uint256 indexed listingId, address seller, uint256 amount, uint256 price);
    event CreditsSold(uint256 indexed listingId, address buyer, uint256 amount);
    event CreditsDonated(address indexed donor, address indexed recipient, uint256 amount);
    event ProducerRegistered(address indexed producer, string name);
    
    constructor() {
        admin = msg.sender;
    }
    
    /**
     * @dev Register as a green energy producer
     */
    function registerProducer(string memory _name) public {
        require(bytes(producers[msg.sender].name).length == 0, "Already registered");
        
        producers[msg.sender] = Producer({
            name: _name,
            totalProduced: 0,
            totalDonated: 0,
            verified: false
        });
        
        emit ProducerRegistered(msg.sender, _name);
    }
    
    /**
     * @dev Admin verifies a producer (in real app, would require proof)
     */
    function verifyProducer(address _producer) public {
        require(msg.sender == admin, "Only admin");
        producers[_producer].verified = true;
    }
    
    /**
     * @dev Issue carbon credits for green energy production
     * @param _kwh Amount of kWh produced
     */
    function issueCredits(uint256 _kwh, string memory _source) public {
        require(producers[msg.sender].verified, "Not a verified producer");
        require(_kwh > 0, "Amount must be positive");
        
        creditBalance[msg.sender] += _kwh;
        producers[msg.sender].totalProduced += _kwh;
        totalCreditsIssued += _kwh;
        
        emit CreditsIssued(msg.sender, _kwh, _source);
    }
    
    /**
     * @dev Create a listing to sell credits
     */
    function createListing(uint256 _amount, uint256 _pricePerCredit) public {
        require(creditBalance[msg.sender] >= _amount, "Insufficient credits");
        require(_amount > 0, "Amount must be positive");
        
        creditBalance[msg.sender] -= _amount;
        
        listings[listingCounter] = CreditListing({
            seller: msg.sender,
            amount: _amount,
            pricePerCredit: _pricePerCredit,
            active: true
        });
        
        emit ListingCreated(listingCounter, msg.sender, _amount, _pricePerCredit);
        listingCounter++;
    }
    
    /**
     * @dev Buy credits from a listing
     */
    function buyCredits(uint256 _listingId, uint256 _amount) public payable {
        CreditListing storage listing = listings[_listingId];
        require(listing.active, "Listing not active");
        require(_amount <= listing.amount, "Insufficient credits in listing");
        require(msg.value == _amount * listing.pricePerCredit, "Incorrect payment");
        
        listing.amount -= _amount;
        if (listing.amount == 0) {
            listing.active = false;
