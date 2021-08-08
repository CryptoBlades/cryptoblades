pragma solidity ^0.6.5;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract SeedVault is Initializable, AccessControlUpgradeable {

    bytes32 public constant SEED_AUTHORITY = keccak256("SEED_AUTHORITY");

    //let's omit business 0 as a way to detect invalid entries
    uint256 public constant BUSINESS_WEAPON_MINT = 1;
    //uint256 public constant BUSINESS_WEAPON_PREMIUM_MINT = 2;

    function initialize () public initializer {
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    mapping(address/*wallet*/ => mapping(uint256/*business*/ => uint256[]/*ordersIndices*/)) userSeedOrders;
    uint256 seedIndexBlockNumber; // the block number "currentSeedIndex" was reached on
    uint256 currentSeedIndex; // used to mark new requests, related to keys in seedHashes
    uint256 currentOrderIndex; // used to track the keys for orderSeedIndices & orderAmounts
    mapping(uint256 => uint256) orderSeedIndices; // keyed by orderIndex
    mapping(uint256 => uint256) orderAmounts; // keyed by orderIndex
    mapping(uint256 => bytes32) seedHashes; // keyed by seedIndex
    mapping(address/*users who calculated blockhash*/ => uint256) seedCookies; // reward tracking for hash runners

    event PlacedOrder(address indexed user, uint256 indexed business, uint256 amount, uint256 seedIndex);
    event FirstOrderOfBusiness(address user, uint256 business); // lets the frontend know not to expect a weapon to appear yet

    modifier seedAuthorityOnly() {
        _seedAuthorityOnly();
        _;
    }

    function _seedAuthorityOnly() internal view {
        //require(hasRole(SEED_AUTHORITY, msg.sender), "Not game admin"); // temp for testing
    }

    function addSeedAndConsume(address user, uint256 business, uint256 amount) public
        seedAuthorityOnly
        returns(uint256) {

        uint256 seed = consumeSeedFor(user, business, amount);
        addSeedOrder(user, business, amount);
        return seed; // consumption must precede placing the order because it's a bucket
    }

    function addSeedOrder(address user, uint256 business, uint256 amount) public seedAuthorityOnly {

        incrementSeedIndexIfRelevant();

        userSeedOrders[user][business].push(currentOrderIndex);

        if(userSeedOrders[user][business].length == 1) {
            emit FirstOrderOfBusiness(user, business); // to indicate to frontend not to expect a mint result
        }
        
        orderSeedIndices[currentOrderIndex] = currentSeedIndex;
        orderAmounts[currentOrderIndex++] = amount;
        emit PlacedOrder(user, business, amount, currentSeedIndex);
    }

    function consumeSeedFor(address user, uint256 business, uint256 amount) public returns(uint256) {
        uint256[] storage userOrders = userSeedOrders[user][business];
        uint256 orderIndex = userOrders[userOrders.length-1];

        delete userOrders[userOrders.length-1]; // BUG: does not actually shorten the array
        uint256 seedIndex = orderSeedIndices[orderIndex];

        require(seedIndex < currentSeedIndex, "Too fresh for seed");
        require(orderAmounts[orderIndex] == amount, "Incorrect amount");

        delete orderSeedIndices[orderIndex];
        delete orderAmounts[orderIndex];

        return uint256(keccak256(abi.encodePacked(orderIndex, seedHashes[seedIndex])));
    }

    function incrementSeedIndexIfRelevant() public { // TODO make this internal
        if(block.number > seedIndexBlockNumber) {
            seedHashes[currentSeedIndex++] = blockhash(block.number - 1);
            seedIndexBlockNumber = block.number;
            seedCookies[msg.sender]++; // we remember their service o7 (uses 5292 gas)
        }
    }

    function checkOrders(address user, uint256 business) public view returns(uint256[] memory) {
        return userSeedOrders[user][business];
    }

}