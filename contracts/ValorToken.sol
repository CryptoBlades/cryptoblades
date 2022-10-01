pragma solidity ^0.6.2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title SimpleToken
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 * Based on https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.1/contracts/examples/SimpleToken.sol
 */
contract ValorToken is ERC20Upgradeable, OwnableUpgradeable {
    function initialize()
        public
        initializer
    {
        __ERC20_init("Valor Token", "VALOR");
        __Ownable_init();
        _mint(address(this), 100000000 * (10 ** uint256(decimals())));
        _approve(address(this), msg.sender, totalSupply());
    }

    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }
}