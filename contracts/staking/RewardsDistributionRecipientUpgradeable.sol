pragma solidity ^0.6.2;

// Inheritance
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// https://docs.synthetix.io/contracts/source/contracts/rewardsdistributionrecipient
abstract contract RewardsDistributionRecipientUpgradeable is Initializable, OwnableUpgradeable {
    address public rewardsDistribution;

    function __RewardsDistributionRecipient_init() internal initializer {
        __Ownable_init();
        __RewardsDistributionRecipient_init_unchained();
    }

    function __RewardsDistributionRecipient_init_unchained() internal initializer {
    }

    function notifyRewardAmount(uint256 reward) external virtual;

    modifier onlyRewardsDistribution() {
        require(
            msg.sender == rewardsDistribution,
            "Caller is not RewardsDistribution contract"
        );
        _;
    }

    function setRewardsDistribution(address _rewardsDistribution)
        external
        onlyOwner
    {
        rewardsDistribution = _rewardsDistribution;
    }
}
