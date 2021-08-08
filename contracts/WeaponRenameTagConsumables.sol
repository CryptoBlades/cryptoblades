pragma solidity ^0.6.5;

import "./Consumables.sol";

contract WeaponRenameTagConsumables is Consumables {

    mapping(uint256 => string) public renames;

    event WeaponRenamed(address indexed owner, uint256 indexed weapon);

    function renameWeapon(uint256 weaponId, string memory newName) public {
        require(bytes(newName).length < 16, 'too long');
        consumeItem();
        renames[weaponId] = newName;
        emit WeaponRenamed(msg.sender, weaponId);
    }

    function getWeaponRename(uint256 weaponId) public view returns (string memory) {
        return renames[weaponId];
    }
}
