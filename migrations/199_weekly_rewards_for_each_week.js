const {upgradeProxy} = require('@openzeppelin/truffle-upgrades');

const SimpleQuests = artifacts.require('SimpleQuests');

module.exports = async function (deployer) {
  const simpleQuests = await upgradeProxy(SimpleQuests.address, SimpleQuests, {deployer});
  //TODO: Add weekly rewards for 53 possible weeks
  // await simpleQuests.setWeeklyReward(1, 1, 1, '0x0000000000000000000000000000000000000000', 23, 22, 30);
  // await simpleQuests.setWeeklyReward(2, 1, 2, '0x0000000000000000000000000000000000000000', 21, 23, 20);
};
