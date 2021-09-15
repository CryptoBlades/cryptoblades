pragma solidity >=0.6.0;

interface ISalvageable {
    function discard(uint256 id) external;
    function getStars(uint256 id) external view returns (uint8);
}
