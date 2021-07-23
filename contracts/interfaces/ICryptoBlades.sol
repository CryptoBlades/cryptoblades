pragma solidity ^0.6.5;

interface ICryptoBlades {
    // Views
    function inGameOnlyFunds(address addr)
        external
        view
        returns (uint256 funds);

    function getSkillToSubtract(
        uint256 _inGameOnlyFunds,
        uint256 _tokenRewards,
        uint256 _skillNeeded
    )
        external
        view
        returns (
            uint256 fromInGameOnlyFunds,
            uint256 fromTokenRewards,
            uint256 fromUserWallet
        );

    function getTokenRewardsFor(address wallet)
        external
        view
        returns (uint256 rewards);

    function transferInGameOnlyFunds(
        address from,
        address to,
        uint256 skillAmount
    ) external;

    function transferTokenRewards(
        address from,
        address to,
        uint256 skillAmount
    ) external;
}
