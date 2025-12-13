// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title BaseMinter
 * @dev Simple NFT minting contract with mint fee collection
 * @notice Users can mint NFTs by uploading images and paying a small fee
 */
contract BaseMinter is ERC721URIStorage, Ownable, ReentrancyGuard {
    
    // State variables
    uint256 private _tokenIdCounter;
    uint256 public constant MINT_FEE = 0.0000175 ether; // ~$0.05 at current ETH prices
    uint256 public totalFeesCollected;
    
    // Mappings
    mapping(address => uint256[]) private _userTokens;
    mapping(uint256 => address) private _tokenMinter;
    
    // Events
    event NFTMinted(
        address indexed minter,
        uint256 indexed tokenId,
        string tokenURI,
        uint256 timestamp
    );
    
    event FeesWithdrawn(
        address indexed owner,
        uint256 amount,
        uint256 timestamp
    );
    
    /**
     * @dev Constructor sets NFT name and symbol
     */
    constructor() ERC721("BaseMint NFT", "BMINT") Ownable(msg.sender) {
        _tokenIdCounter = 0;
    }
    
    /**
     * @notice Mint a new NFT with custom metadata
     * @param tokenURI The IPFS URI containing NFT metadata
     * @return tokenId The ID of the newly minted NFT
     */
    function mintNFT(string memory tokenURI) 
        public 
        payable 
        nonReentrant 
        returns (uint256) 
    {
        require(msg.value >= MINT_FEE, "Insufficient mint fee");
        require(bytes(tokenURI).length > 0, "Token URI cannot be empty");
        
        // Increment counter and mint
        _tokenIdCounter++;
        uint256 newTokenId = _tokenIdCounter;
        
        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        
        // Track user tokens and minter
        _userTokens[msg.sender].push(newTokenId);
        _tokenMinter[newTokenId] = msg.sender;
        
        // Update total fees
        totalFeesCollected += msg.value;
        
        emit NFTMinted(msg.sender, newTokenId, tokenURI, block.timestamp);
        
        // Refund excess payment
        if (msg.value > MINT_FEE) {
            payable(msg.sender).transfer(msg.value - MINT_FEE);
        }
        
        return newTokenId;
    }
    
    /**
     * @notice Batch mint multiple NFTs (gas efficient for power users)
     * @param tokenURIs Array of IPFS URIs
     * @return tokenIds Array of newly minted token IDs
     */
    function batchMintNFTs(string[] memory tokenURIs) 
        public 
        payable 
        nonReentrant 
        returns (uint256[] memory) 
    {
        uint256 count = tokenURIs.length;
        require(count > 0 && count <= 10, "Must mint 1-10 NFTs");
        require(msg.value >= MINT_FEE * count, "Insufficient mint fee");
        
        uint256[] memory tokenIds = new uint256[](count);
        
        for (uint256 i = 0; i < count; i++) {
            require(bytes(tokenURIs[i]).length > 0, "Token URI cannot be empty");
            
            _tokenIdCounter++;
            uint256 newTokenId = _tokenIdCounter;
            
            _safeMint(msg.sender, newTokenId);
            _setTokenURI(newTokenId, tokenURIs[i]);
            
            _userTokens[msg.sender].push(newTokenId);
            _tokenMinter[newTokenId] = msg.sender;
            
            tokenIds[i] = newTokenId;
            
            emit NFTMinted(msg.sender, newTokenId, tokenURIs[i], block.timestamp);
        }
        
        totalFeesCollected += MINT_FEE * count;
        
        // Refund excess
        uint256 totalCost = MINT_FEE * count;
        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost);
        }
        
        return tokenIds;
    }
    
    /**
     * @notice Withdraw collected fees (owner only)
     */
    function withdrawFees() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw");
        
        emit FeesWithdrawn(msg.sender, balance, block.timestamp);
        
        payable(owner()).transfer(balance);
    }
    
    /**
     * @notice Get total number of NFTs minted
     */
    function getTotalMinted() public view returns (uint256) {
        return _tokenIdCounter;
    }
    
    /**
     * @notice Get all token IDs owned by an address
     */
    function getUserTokens(address user) public view returns (uint256[] memory) {
        return _userTokens[user];
    }
    
    /**
     * @notice Get the original minter of a token
     */
    function getTokenMinter(uint256 tokenId) public view returns (address) {
        return _tokenMinter[tokenId];
    }
    
    /**
     * @notice Get contract balance
     */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @notice Get recent mints (last N tokens)
     * @param count Number of recent tokens to return
     */
    function getRecentMints(uint256 count) 
        public 
        view 
        returns (uint256[] memory) 
    {
        uint256 total = _tokenIdCounter;
        if (total == 0) {
            return new uint256[](0);
        }
        
        uint256 returnCount = count > total ? total : count;
        uint256[] memory recentTokenIds = new uint256[](returnCount);
        
        for (uint256 i = 0; i < returnCount; i++) {
            recentTokenIds[i] = total - i;
        }
        
        return recentTokenIds;
    }
    
    /**
     * @notice Check if address has minted any NFTs
     */
    function hasMinted(address user) public view returns (bool) {
        return _userTokens[user].length > 0;
    }
    
    /**
     * @notice Get mint count for specific address
     */
    function getMintCount(address user) public view returns (uint256) {
        return _userTokens[user].length;
    }
}