pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";
import "./interfaces/IRandoms.sol";

struct SeedState {
    bytes32 requestId;
    uint256 seed;
    bool isAvailable;
}

contract ChainlinkRandoms is IRandoms, Pausable, AccessControl, VRFConsumerBase {
    using SafeERC20 for IERC20;

    uint256 constant VRF_MAGIC_SEED = uint256(keccak256("CryptoBlades"));

    bytes32 public constant RANDOMNESS_REQUESTER = keccak256("RANDOMNESS_REQUESTER");

    bytes32 private keyHash;
    uint256 private fee;

    uint256 private seed;

    mapping(uint => bytes32) historicalBlockHashes;

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
        keyHash = _keyHash;
        fee = _fee;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // Views
    function getRandomSeed(address user) external override view returns (uint256) {
        return getRandomSeedUsingHash(user, blockhash(block.number - 1));
    }

    function getRandomSeedUsingHash(address user, bytes32 hash) public override view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(user, seed, hash, gasleft())));
    }

    // Mutative

    /**
     * Requests randomness from a user-provided seed
     */
    function requestRandomNumber() external whenNotPaused {
        require(hasRole(RANDOMNESS_REQUESTER, msg.sender), "Sender cannot request seed");
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");

        // the user-provided seed is not necessary, as per the docs
        // hence we set it to an arbitrary constant
        requestRandomness(keyHash, fee, VRF_MAGIC_SEED);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function getHistoricalBlockHash(uint blockNumber) public override updateBlockHashesModifier returns (bytes32) {
        require(blockNumber < block.number);
        return historicalBlockHashes[blockNumber];
    }

    function getHistoricalBlockHashWithFallback(uint blockNumber) public override returns (bytes32) {
        bytes32 hash = getHistoricalBlockHash(blockNumber);
        if (hash == 0) {
            hash = blockhash(block.number - 1);
        }
        return hash;
    }

    function updateBlockHashes() public override {
        historicalBlockHashes[block.number-1] = blockhash(block.number-1);
    }

    modifier updateBlockHashesModifier() {
        updateBlockHashes();
        _;
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 /* requestId */, uint256 randomness) internal override {
        seed = randomness;
    }

    function withdrawLink(uint256 tokenAmount) external onlyOwner {
        // very awkward - but should be safe given that the LINK token is ERC20-compatible
        IERC20(address(LINK)).safeTransfer(msg.sender, tokenAmount);
    }

    // Modifiers
    modifier onlyOwner() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");
        _;
    }
}
