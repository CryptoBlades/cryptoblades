const StakingRewards = artifacts.require("StakingRewards");

module.exports = async function (deployer, network, accounts) {
  if (network === 'bsctestnet') {
    const skillTokenAddress = '0x3560b77666e9ebe6ec532ccb4223a4843e0c5aa7';

    await deployer.deploy(StakingRewards, accounts[0], accounts[0], skillTokenAddress, skillTokenAddress, 7 * 24 * 60 * 60);
  }
};
