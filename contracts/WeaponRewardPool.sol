pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "./weapons.sol";
import "./FightUtil.sol";

// contract WeaponRewardPool is
//     IERC721ReceiverUpgradeable,
//     Initializable,
//     AccessControlUpgradeable
// {
//     Weapons public weapons;
//     address weaponRewardPoolAddress;

//     function initialize(Weapons _weapons) public initializer {
//         __AccessControl_init();

//         _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

//         weapons = _weapons;
//     }
    
//     function store(uint256 weaponId) internal {
//         //TODO: not burn but transfer to pool

//     }
// }

contract WeaponRewardPool is AccessControlUpgradeable {

    using ABDKMath64x64 for int128;

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    struct UnlikelyFightMath {
        int128 totalPlayerFightPower;
        int128 playerMin;
        int128 playerMax;
        int128 playerRange;
        int128 targetMin;
        int128 targetMax;
        int128 targetRange;
        int128 rollingTotal;
    }

    function mintUnlikelyFightWeapon() public restricted returns (uint256) {
        // uint256 seed = randoms.getRandomSeed(msg.sender);
        // return weapons.mint(msg.sender, seed);
    }

    function poolUnlikelyFightWeapon(uint256 unlikelyFightWeaponId) public restricted {
        // weapons.safeTransferFrom(msg.sender, weaponPoolAddress, unlikelyFightWeaponId);
    }

    function isUnlikelyFight(
        uint24 playerFightPower,
        uint24 traitsCWE,
        uint24 targetPower,
        int128 oneFrac,
        int128 fightTraitBonus
    ) public pure returns(bool) {
        UnlikelyFightMath memory math;
        math.totalPlayerFightPower = FightUtil.getPlayerTraitBonusAgainst(traitsCWE, oneFrac, fightTraitBonus) * playerFightPower;
        math.playerMin = ABDKMath64x64.divu(uint256(math.totalPlayerFightPower * 9), 10);
        math.playerMax = ABDKMath64x64.divu(uint256(math.totalPlayerFightPower * 11), 10);
        math.playerRange = math.playerMax - math.playerMin;
        math.targetMin = ABDKMath64x64.divu(uint256(targetPower * 9), 10);
        math.targetMax = ABDKMath64x64.divu(uint256(targetPower * 11), 10);
        math.targetRange = math.targetMax - math.targetMin;
        math.rollingTotal = 0;

        if (math.playerMin < math.targetMin) {
            // case 1: player rolls below enemy minimum
            math.rollingTotal = (math.targetMin - math.playerMin) / math.playerRange;
            // case 2: enemy rolls above player maximum
            math.rollingTotal += (1 - math.rollingTotal) * ((math.targetMax - math.playerMax) / math.targetRange);
            // case 3: 1 and 2 are not true, both values are in the overlap range
            math.rollingTotal += (1 - math.rollingTotal) * ABDKMath64x64.divu(5, 10);
            //since this is chance the enemy wins, we negate it
            math.rollingTotal = 1 - math.rollingTotal;
        }

        return math.rollingTotal <= ABDKMath64x64.divu(3, 10);
    }

    // function _getPlayerTraitBonusAgainst(uint24 traitsCWE, int128 oneFrac, int128 fightTraitBonus) private pure returns (int128) {
    //     int128 traitBonus = oneFrac;
    //     uint8 characterTrait = uint8(traitsCWE & 0xFF);
    //     if(characterTrait == (traitsCWE >> 8) & 0xFF/*wepTrait*/) {
    //         traitBonus = traitBonus.add(fightTraitBonus);
    //     }
    //     if(isTraitEffectiveAgainst(characterTrait, uint8(traitsCWE >> 16)/*enemy*/)) {
    //         traitBonus = traitBonus.add(fightTraitBonus);
    //     }
    //     else if(isTraitEffectiveAgainst(uint8(traitsCWE >> 16)/*enemy*/, characterTrait)) {
    //         traitBonus = traitBonus.sub(fightTraitBonus);
    //     }
    //     return traitBonus;
    // }

    // function isTraitEffectiveAgainst(uint8 attacker, uint8 defender) public pure returns (bool) {
    //     return (((attacker + 1) % 4) == defender); // Thanks to Tourist
    // }

    modifier restricted() {
        require(hasRole(GAME_ADMIN, msg.sender), "Not game admin");
        _;
    }
}