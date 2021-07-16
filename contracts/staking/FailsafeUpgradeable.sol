pragma solidity ^0.6.2;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract FailsafeUpgradeable is Initializable, OwnableUpgradeable {
    bool public failsafeModeActive;

    function __Failsafe_init() internal initializer {
        __Ownable_init();
        __Failsafe_init_unchained();
    }

    function __Failsafe_init_unchained() internal initializer {
        failsafeModeActive = false;
    }

    function enableFailsafeMode() public virtual onlyOwner {
        failsafeModeActive = true;
        emit FailsafeModeEnabled();
    }

    event FailsafeModeEnabled();

    modifier normalMode {
        require(
            !failsafeModeActive,
            "This action cannot be performed while the contract is in Failsafe Mode"
        );
        _;
    }

    modifier failsafeMode {
        require(
            failsafeModeActive,
            "This action can only be performed while the contract is in Failsafe Mode"
        );
        _;
    }
}
