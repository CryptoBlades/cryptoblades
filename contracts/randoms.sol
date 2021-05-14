pragma solidity ^0.6.0;

import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../node_modules/@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";
import "./interfaces/IRandoms.sol";

contract ChainlinkRandoms is IRandoms, Ownable, VRFConsumerBase {
    using SafeERC20 for IERC20;

    address main;

    bytes32 internal keyHash;
    uint256 internal fee;

    mapping(address => bytes32) private requests;
    mapping(bytes32 => address) private requestUser;

    mapping(bytes32 => bool) private seedAvailable;
    mapping(bytes32/*requestID*/ => uint256/*seed*/) private seeds;

    // BSC testnet details:
    // LINK token: 0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06
    // VRF Coordinator: 0xa555fC018435bef5A13C6c6870a9d4C11DEC329C
    // Key Hash: 0xcaf3c3727e033261d383b315559476f48034c13b18f8cafed4d871abe5049186
    // Fee: 0.1 * 10 ** 18 // 0.1 LINK

    constructor(address _vrfCoordinator, address _link, bytes32 _keyHash, uint256 _fee)
        VRFConsumerBase(
            _vrfCoordinator, // VRF Coordinator
            _link  // LINK Token
        ) public
    {
        main = address(0);
        keyHash = _keyHash;
        fee = _fee;
    }

    function setMain(address newMain) external onlyOwner {
        main = newMain;
    }

    /**
     * Requests randomness from a user-provided seed
     */
    function getRandomNumber(address user, uint256 userProvidedSeed) public override restricted {
        //*
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
        bytes32 requestId = requestRandomness(keyHash, fee, userProvidedSeed);
        /*/
        bytes32 requestId = keccak256(abi.encodePacked(block.timestamp, user, userProvidedSeed));
        //*/

        requests[user] = requestId;
        requestUser[requestId] = user;

        emit RandomNumberRequested(user, userProvidedSeed);

        // THIS NEXT BIT IS NOT THE REAL WAY IT WORKS
        // uint256 fakeRandomValue = uint256(keccak256(abi.encodePacked(now, requestId, user, userProvidedSeed)));
        // fulfillRandomness(requestId, fakeRandomValue);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        address _user = requestUser[requestId];

        seeds[requestId] = randomness;
        seedAvailable[requestId] = true;
        emit RandomNumberReceived(_user);
    }

    modifier restricted() {
        require(main == msg.sender, "Can only be called by main file");
        _;
    }

    function hasRequestedSeed(address user) public override view restricted returns (bool) {
        return requests[user] != 0;
    }

    function hasConsumableSeed(address user) public override view restricted returns (bool) {
        return hasRequestedSeed(user) && seedAvailable[requests[user]];
    }

    function consumeSeed(address user) public override restricted returns (uint256) {
        bytes32 _requestId = requests[user];
        uint256 seed = seeds[_requestId];
        delete seeds[_requestId];
        delete seedAvailable[_requestId];
        delete requestUser[_requestId];
        delete requests[user];
        return seed;
    }

    function withdrawLink(uint256 tokenAmount) external onlyOwner {
        // very awkward - but should be safe given that the LINK token is ERC20-compatible
        IERC20(address(LINK)).safeTransfer(owner(), tokenAmount);
    }
}
