// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract HasMain is Initializable, OwnableUpgradeable {
    address public main;

    function __HasMain_init() public initializer {
        __Ownable_init();
        __HasMain_init_unchained();
    }

    function __HasMain_init_unchained() public initializer {
        main = address(0);
    }

    function setMain(address newMain) external onlyOwner {
        main = newMain;
    }

    modifier restrictedToMain() {
        require(msg.sender == main || msg.sender == address(this), "Can only be called by main address or self");
        _;
    }
}
