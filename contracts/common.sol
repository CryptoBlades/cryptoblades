pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";

library Common {
    using ABDKMath64x64 for int128;
    using SafeMath for uint256;
    using SafeMath for uint8;

    function isTraitEffectiveAgainst(uint8 attacker, uint8 defender) internal pure returns (bool) {
        return (((attacker + 1) % 4) == defender); // Thanks to Tourist
    }

    function getPlayerPower(
        uint24 basePower,
        int128 weaponMultiplier,
        uint24 bonusPower
    ) internal pure returns(uint24) {
        return uint24(weaponMultiplier.mulu(basePower).add(bonusPower));
    }

    function getBonusRankingPoints(uint256 weakerPower, uint256 strongerPower) internal pure returns (uint256) {
        // @TODO once tested transform to save gas: 
        // X < Y: (1 - ( (1.3*(x-y)/0.6*y) + (0.7*(y-x)/0.6*x) )) * 0.5
        // Note: Formula hard-copied in PvPArenaMatchMaking.vue due to contract size limitations in PvPArena.sol
        uint256 bonusRanking;

        uint256 strongerMinRoll = strongerPower.mul(90).div(100);
        uint256 strongerMaxRoll = strongerPower.mul(110).div(100);
 
        uint256 weakerMinRoll = weakerPower.mul(90).div(100);
        uint256 weakerMaxRoll = weakerPower.mul(110).div(100);

        uint256 strongerRollSpread = strongerMaxRoll.sub(strongerMinRoll);
        uint256 weakerRollSpread = weakerMaxRoll.sub(weakerMinRoll);

        uint256 rollOverlap = weakerMaxRoll.sub(strongerMinRoll);
       
        uint256 strongerRollChanceToOverlap = rollOverlap.mul(100).div(strongerRollSpread);

        uint256 weakerRollChanceToOverlap = rollOverlap.mul(100).div(weakerRollSpread);
        // A * B * 100 / 10000 * 2
        uint256 winChance = strongerRollChanceToOverlap.mul(weakerRollChanceToOverlap).mul(100).div(20000);

        if (winChance < 50) {
            bonusRanking = getBonusRankingPointFormula(uint256(50).sub(winChance));
            return bonusRanking;
        }
    }

    function getBonusRankingPointFormula(uint256 processedWinChance) internal pure returns (uint256) {
        // Note: Formula hard-copied in PvPArenaMatchMaking.vue due to contract size limitations in PvPArena.sol
        if (processedWinChance <= 40) {
            // Equivalent to (1.06**processedWinChance)
            return (53**processedWinChance).div(50**processedWinChance);
        } else {
            // Equivalent to (1.5**(1.3*processedWinChance - 48)) + 7
            return ((3**(processedWinChance.mul(13).div(10).sub(48))).div(2**(processedWinChance.mul(13).div(10).sub(48)))).add(7);
        }
    }

    function getPlayerPowerBase100(
        uint256 basePower,
        int128 weaponMultiplier,
        uint24 bonusPower
    ) internal pure returns (uint24) {
        // we divide total power by 100 and add the base of 1000
       return uint24 (weaponMultiplier.mulu(basePower).add(bonusPower).div(100).add(1000));  
    }
    function getPowerAtLevel(uint8 level) internal pure returns (uint24) {
        // does not use fixed points since the numbers are simple
        // the breakpoints every 10 levels are floored as expected
        // level starts at 0 (visually 1)
        // 1000 at lvl 1
        // 9000 at lvl 51 (~3months)
        // 22440 at lvl 105 (~3 years)
        // 92300 at lvl 255 (heat death of the universe)
        return uint24(
            uint256(1000)
                .add(level.mul(10))
                .mul(level.div(10).add(1))
        );
    }

    function adjustDecimals(uint256 amount, uint256 decimals) internal pure returns (uint256 adjustedAmount){
        if(decimals > 18) {
            adjustedAmount = amount.mul(10**uint(decimals - 18));
        } else {
            adjustedAmount = amount.div(10**uint(18 - decimals));
        }
    }
}
