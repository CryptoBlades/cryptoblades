pragma solidity ^0.6.5;

import "./Consumables.sol";
import "./weapons.sol";

contract WeaponRenameTagConsumables is Consumables {

    Weapons public weapons;

    mapping(uint256 => string) public renames;

    event WeaponRenamed(address indexed owner, uint256 indexed weapon);

    function initialize(Weapons _weapons)
        public
        initializer
    {
        __AccessControl_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _enabled = true;

        weapons = _weapons;
    }

    function renameWeapon(uint256 weaponId, string memory newName) public {
        require(bytes(newName).length < 16, 'too long');
        require(weapons.ownerOf(weaponId) == msg.sender, "Not the weapon owner");
        consumeItem();
        renames[weaponId] = newName;
        emit WeaponRenamed(msg.sender, weaponId);
    }

    function getWeaponRename(uint256 weaponId) public view returns (string memory) {
        return renames[weaponId];
    }
}
