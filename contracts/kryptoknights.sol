pragma solidity ^0.6.0;

//import "./ownable.sol";
import "./characters.sol";
import "./weapons.sol";
import "./util.sol";

contract Kryptoknights is Util {

    Characters public characters;
    Weapons public weapons;

    constructor() public /*Ownable()*/ {
        characters = new Characters(address(this));
        weapons = new Weapons(address(this));
    }

    mapping (address => uint256) public skill;

    uint256 public mintCharacterFee = 500;
    uint256 public rerollTraitFee = 300;
    uint256 public rerollCosmeticsFee = 300;
    uint256 public refillStaminaFee = 1000;
    
    uint256 public mintWeaponFee = 200;
    uint256 public reforgeWeaponFee = 100;
    
    event FightOutcome(uint256 character, uint256 weapon, uint32 target, uint24 playerRoll, uint24 enemyRoll);

    function getCharactersAddress() external view returns (address) {
        return address(characters);
    }
    
    function getWeaponsAddress() external view returns (address) {
        return address(weapons);
    }

    function getSkill() external view returns (uint256) {
        return skill[msg.sender];
    }

    function giveMeSkill(uint256 amount) public {
        // TEMPORARY FUNCITON TO TEST WITH
        skill[msg.sender] = skill[msg.sender] + amount;
    }

    function getCharacters() public view returns(uint256[] memory) {
        uint256[] memory tokens = new uint256[](characters.balanceOf(msg.sender));
        for(uint256 i = 0; i < tokens.length; i++) {
            tokens[i] = characters.tokenOfOwnerByIndex(msg.sender, i);
        }
        return tokens;
    }
    
    function getWeapons() public view returns(uint256[] memory) {
        uint256[] memory tokens = new uint256[](weapons.balanceOf(msg.sender));
        for(uint256 i = 0; i < tokens.length; i++) {
            tokens[i] = weapons.tokenOfOwnerByIndex(msg.sender, i);
        }
        return tokens;
    }
    
    function fight(uint256 char, uint256 wep, uint32 target) external
        isCharacterOwner(char)
        isWeaponOwner(wep)
        isTargetValid(char, wep, target) {
        // avg xp gain from a fight is 9 xp

        uint24 playerRoll = getPlayerPowerRoll(char, wep, uint8((target >> 24) & 0xFF)/*monster trait*/);
        uint24 monsterRoll = getMonsterPowerRoll(getMonsterPower(target));

        if(playerRoll >= monsterRoll) {
            characters.gainXp(char, getXpGainForFight(char, wep, target));
        }
        emit FightOutcome(char, wep, target, playerRoll, monsterRoll);
    }

    function getMonsterPower(uint32 target) public pure returns (uint24) {
        return uint24(target & 0xFFFFFF);
    }

    function getXpGainForFight(uint256 char, uint256 wep, uint32 target) public view returns (uint16) {
        return uint16(getMonsterPower(target)/getPlayerPower(char, wep) * 9);
    }

    function getPlayerPowerRoll(uint256 char, uint256 wep, uint8 monsterTrait) internal returns(uint24) {
        uint256 playerPower = getPlayerPower(char, wep);
        playerPower = playerPower - (playerPower / 10) + (randomSafeMinMax(0, uint256(playerPower) / 10 * 2));
        uint8 playerTrait = characters.getTrait(char);

        uint256 traitBonus = 0;
        if(playerTrait == weapons.getTrait(wep)) {
            traitBonus += 75;
        }
        if(isTraitEffectiveAgainst(playerTrait, monsterTrait)) {
            traitBonus += 75;
        }
        else if(isTraitWeakAgainst(playerTrait, monsterTrait)) {
            traitBonus -= 75;
        }
        return uint24(playerPower * traitBonus);
    }

    function getMonsterPowerRoll(uint24 monsterPower) internal returns(uint24) {
        return uint24(monsterPower - (monsterPower / 10) + (randomSafeMinMax(0, uint256(monsterPower) / 10 * 2)));
    }

    function getPlayerPower(uint256 char, uint256 wep) public view returns (uint24) {
        return characters.getPower(char) * uint24(weapons.getPowerMultiplier10k(wep) / 10000);
    }

    function getTargets(uint256 char, uint256 wep) public view returns (uint32[4] memory) {
        // 4 targets, roll powers based on character + weapon power
        // trait bonuses not accounted for
        // targets expire on the hour
        uint24 playerPower = getPlayerPower(char, wep);

        uint[] memory seedArray = new uint[](3);
        seedArray[0] = char;
        seedArray[1] = playerPower;
        seedArray[2] = getCurrentHour();
        uint256 seed = randomSeeded(combineSeeds(seedArray));

        uint32[4] memory targets;
        for(uint i = 0; i < targets.length; i++) {
            uint24 monsterPower = playerPower - (playerPower / 10) + uint24(randomSeededMinMax(0, playerPower / 10 * 2, seed));
            uint8 monsterTrait = uint8(randomSeededMinMax(0,3, seed));
            targets[i] = monsterPower | (monsterTrait << 24);
        }

        return targets;
    }

    function testFrac(uint pow) public pure returns (uint16) {
        return uint16(pow / 10000);
    }

    function isTraitEffectiveAgainst(uint8 attacker, uint8 defender) public pure returns (bool) {
        if(attacker == 0 && defender == 1) {
            return true;
        }
        if(attacker == 1 && defender == 2) {
            return true;
        }
        if(attacker == 2 && defender == 3) {
            return true;
        }
        if(attacker == 3 && defender == 0) {
            return true;
        }
        return false;
    }

    function isTraitWeakAgainst(uint8 attacker, uint8 defender) public pure returns (bool) {
        if(attacker == 1 && defender == 0) {
            return true;
        }
        if(attacker == 2 && defender == 1) {
            return true;
        }
        if(attacker == 3 && defender == 2) {
            return true;
        }
        if(attacker == 0 && defender == 3) {
            return true;
        }
        return false;
    }
    
    function mintCharacter() public returns (uint256) {
        require(characters.balanceOf(msg.sender) < 4, "You can only have 4 characters!");
        paySkill(mintCharacterFee);
        uint256 tokenID = characters.mint(msg.sender);
        if(weapons.balanceOf(msg.sender) == 0)
            weapons.mint(msg.sender, 0); // first weapon free with a character mint, max 1 star
        return tokenID;
    }
    
    function mintWeapon() public returns (uint256) {
        paySkill(mintWeaponFee);
        uint256 tokenID = weapons.mint(msg.sender, 4); // max 5 star
        return tokenID;
    }
    
    function fillStamina(uint256 character) public isCharacterOwner(character) {
        paySkill(refillStaminaFee);
        characters.setStaminaTimestamp(character, characters.getStaminaTimestamp(character) - characters.getStaminaMaxWait());
    }
    
    function reforgeWeapon(uint256 reforgeID, uint256 burnID) public {
        require(weapons.getLevel(reforgeID) < 127, "Weapons cannot be improved beyond level 128!");
        paySkill(reforgeWeaponFee);
        weapons.levelUp(reforgeID);
        weapons.transferFrom(weapons.ownerOf(burnID), address(0x0), burnID);
    }

    modifier isWeaponOwner(uint256 weapon) {
        require(weapons.ownerOf(weapon) == msg.sender, "Not the weapon owner");
        _;
    }

    modifier isCharacterOwner(uint256 character) {
        require(characters.ownerOf(character) == msg.sender, "Not the character owner");
        _;
    }

    modifier isTargetValid(uint256 character, uint256 weapon, uint32 target) {
        bool foundMatch = false;
        uint32[4] memory targets = getTargets(character, weapon);
        for(uint i = 0; i < targets.length; i++) {
            if(targets[i] == target) {
                foundMatch = true;
            }
        }
        require(foundMatch, "Target invalid");
        _;
    }
    
    function paySkill(uint256 amount) internal {
        require(skill[msg.sender] >= amount, string(abi.encodePacked("Not enough SKILL! Need ",(amount))));
        skill[msg.sender] = skill[msg.sender] - amount;
    }

    function getCurrentHour() public view returns (uint256) {
        // "now" returns unix time since 1970 Jan 1, in seconds
        return now / (1 hours);
    }
}