pragma solidity ^0.6.5;

import "./Consumables.sol";
import "./characters.sol";
import "./interfaces/IRandoms.sol";

contract ExpScrollConsumables is Consumables {

    Characters characters;
    uint8 internal staminaCost;
    uint16 internal expGain;

    event ExpScrollUsed(address indexed owner, uint256 indexed character, uint8 staminaUsed, uint16 expGained);

    function initialize(Characters _characters)
        public
        initializer
    {
        __AccessControl_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _enabled = true;
        staminaCost = 160;
        expGain = 160;
        characters = _characters;
    }

    function updateExpScroll(uint8 _staminaCost, uint16 _expGain) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");
        require(_staminaCost > 0, 'invalid stamina cost');
        require(_expGain > 0, 'invalid exp gain');
        staminaCost = _staminaCost;
        expGain = _expGain;
    }

    function getStaminaCost() public view returns (uint8){
        return staminaCost;
    }

    function getExpGain() public view returns (uint16){
        return expGain;
    }

    function useExpScroll(uint256 characterId) public {
        require(characters.ownerOf(characterId) == msg.sender, "Not the character owner");
        require(characters.getStaminaPoints(characterId) >= staminaCost, "Not enough stamina");
        consumeItem(1);
        characters.gainXp(characterId, expGain);
        characters.drainStamina(characterId, staminaCost);
        emit ExpScrollUsed(msg.sender, characterId, staminaCost, expGain);
    }
}
