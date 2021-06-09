// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract FailsafeUpgradeable is Initializable, OwnableUpgradeable {
    bool public failsafeModeActive;

    function __Failsafe_init() public initializer {
        __Ownable_init();
        __Failsafe_init_unchained();
    }

    function __Failsafe_init_unchained() public initializer {
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
