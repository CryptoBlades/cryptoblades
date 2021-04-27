pragma solidity ^0.6.0;

contract MultiAccess {
    
    // how about a master address that cannot be revoked?
    mapping(address => bool) private access;

    constructor() public {
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