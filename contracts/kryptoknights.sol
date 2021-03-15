pragma solidity ^0.6.0;

//import "./ownable.sol";
import "./characters.sol";
import "./weapons.sol";
import "./data.sol";

contract Kryptoknights is Data {

    Characters public characters;
    Weapons public weapons;

    constructor() public /*Ownable()*/ {
        characters = new Characters(address(this));
        weapons = new Weapons(address(this));
    }

    mapping (address => uint256) public skill;
    
    event FightOutcome(uint256 character, uint16 target, uint16 outcome);
    event LevelUp(uint256 character, uint16 level);
    event NewCharacter(uint256 character);
    event NewWeapon(uint256 weapon);

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
    
    function mintCharacter() public {
        paySkill(mintCharacterFee);
        uint256 tokenID = characters.mint();
        emit NewCharacter(tokenID);
    }
    
    function mintWeapon() public {
        paySkill(mintWeaponFee);
        uint256 tokenID = weapons.mint();
        emit NewWeapon(tokenID);
    }
    
    function fillStamina(uint256 character) public isCharacterOwner(character) {
        paySkill(refillStaminaFee);
        characters.setStaminaTimestamp(character, characters.getStaminaTimestamp(character) - getStaminaMaxWait());
    }
    
    function reforgeWeapon(uint256 reforgeID, uint256 burnID) public {
        paySkill(reforgeWeaponFee);

        uint8 burnWeaponStar = weapons.getStars(burnID);
        uint16 xpGain = (burnWeaponStar - 1) * 8 + 16;
        weapons.gainXp(reforgeID, xpGain);

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

    modifier isTargetValid(uint256 character, uint16 target) {
        bool foundMatch = false;
        uint16[4] memory targets = getTargets(character);
        for(uint16 i = 0; i < targets.length; i++) {
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
}