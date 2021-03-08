pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./util.sol";

contract Characters is ERC721, Util {
  
    constructor () public ERC721("Kryptoknight", "KNT") {
    }

    struct Character {
        uint32 xp; // can calculate level from xp
        uint64 staminaTimestamp; // Time.now-stamp = available stamina, in seconds
        uint64 appearance; // placeholder; cat ears, cup size and shit. PIMP MY KNIGHT
    }
    
    uint256 public mintCharacterFee = 500;
    uint256 public rerollTraitFee = 500;
    uint256 public rerollCosmeticsFee = 500;
    uint256 public refillStaminaFee = 1000;

    uint maxStamina = 200;
    uint timePerStamina = 5 minutes;
    
    Character[] public tokens;

    modifier isCharacterOwner(uint256 characterID) {
        require(ownerOf(characterID) == msg.sender);
        _;
    }

    function mint() public returns (uint256) {
        uint64 appearance = 0;
        uint256 tokenID = tokens.push(Character(0, 0, 0));
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

}
