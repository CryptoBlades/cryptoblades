pragma solidity ^0.6.5;

import "./Consumables.sol";
import "./weapons.sol";

contract WeaponRenameTagConsumables is Consumables {

    Weapons public weapons;

    uint8 private _minSize;
    uint8 private _maxSize;

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
        _minSize = 1;
        _maxSize = 24;
    }

    function renameWeapon(uint256 weaponId, string memory newName) public {
        require(bytes(newName).length >= _minSize && bytes(newName).length <= _maxSize, 'size not valid');
        require(weapons.ownerOf(weaponId) == msg.sender, "Not the weapon owner");
        consumeItem(1);
        renames[weaponId] = newName;
        emit WeaponRenamed(msg.sender, weaponId);
    }

    function getWeaponRename(uint256 weaponId) public view returns (string memory) {
        return renames[weaponId];
    }

    function setMinSize(uint8 newMinSize) external isAdmin {
        require(newMinSize > 0, 'invalid size');
        _minSize = newMinSize;
    }

    function setMaxSize(uint8 newMaxSize) external isAdmin {
        require(newMaxSize > 0, 'invalid size');
        _maxSize = newMaxSize;
    }

    function getMinSize() public view returns (uint8){
        return _minSize;
    }

    function getMaxSize() public view returns (uint8){
        return _maxSize;
    }
}