pragma solidity ^0.6.0;

contract Kryptoknights {
    string public _name = "Krypto knights!";

    function getName() public view returns (string memory) {
        return _name;
    }
}