pragma solidity ^0.5.0;

import "./ownable.sol";
import "./characters.sol";
import "./weapons.sol";
import "./util.sol";

contract Kryptonites is Ownable, Util {
    
    Characters characters;
    Weapons weapons;
    
    
    constructor() internal Ownable() {
        characters = new Characters();
        weapons = new Weapons();
    }
    
    event FightOutcome(uint256 character, uint16 target, uint16 outcome);
    event LevelUp(uint256 character, uint16 level);
    event NewCharacter(uint256 character);
    event NewWeapon(uint256 weapon);
    
    function fight(uint256 character, uint256 weapon, uint16 target) external isCharacterOwner(character) isWeaponOwner(weapon) isTargetValid(character, target)  {
        // todo
        uint atk;
        uint hp;
        uint def;
        uint crit;
        emit FightOutcome(character, target, 0);
    }
    
    function getTargets(uint256 forCharacter) public view returns (uint16[4] memory) {
        //Characters.Character storage character = characters.tokens[forCharacter];
        // 4 targets: 1 easy, 2 mediums/mediumhards, 1 hard?
        return [uint16(0),0,0,0];
    }
    
    function mintCharacter() external payable requiredPay(uint256(characters.mintCharacterFee)) {
        uint256 tokenID = characters.mint();
        emit NewCharacter(tokenID);
    }
    
    function mintWeapon() external payable requiredPay(uint256(weapons.mintWeaponFee)) {
        uint256 tokenID = weapons.mint();
        emit NewWeapon(tokenID);
    }
    
    function fillStamina(uint256 character) external payable isCharacterOwner(character) requiredPay(uint256(characters.refillStaminaFee)) {
        characters.tokens.staminaTimestamp = now - (characters.timePerStamina * characters.maxStamina);
    }
    
    function reforgeWeapon(uint256 reforgeID, uint256 burnID) external payable requiredPay(uint256(weapons.reforgeWeaponFee)) {
        Weapons.Weapon storage reforging = weapons.tokens[reforgeID];
        Weapons.Weapon storage burning = weapons.tokens[burnID];
        uint8 forgeWeaponStar = weapons.getStars(weapon1.properties);
        uint8 burnWeaponStar = weapons.getStars(weapon2.properties);
        
        uint8 level = weapons.getLevel(reforging.stats);
        uint16 xpToLevel = weapons.getRequiredXpForLevel(level);
        uint16 xpGain = (burnWeaponStar - 1) * 8 + 16;

        reforging.xp += xpGain;
        int32 delta = xpToLevel-xpGain;

        if(delta <= 0) {
            reforging.xp = uint16(-delta);
            weapons.levelUp(reforgeID);
        }
        weapons.transferFrom(weapons.ownerOf(burnID), 0x0, burnID);
    }
    
    modifier isWeaponOwner(uint256 weapon) {
        require(weapons.ownerOf(weapon) == msg.sender);
        _;
    }
  
    modifier isCharacterOwner(uint256 character) {
        require(characters.ownerOf(character) == msg.sender);
        _;
    }
  
    modifier isTargetValid(uint256 character, uint16 target) {
        bool foundMatch = false;
        uint16[4] targets = getTargets(character);
        for(int i = 0; i < targets.length; i++) {
            if(targets[i] == target) {
                foundMatch = true;
            }
        }
        require(foundMatch);
        _;
    }
    
    modifier requiredPay(uint256 amount) {
        require(msg.value == amount);
        _;
    }
    
}