// SPDX-License-Identifier: MIT

interface IRandoms {
    // Views
    function getRandomSeed(address user) external view returns (uint256 seed);
}
