pragma solidity ^0.6.5;

import "./Cosmetics.sol";
import "./weapons.sol";

contract WeaponCosmetics is Cosmetics {

    Weapons public weapons;

    mapping(uint256 => uint32) public appliedCosmetics;

    event WeaponCosmeticApplied(address indexed owner, uint256 indexed weapon, uint32 cosmetic);
    event WeaponCosmeticRemoved(address indexed owner, uint256 indexed weapon, uint32 cosmetic);

    function initialize(Weapons _weapons)
        public
        initializer
    {
        __AccessControl_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        weapons = _weapons;
        for(uint8 i = 1; i < 20; i++) {
            _cosmeticAvailable[i] = true;
        }
    }

    function applyCosmetic(uint256 weaponId, uint32 cosmetic) public {
        require(weapons.ownerOf(weaponId) == msg.sender, "Not the weapon owner");
        if(appliedCosmetics[weaponId] != _noCosmetic){
            _restoreCosmetic(appliedCosmetics[weaponId], 1);
        }

        useCosmetic(cosmetic, 1);

        appliedCosmetics[weaponId] = cosmetic;
        emit WeaponCosmeticApplied(msg.sender, weaponId, cosmetic);
    }

    function removeCosmetic(uint256 weaponId) public {
        require(weapons.ownerOf(weaponId) == msg.sender, "Not the weapon owner");
        require(appliedCosmetics[weaponId] != _noCosmetic, "No cosmetic applied");
        _restoreCosmetic(appliedCosmetics[weaponId], 1);
        emit WeaponCosmeticRemoved(msg.sender, weaponId, appliedCosmetics[weaponId]);
        appliedCosmetics[weaponId] = _noCosmetic;
    }

    function getWeaponCosmetic(uint256 weaponId) public view returns (uint32) {
        return appliedCosmetics[weaponId];
    }
}