pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "../interfaces/ITransferCooldownable.sol";

contract Junk is Initializable, ERC721Upgradeable, AccessControlUpgradeable, ITransferCooldownable {

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");
    bytes32 public constant RECEIVE_DOES_NOT_SET_TRANSFER_TIMESTAMP = keccak256("RECEIVE_DOES_NOT_SET_TRANSFER_TIMESTAMP");

    uint256 public constant TRANSFER_COOLDOWN = 1 days;

    function initialize () public initializer {
        __ERC721_init("CryptoBlades Trinket", "CBT");
        __AccessControl_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    mapping(uint256 => uint256) public override lastTransferTimestamp;

    mapping(uint256 => uint8) public stars;
    mapping(uint256 => uint256) public effect;

    modifier restricted() {
        require(hasRole(GAME_ADMIN, msg.sender), "Not game admin");
        _;
    }

    function __ITransferCooldownable_interfaceId() external pure returns (bytes4) {
        return TransferCooldownableInterfaceId.interfaceId();
    }

    function transferCooldownEnd(uint256 tokenId) public override view returns (uint256) {
        return lastTransferTimestamp[tokenId].add(TRANSFER_COOLDOWN);
    }

    function transferCooldownLeft(uint256 tokenId) public override view returns (uint256) {
        (bool success, uint256 secondsLeft) =
            lastTransferTimestamp[tokenId].trySub(
                block.timestamp.sub(TRANSFER_COOLDOWN)
            );

        return success ? secondsLeft : 0;
    }

    function mint(address minter, uint8 mintStars, uint256 mintEffect) public restricted returns(uint256) {

        uint256 tokenID = totalSupply();
        stars[tokenID] = mintStars;
        effect[tokenID] = mintEffect;
        _mint(minter, tokenID);
        return tokenID;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        // when not minting or burning...
        if(from != address(0) && to != address(0)) {
            // only allow transferring a particular token every TRANSFER_COOLDOWN seconds
            require(lastTransferTimestamp[tokenId] < block.timestamp.sub(TRANSFER_COOLDOWN), "Transfer cooldown");

            if(!hasRole(RECEIVE_DOES_NOT_SET_TRANSFER_TIMESTAMP, to)) {
                lastTransferTimestamp[tokenId] = block.timestamp;
            }
        }
    }

}