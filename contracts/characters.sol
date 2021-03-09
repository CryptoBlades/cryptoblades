pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./data.sol";

contract Characters is ERC721, Data {
  
    address main;

    constructor (address source) public ERC721("Kryptoknight", "KNT") {
        main = source;
    }

    struct Character {
        uint32 xp; // can calculate level from xp
        uint64 staminaTimestamp; // standard timestamp in seconds-resolution marking regen start from 0
        uint64 appearance; // placeholder; cat ears, cup size and shit. PIMP MY KNIGHT
    }
    
    Character[] public tokens;

    modifier restricted() {
        require(main == msg.sender);
        _;
    }

    modifier isCharacterOwner(uint256 characterID) {
        require(ownerOf(characterID) == msg.sender);
        _;
    }

    function mint() public restricted returns (uint256) {
        uint64 appearance = 0;
        uint256 tokenID = tokens.length;
        tokens.push(Character(0, 0, 0));
        _mint(msg.sender, tokenID);
        return tokenID;
    }

    function getRequiredXpForLevel(uint8 level) public pure returns (uint16) {
        uint16 xp = 16;
        for(uint16 i = 1; i < level; i++) {
            if (xp <= 112)
            {
                xp += xp / 10;
            }
            else
            {
                xp += (i-14) + 1;
            }
        }
        return xp;
    }

    function getXp(uint256 id) public view returns (uint32) {
        return tokens[id].xp;
    }

    function setXp(uint256 id, uint32 xp) public restricted {
        tokens[id].xp = xp;
    }

    function getAppearance(uint256 id) public view returns (uint64) {
        return tokens[id].appearance;
    }

    function getStaminaTimestamp(uint256 id) public view returns (uint64) {
        return tokens[id].staminaTimestamp;
    }

    function setStaminaTimestamp(uint256 id, uint64 timestamp) public restricted {
        tokens[id].staminaTimestamp = timestamp;
    }

}
