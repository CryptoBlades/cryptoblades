pragma solidity ^0.6.0;

import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/utils/Pausable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../node_modules/@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";
import "./interfaces/IRandoms.sol";

struct SeedState {
    bytes32 requestId;
    uint256 seed;
    bool isAvailable;
}

abstract contract PausableOwnable is Ownable, Pausable {
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}

contract ChainlinkRandoms is IRandoms, PausableOwnable, VRFConsumerBase {
    using SafeERC20 for IERC20;

    uint256 constant VRF_MAGIC_SEED = uint256(keccak256("CryptoBlades"));

    address private main;

    bytes32 private keyHash;
    uint256 private fee;

    mapping(bytes32 => address) private requestUser;
    mapping(address => SeedState) private seedStates;

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

    // Views

    function hasRequestedSeed(address user) internal view returns (bool) {
        return seedStates[user].requestId != 0;
    }

    function hasConsumableSeed(address user) internal view returns (bool) {
        return hasRequestedSeed(user) && seedStates[user].isAvailable;
    }

    // Mutative

    function setMain(address newMain) external onlyOwner {
        main = newMain;
    }

    /**
     * Requests randomness from a user-provided seed
     */
    function getRandomNumber(address user) external override whenNotPaused {
        require(msg.sender == main || msg.sender == user, "Is not self or main");
        require(hasRequestedSeed(user), "Already requested");
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");

        // the user-provided seed is not necessary, as per the docs
        // hence we set it to an arbitrary constant
        bytes32 requestId = requestRandomness(keyHash, fee, VRF_MAGIC_SEED);

        requestUser[requestId] = user;
        seedStates[user].requestId = requestId;

        emit RandomNumberRequested(user);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        address _user = requestUser[requestId];

        seedStates[_user].seed = randomness;
        seedStates[_user].isAvailable = true;

        emit RandomNumberReceived(_user);
    }

    function consumeSeed(address user) public override restricted whenNotPaused returns (uint256) {
        SeedState storage seedState = seedStates[user];
        require(seedState.isAvailable, "User has no random seed");

        uint256 _seed = seedState.seed;

        delete requestUser[seedState.requestId];
        delete seedStates[user];

        return _seed;
    }

    function withdrawLink(uint256 tokenAmount) external onlyOwner {
        // very awkward - but should be safe given that the LINK token is ERC20-compatible
        IERC20(address(LINK)).safeTransfer(owner(), tokenAmount);
    }

    // Modifiers

    modifier restricted() {
        require(main == msg.sender, "Can only be called by main file");
        _;
    }
}
