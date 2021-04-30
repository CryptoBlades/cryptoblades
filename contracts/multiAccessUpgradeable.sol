pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

contract MultiAccessUpgradeable is Initializable {

    // how about a master address that cannot be revoked?
    mapping(address => bool) private access;

    function initialize() public initializer {
        access[msg.sender] = true;
    }

    function grantAccess(address to) public restricted {
        access[to] = true;
    }

    function revokeAccess(address from) public restricted {
        delete access[from];
    }

    modifier restricted() {
        require(access[msg.sender] == true, "Access denied");
        _;
    }

}