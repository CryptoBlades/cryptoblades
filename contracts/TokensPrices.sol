pragma solidity ^0.6.0;
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";

contract TokensPrices is Initializable, AccessControlUpgradeable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using ABDKMath64x64 for int128;

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

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

    function initialize() public initializer {
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setTokenPrice(uint256 price) external restricted {
        tokenPrice = price;
    }

    function setSkillTokenPrice(uint256 price) external restricted {
        skillTokenPrice = price;
    }

    function skillToNativeRatio() external view returns (int128) {
        return ABDKMath64x64.divu(skillTokenPrice, tokenPrice);
    }
}
