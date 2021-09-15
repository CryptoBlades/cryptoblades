pragma solidity >=0.6.0;

import "./ISalvageable.sol";

interface IReforgeable is ISalvageable {
    function getBurnPoints(uint256 id) external view returns (uint8 pointsLB, uint8 points4B, uint8 points5B);
}
