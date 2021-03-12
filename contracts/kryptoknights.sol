pragma solidity ^0.6.0;

//import "./ownable.sol";
import "./characters.sol";
import "./weapons.sol";
import "./data.sol";

contract Kryptoknights is Data {
    
    Characters characters;
    Weapons weapons;
    
    constructor() public /*Ownable()*/ {
        characters = new Characters(address(this));
        weapons = new Weapons(address(this));
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
    
    function mintCharacter() public payable requiredPay(mintCharacterFee) {
        uint256 tokenID = characters.mint();
        emit NewCharacter(tokenID);
    }
    
    function mintWeapon() public payable requiredPay(mintWeaponFee) {
        uint256 tokenID = weapons.mint();
        emit NewWeapon(tokenID);
    }
    
    function fillStamina(uint256 character) public payable isCharacterOwner(character) requiredPay(refillStaminaFee) {
        characters.setStaminaTimestamp(character, characters.getStaminaTimestamp(character) - getStaminaMaxWait());
    }
    
    function reforgeWeapon(uint256 reforgeID, uint256 burnID) public payable requiredPay(reforgeWeaponFee) {

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
    
    modifier requiredPay(uint256 amount) {
        require(msg.value == amount, "Incorrect payment");
        _;
    }
    
}