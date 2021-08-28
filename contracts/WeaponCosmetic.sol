pragma solidity ^0.6.5;

import "./Cosmetics.sol";
import "./weapons.sol";

contract WeaponCosmetic is Cosmetics {

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
        _maxCosmeticId = 2;
        _cosmeticAvailable[1] = true;
        _cosmeticAvailable[2] = true;
    }

    function applyCosmetic(uint256 weaponId, uint32 cosmetic) public {
        if(appliedCosmetics[weaponId] != _noCosmetic){
            _restoreCosmetic(appliedCosmetics[weaponId], 1);
        }

        useCosmetic(cosmetic, 1);

        appliedCosmetics[weaponId] = cosmetic;
        emit WeaponCosmeticApplied(msg.sender, weaponId, cosmetic);
    }

    function removeCosmetic(uint256 weaponId, uint32 cosmetic) public {
        require(cosmetic != _noCosmetic && appliedCosmetics[weaponId] == cosmetic, "Cosmetic not valid");
        _restoreCosmetic(cosmetic, 1);
        appliedCosmetics[weaponId] = _noCosmetic;
        emit WeaponCosmeticRemoved(msg.sender, weaponId, cosmetic);
    }

    function getWeaponCosmetic(uint256 weaponId) public view returns (uint32) {
        return appliedCosmetics[weaponId];
    }
}