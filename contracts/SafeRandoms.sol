pragma solidity ^0.6.5;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract SafeRandoms is Initializable, AccessControlUpgradeable {

    bytes32 public constant SEED_AUTHORITY = keccak256("SEED_AUTHORITY");

    /* Notes
    *   One-at-a-time seeds cost 20527 gas less compared to first queued, and 5527 less compared to following ones
    *   It's worth passing an array to request a seed instead of pre-hashing them into uint to save on contract size
    *       8 gas for 1 value, 20 gas for 2 values, 416 for 10 values, so pre-hash for large arrays though!
    *   It takes 280 gas per value to hash into a single value. Probably won't save much by bit packing instead
    *   But skipping the hashing entirely will save 970 gas
    *   Bitpacking 2 values costs 148 gas instead of hashing
    */

    // WIP THIS CONTRACT IS A DRAFT

    mapping(address/*wallet*/ => mapping(uint256/*business*/ => uint256[]/*ordersIndices*/)) userSeedOrders;
    mapping(address => mapping(uint256 => uint256[])) userSeedOrders2;
    mapping(address => mapping(uint256 => uint256)) userSeedOrders3;

    uint256 currentSeedIndex; // used to mark new requests, related to keys in seedHashes
    uint256 currentOrderIndex; // used to track the keys for orderSeedIndices & orderAmounts
    mapping(uint256 => uint256) orderSeedIndices; // keyed by orderIndex
    mapping(uint256 => bytes32) seedHashes; // keyed by seedIndex

    function initialize () public initializer {
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function requestSingle(uint256 business) external {
        userSeedOrders[msg.sender][business].push(currentOrderIndex);

        orderSeedIndices[currentOrderIndex++] = 1;
    }

    function requestArray(uint256[] calldata business) external {
        uint256 hashed = uint256(keccak256(abi.encodePacked(business)));
        userSeedOrders2[msg.sender][hashed].push(currentOrderIndex);

        orderSeedIndices[currentOrderIndex++] = 1;
    }

    function requestOne(uint256 business) external {
        
        userSeedOrders3[msg.sender][business] = currentOrderIndex;
        orderSeedIndices[currentOrderIndex++] = 1;
    }

    function requestSingle2(uint256 business, uint256 business2) external {
        
        userSeedOrders[msg.sender][business | business2].push(currentOrderIndex);

        orderSeedIndices[currentOrderIndex++] = 1;
    }

    function getSingle(uint256 business) public view returns(uint256[] memory) {
        return userSeedOrders[msg.sender][business];
    }

    function getSingle(uint256[] memory business) public view returns(uint256[] memory) {
        uint256 hashed = uint256(keccak256(abi.encodePacked(business)));
        return userSeedOrders2[msg.sender][hashed];
    }

    function checkHash(uint256[] memory business) public view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(business)));
    }
}