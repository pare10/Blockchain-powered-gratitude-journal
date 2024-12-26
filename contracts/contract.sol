// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title GratitudeJournal
 * @dev A blockchain-powered gratitude journal where users can record and share gratitude entries
 */
contract GratitudeJournal {
    // Struct to represent a gratitude entry
    struct GratitudeEntry {
        address author;
        string content;
        uint256 timestamp;
        bool isPublic;
        uint256 likes;
    }

    // State variables
    address public owner;
    GratitudeEntry[] public entries;
    mapping(address => uint256[]) private userEntries;
    mapping(uint256 => mapping(address => bool)) private entryLikes;

    // Events to log important actions
    event EntryCreated(address indexed author, uint256 indexed entryId, bool isPublic);
    event EntryLiked(address indexed liker, uint256 indexed entryId);
    event EntryUnliked(address indexed unliker, uint256 indexed entryId);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can perform this action");
        _;
    }

    // Constructor
    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Create a new gratitude entry
     * @param _content The content of the gratitude entry
     * @param _isPublic Whether the entry is publicly visible
     * @return The ID of the created entry
     */
    function createEntry(string memory _content, bool _isPublic) public returns (uint256) {
        require(bytes(_content).length > 0, "Entry content cannot be empty");
        require(bytes(_content).length <= 1000, "Entry content too long");

        GratitudeEntry memory newEntry = GratitudeEntry({
            author: msg.sender,
            content: _content,
            timestamp: block.timestamp,
            isPublic: _isPublic,
            likes: 0
        });

        uint256 newEntryId = entries.length;
        entries.push(newEntry);
        userEntries[msg.sender].push(newEntryId);

        emit EntryCreated(msg.sender, newEntryId, _isPublic);
        return newEntryId;
    }

    /**
     * @dev Like a public entry
     * @param _entryId The ID of the entry to like
     */
    function likeEntry(uint256 _entryId) public {
        require(_entryId < entries.length, "Entry does not exist");
        require(entries[_entryId].isPublic, "Entry is not public");
        require(msg.sender != entries[_entryId].author, "Cannot like own entry");
        require(!entryLikes[_entryId][msg.sender], "Already liked this entry");

        entries[_entryId].likes++;
        entryLikes[_entryId][msg.sender] = true;

        emit EntryLiked(msg.sender, _entryId);
    }

    /**
     * @dev Unlike a previously liked public entry
     * @param _entryId The ID of the entry to unlike
     */
    function unlikeEntry(uint256 _entryId) public {
        require(_entryId < entries.length, "Entry does not exist");
        require(entryLikes[_entryId][msg.sender], "Entry not previously liked");

        entries[_entryId].likes--;
        entryLikes[_entryId][msg.sender] = false;

        emit EntryUnliked(msg.sender, _entryId);
    }

    /**
     * @dev Get entries for a specific user
     * @param _user Address of the user
     * @return An array of entry IDs for the user
     */
    function getUserEntries(address _user) public view returns (uint256[] memory) {
        return userEntries[_user];
    }

    /**
     * @dev Get the total number of entries
     * @return Total number of entries
     */
    function getTotalEntries() public view returns (uint256) {
        return entries.length;
    }

    /**
     * @dev Retrieve a specific entry by its ID
     * @param _entryId The ID of the entry to retrieve
     * @return The gratitude entry details
     */
    function getEntry(uint256 _entryId) public view returns (GratitudeEntry memory) {
        require(_entryId < entries.length, "Entry does not exist");
        
        GratitudeEntry memory entry = entries[_entryId];
        
        // Only return entry if it's public or the caller is the author
        require(entry.isPublic || msg.sender == entry.author, "Not authorized to view this entry");
        
        return entry;
    }

    /**
     * @dev Get all public entries
     * @return An array of public gratitude entries
     */
    function getPublicEntries() public view returns (GratitudeEntry[] memory) {
        // Count public entries
        uint256 publicEntryCount = 0;
        for (uint256 i = 0; i < entries.length; i++) {
            if (entries[i].isPublic) {
                publicEntryCount++;
            }
        }

        // Create array of public entries
        GratitudeEntry[] memory publicEntries = new GratitudeEntry[](publicEntryCount);
        uint256 index = 0;
        for (uint256 i = 0; i < entries.length; i++) {
            if (entries[i].isPublic) {
                publicEntries[index] = entries[i];
                index++;
            }
        }

        return publicEntries;
    }

    /**
     * @dev Allow contract owner to withdraw any accumulated funds
     */
    function withdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    /**
     * @dev Fallback function to receive Ether
     */
    receive() external payable {}
}