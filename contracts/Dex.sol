// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.5;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./common.sol";

contract Dex is Initializable, AccessControlUpgradeable {
    using SafeMath for uint256;

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");
    uint public constant FEE_DENOMINATOR = 10000;

    uint8 public constant VAR_FEE = 0;
    uint8 public constant VAR_CONTRACT_ENABLED = 1;

    struct TokenPair {
        address token1;
        uint token1Amount;
        address token2;
        uint token2Amount;
    }

    mapping(uint => TokenPair) public tokenPairs;
    mapping(address => uint) public collectedFees;
    mapping(uint256 => uint256) public vars;

    event TokenPairSwapped(address indexed token1, uint token1Amount, address indexed token2, uint token2Amount);
    event TokenPairAdded(uint id, address indexed token1, address indexed token2);
    event TokenPairRemoved(uint id, address indexed token1, address indexed token2);
    event LiquidityAdded(address indexed token1, uint token1Amount, address indexed token2, uint token2Amount);
    event LiquiditySet(address indexed token1, uint token1Amount, address indexed token2, uint token2Amount);
    event LiquidityTaken(address indexed token1, uint token1Amount, address indexed token2, uint token2Amount);
    event ERC20Withdrawal(address indexed token, uint amount);

    function initialize() virtual public initializer {
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, tx.origin);
        _setupRole(GAME_ADMIN, tx.origin);
    }

    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(GAME_ADMIN, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "NA");
    }

    modifier contractEnabled() {
        _contractEnabled();
        _;
    }

    function _contractEnabled() internal view {
        require(vars[VAR_CONTRACT_ENABLED] == 1, "Contract disabled");
    }

    // FUNCTIONS

    function swap(address tokenA, address tokenB, uint amountA) external contractEnabled {
        uint id = getTokenPairId(tokenA, tokenB);
        TokenPair memory pair = tokenPairs[id];
        require((pair.token1 == tokenA && pair.token2 == tokenB) || (pair.token2 == tokenA && pair.token1 == tokenB), "Invalid pair");
        amountA = transferWithAdditionalAmountCheck(tokenA, msg.sender, address(this), amountA);
        uint amountB = getAmountOut(tokenA, tokenB, amountA);
        require(amountB > 0, "Invalid amount");
        if (tokenA == pair.token1) {
            pair.token1Amount += amountA;
            pair.token2Amount -= amountB;
        } else {
            pair.token1Amount -= amountB;
            pair.token2Amount += amountA;
        }
        tokenPairs[id] = pair;
        uint fee = amountB.mul(vars[VAR_FEE]).div(FEE_DENOMINATOR);
        collectedFees[tokenB] = collectedFees[tokenB].add(fee);
        IERC20(tokenB).transfer(msg.sender, Common.adjustDecimals(amountB - fee, ERC20(tokenB).decimals()));
        emit TokenPairSwapped(tokenA, amountA, tokenB, amountB);
    }

    // VIEWS

    function getTokenPairId(address tokenA, address tokenB) public pure returns (uint id) {
        (address token1, address token2) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        id = uint(keccak256(abi.encodePacked(token1, token2)));
    }

    function getAmountOut(address tokenA, address tokenB, uint amountA) public view returns (uint amountTo) {
        uint id = getTokenPairId(tokenA, tokenB);
        TokenPair memory pair = tokenPairs[id];
        require(amountA > 0, "Invalid amount");
        if (tokenA == pair.token1) {
            amountTo = pair.token2Amount.mul(amountA).div(pair.token1Amount);
        } else {
            amountTo = pair.token1Amount.mul(amountA).div(pair.token2Amount);
        }
    }

    function getVars(uint256[] calldata varFields) external view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](varFields.length);
        for (uint i = 0; i < varFields.length; i++) {
            result[i] = vars[varFields[i]];
        }
        return result;
    }

    // ADMIN

    function setVar(uint256 varField, uint256 value) external restricted {
        vars[varField] = value;
    }

    function addPair(address tokenA, uint amountA, address tokenB, uint amountB) external restricted {
        (address token1, uint amount1, address token2, uint amount2) = tokenA < tokenB ? (tokenA, amountA, tokenB, amountB) : (tokenB, amountB, tokenA, amountA);
        uint id = getTokenPairId(token1, token2);
        require(tokenPairs[id].token1 == address(0) && tokenPairs[id].token2 == address(0), "Pair already exists");
        amount1 = transferWithAdditionalAmountCheck(token1, msg.sender, address(this), amount1);
        amount2 = transferWithAdditionalAmountCheck(token2, msg.sender, address(this), amount2);
        tokenPairs[id] = TokenPair(token1, amount1, token2, amount2);
        emit TokenPairAdded(id, token1, token2);
    }

    function addPairWithoutLiquidity(address tokenA, address tokenB) external restricted {
        (address token1, address token2) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        uint id = getTokenPairId(token1, token2);
        require(tokenPairs[id].token1 == address(0) && tokenPairs[id].token2 == address(0), "Pair already exists");
        tokenPairs[id] = TokenPair(token1, 0, token2, 0);
        emit TokenPairAdded(id, token1, token2);
    }

    function deletePair(address tokenA, address tokenB) external restricted {
        (address token1, address token2) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        uint id = getTokenPairId(token1, token2);
        require(tokenPairs[id].token1 != address(0) && tokenPairs[id].token2 != address(0), "Pair doesn't exist");
        delete tokenPairs[id];
        emit TokenPairRemoved(id, token1, token2);
    }

    function addLiquidity(address tokenA, uint amountA, address tokenB, uint amountB) external restricted {
        (address token1, uint amount1, address token2, uint amount2) = tokenA < tokenB ? (tokenA, amountA, tokenB, amountB) : (tokenB, amountB, tokenA, amountA);
        uint id = getTokenPairId(token1, token2);
        TokenPair memory pair = tokenPairs[id];
        require(pair.token1 == token1 && pair.token2 == token2, "Invalid pair");
        require(amount1 > 0 && amount2 > 0, "Invalid amount");
        amount1 = transferWithAdditionalAmountCheck(token1, msg.sender, address(this), amount1);
        amount2 = transferWithAdditionalAmountCheck(token2, msg.sender, address(this), amount2);
        pair.token1Amount += amount1;
        pair.token2Amount += amount2;
        tokenPairs[id] = pair;
        emit LiquidityAdded(token1, amount1, token2, amount2);
    }

    function setLiquidityInWei(address tokenA, uint amountA, address tokenB, uint amountB) external restricted {
        (address token1, uint amount1, address token2, uint amount2) = tokenA < tokenB ? (tokenA, amountA, tokenB, amountB) : (tokenB, amountB, tokenA, amountA);
        uint id = getTokenPairId(token1, token2);
        TokenPair memory pair = tokenPairs[id];
        require(pair.token1 == token1 && pair.token2 == token2, "Invalid pair");
        pair.token1Amount = amount1;
        pair.token2Amount = amount2;
        tokenPairs[id] = pair;
        emit LiquiditySet(token1, amount1, token2, amount2);
    }

    function takeLiquidityInWei(address tokenA, uint amountA, address tokenB, uint amountB) external restricted {
        (address token1, uint amount1, address token2, uint amount2) = tokenA < tokenB ? (tokenA, amountA, tokenB, amountB) : (tokenB, amountB, tokenA, amountA);
        uint id = getTokenPairId(token1, token2);
        TokenPair memory pair = tokenPairs[id];
        require(pair.token1 == token1 && pair.token2 == token2, "Invalid pair");
        IERC20(token1).transfer(msg.sender, amount1);
        IERC20(token2).transfer(msg.sender, amount2);
        pair.token1Amount = pair.token1Amount.sub(amount1);
        pair.token2Amount = pair.token2Amount.sub(amount2);
        tokenPairs[id] = pair;
        emit LiquidityTaken(token1, amount1, token2, amount2);
    }

    function withdrawERC20Wei(address token, uint256 amount) external restricted {
        IERC20(token).transfer(msg.sender, amount);
        emit ERC20Withdrawal(token, amount);
    }

    function collectFees(address token) external restricted {
        uint fee = collectedFees[token];
        IERC20(token).transfer(msg.sender, Common.adjustDecimals(fee, ERC20(token).decimals()));
        collectedFees[token] = 0;
    }

    // PRIVATE

    function transferWithAdditionalAmountCheck(address token, address from, address to, uint amount) private returns (uint) {
        uint amountBefore = IERC20(token).balanceOf(address(this));
        IERC20(token).transferFrom(from, to, Common.adjustDecimals(amount, ERC20(token).decimals()));
        uint amountAfter = IERC20(token).balanceOf(address(this));
        return amountAfter.sub(amountBefore);
    }

}