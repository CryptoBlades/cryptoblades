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
    uint8 public offsetSlippage;

    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(GAME_ADMIN, msg.sender));
    }

    function initialize(address gameContract) public initializer {
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        game = CryptoBlades(gameContract);
        combatTokenChargePercent = 25;
        offsetSlippage = 5;
    }

    receive() external payable restricted {}

    function fight(
        uint256[] char,
        uint32[] target,
        uint8[] fightMultiplier
    ) external payable {
        uint256 totalTokens;
        uint256 totalExpectedTokens;
        for (uint256 i = 0; i < char.length; i++) {
            (uint256 tokens, uint256 expectedTokens) = game.fight(
                msg.sender,
                char[i],
                target[i],
                fightMultiplier[i]
            );
            totalTokens += tokens;
            totalExpectedTokens += expectedTokens;
        }
        //The following can be put outside the loop? I'm not 100% sure this is correct
        uint256 offset = ABDKMath64x64.mulu(
            getSkillToNativeRatio(),
            totalExpectedTokens.mul(combatTokenChargePercent).div(100)
        );

        require(
            msg.value >= offset.mul(100 - offsetSlippage).div(100) &&
                msg.value <= offset.mul(100 + offsetSlippage).div(100),
            "Offset error"
        );
        if (totalTokens == 0) {
            payable(msg.sender).transfer(msg.value);
        }
    }

    function singleFight(
        uint256 char,
        uint32 target,
        uint8 fightMultiplier
    ) external payable {
        (uint256 tokens, uint256 expectedTokens) = game.fight(
            msg.sender,
            char,
            target,
            fightMultiplier
        );

        uint256 offset = ABDKMath64x64.mulu(
            getSkillToNativeRatio(),
            expectedTokens.mul(combatTokenChargePercent).div(100)
        );

        require(
            msg.value >= offset.mul(100 - offsetSlippage).div(100) &&
                msg.value <= offset.mul(100 + offsetSlippage).div(100),
            "Offset error"
        );

        if (tokens == 0) {
            payable(msg.sender).transfer(msg.value);
        }
    }

    function retrieve(
        address addressToTransferTo,
        uint256 amount
    ) external restricted {
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

    function setOffsetSlippage(uint8 slippage) external restricted {
        offsetSlippage = slippage;
    }
}
