pragma solidity ^0.6.0;
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "./cryptoblades.sol";

contract TokensManager is Initializable, AccessControlUpgradeable {
    using SafeMath for uint256;
    using ABDKMath64x64 for int128;

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    CryptoBlades public game;

    uint256 public combatTokenChargePercent;
    // Note: All prices are multiplied by 100
    uint256 public tokenPrice;
    uint256 public skillTokenPrice;

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
        combatTokenChargePercent = 25;
    }

    receive() external payable restricted {
    }

    function fight(uint256 char, uint256 wep, uint32 target, uint8 fightMultiplier) external payable {
        (uint256 expectedTokens, bool playerLost) = game.fight(char, wep, target, fightMultiplier);

        uint256 offset = ABDKMath64x64.mulu(getSkillToNativeRatio(), expectedTokens.mul(combatTokenChargePercent));

        require(msg.value == offset, 'Offset error');

        if (playerLost) {
            payable(msg.sender).transfer(msg.value);
        }
    }

    function retrieve(address addressToTransferTo, uint256 amount) external restricted {
        payable(addressToTransferTo).transfer(amount);
    }

    function getSkillToNativeRatio() public view returns (int128) {
        return ABDKMath64x64.divu(skillTokenPrice, tokenPrice);
    }

    function setTokenPrice(uint256 price) external restricted {
        tokenPrice = price;
    }

    function setSkillTokenPrice(uint256 price) external restricted {
        skillTokenPrice = price;
    }

    function setCombatTokenChargePercent(uint256 percent) external restricted {
        combatTokenChargePercent = percent;
    }
}