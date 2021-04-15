pragma solidity ^0.6.2;

import "./Owned.sol";

abstract contract Failsafe is Owned {
    bool public failsafeModeActive = false;

    constructor() internal {
        require(owner != address(0), "Owner must be set");
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
