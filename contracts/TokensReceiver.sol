pragma solidity ^0.6.0;
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./cryptoblades.sol";
import "hardhat/console.sol";

contract TokensReceiver is Initializable, AccessControlUpgradeable {
    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    CryptoBlades public game;

    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(GAME_ADMIN, msg.sender));
    }

    function initialize(
        address gameContract
    ) public initializer {
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        game = CryptoBlades(gameContract);
    }

    function fight(uint256 char, uint256 wep, uint32 target, uint8 fightMultiplier) external payable {
        uint256 offset = game.fight(char, wep, target, fightMultiplier);

        require(msg.value == offset, 'Offset error');
    }

    function getBalance() external view restricted returns (uint256) {
        return address(this).balance;
    }

    function retrieve(address addressToTransferTo, uint256 amount) external restricted {
        payable(addressToTransferTo).transfer(amount);
    }
}
