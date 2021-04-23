pragma solidity ^0.6.0;

import "../node_modules/@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

contract Randoms is VRFConsumerBase {

    // NOTE: This file is tweaked for local network use
    // test and mainnet use will need adjustments

    address main;

    bytes32 internal keyHash;
    uint256 internal fee;

    uint256 internal requestID = 1;

    
    mapping(address => uint256) private requests;
    mapping(uint256 => bool) private seedAvailable;
    mapping(uint256/*requestID*/ => uint256/*seed*/) private seeds;

    constructor(address source) 
        VRFConsumerBase(
            0xa555fC018435bef5A13C6c6870a9d4C11DEC329C, // VRF Coordinator
            0x84b9b910527ad5c03a9ca831909e21e236ea7b06  // LINK Token
        ) public
    {
        main = source;
        keyHash = 0xcaf3c3727e033261d383b315559476f48034c13b18f8cafed4d871abe5049186;
        fee = 0.1 * 10 ** 18; // 0.1 LINK
    }

    /** 
     * Requests randomness from a user-provided seed
     */
    function getRandomNumber(address user, uint256 userProvidedSeed) public restricted returns (bytes32 requestId) {
        uint256 id = requestID++;
        requests[user] = id;
        // THIS NEXT BIT IS NOT THE REAL WAY IT WORKS
        fulfillRandomness(bytes32(id), uint(keccak256(abi.encodePacked(now, id, user, userProvidedSeed))));
        return bytes32(id);
        /*require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
        return requestRandomness(keyHash, fee, userProvidedSeed);*/
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        seeds[uint256(requestId)] = randomness;
        seedAvailable[uint256(requestId)] = true;
    }
    
    modifier restricted() {
        require(main == msg.sender, "Can only be called by main file");
        _;
    }

    function hasRequestedSeed(address user) public view restricted returns (bool) {
        return requests[user] != 0;
    }

    function hasConsumableSeed(address user) public view restricted returns (bool) {
        return hasRequestedSeed(user) && seedAvailable[requests[user]];
    }

    function consumeSeed(address user) public restricted returns (uint256) {
        uint256 seed = seeds[requests[user]];
        delete seeds[requests[user]];
        delete seedAvailable[requests[user]];
        delete requests[user];
        return seed;
    }

    function bytesToBytes32Array(bytes memory data)
        public
        pure
        returns (bytes32[] memory)
    {
        // Find 32 bytes segments nb
        uint256 dataNb = data.length / 32;
        // Create an array of dataNb elements
        bytes32[] memory dataList = new bytes32[](dataNb);
        // Start array index at 0
        uint256 index = 0;
        // Loop all 32 bytes segments
        for (uint256 i = 32; i <= data.length; i = i + 32) {
            bytes32 temp;
            // Get 32 bytes from data
            assembly {
                temp := mload(add(data, i))
            }
            // Add extracted 32 bytes to list
            dataList[index] = temp;
            index++;
        }
        // Return data list
        return (dataList);
    }
}