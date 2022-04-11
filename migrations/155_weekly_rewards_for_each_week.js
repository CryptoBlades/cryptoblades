const {upgradeProxy} = require('@openzeppelin/truffle-upgrades');

const SimpleQuests = artifacts.require('SimpleQuests');

module.exports = async function (deployer) {
  const simpleQuests = await upgradeProxy(SimpleQuests.address, SimpleQuests, {deployer});

  await simpleQuests.setWeeklyReward(2, 3, 2, '0x0000000000000000000000000000000000000000', 0, 1, 45);
  await simpleQuests.setWeeklyReward(1, 1, 5, '0x0000000000000000000000000000000000000000', 0, 2, 25);
  await simpleQuests.setWeeklyReward(1, 2, 4, '0x0000000000000000000000000000000000000000', 0, 3, 40);
  await simpleQuests.setWeeklyReward(3, 1, 2, '0x0000000000000000000000000000000000000000', 0, 4, 40);
  await simpleQuests.setWeeklyReward(2, 4, 1, '0x0000000000000000000000000000000000000000', 0, 5, 45);
  await simpleQuests.setWeeklyReward(3, 0, 38, '0x0000000000000000000000000000000000000000', 0, 6, 35);
  await simpleQuests.setWeeklyReward(3, 0, 20, '0x0000000000000000000000000000000000000000', 0, 7, 25);
  await simpleQuests.setWeeklyReward(3, 0, 60, '0x0000000000000000000000000000000000000000', 0, 8, 45);
  await simpleQuests.setWeeklyReward(1, 2, 3, '0x0000000000000000000000000000000000000000', 0, 9, 30);
  await simpleQuests.setWeeklyReward(1, 3, 1, '0x0000000000000000000000000000000000000000', 0, 10, 40);
  await simpleQuests.setWeeklyReward(2, 2, 4, '0x0000000000000000000000000000000000000000', 0, 11, 30);
  await simpleQuests.setWeeklyReward(1, 2, 2, '0x0000000000000000000000000000000000000000', 0, 12, 25);
  await simpleQuests.setWeeklyReward(2, 3, 1, '0x0000000000000000000000000000000000000000', 0, 13, 30);
  await simpleQuests.setWeeklyReward(2, 2, 3, '0x0000000000000000000000000000000000000000', 0, 14, 25);
  await simpleQuests.setWeeklyReward(3, 1, 1, '0x0000000000000000000000000000000000000000', 0, 15, 30);

  await simpleQuests.setWeeklyReward(2, 3, 2, '0x0000000000000000000000000000000000000000', 0, 16, 45);
  await simpleQuests.setWeeklyReward(1, 1, 5, '0x0000000000000000000000000000000000000000', 0, 17, 25);
  await simpleQuests.setWeeklyReward(1, 2, 4, '0x0000000000000000000000000000000000000000', 0, 18, 40);
  await simpleQuests.setWeeklyReward(3, 1, 2, '0x0000000000000000000000000000000000000000', 0, 19, 40);
  await simpleQuests.setWeeklyReward(2, 4, 1, '0x0000000000000000000000000000000000000000', 0, 20, 45);
  await simpleQuests.setWeeklyReward(3, 0, 38, '0x0000000000000000000000000000000000000000', 0, 21, 35);
  await simpleQuests.setWeeklyReward(3, 0, 20, '0x0000000000000000000000000000000000000000', 0, 22, 25);
  await simpleQuests.setWeeklyReward(3, 0, 60, '0x0000000000000000000000000000000000000000', 0, 23, 45);
  await simpleQuests.setWeeklyReward(1, 2, 3, '0x0000000000000000000000000000000000000000', 0, 24, 30);
  await simpleQuests.setWeeklyReward(1, 3, 1, '0x0000000000000000000000000000000000000000', 0, 25, 40);
  await simpleQuests.setWeeklyReward(2, 2, 4, '0x0000000000000000000000000000000000000000', 0, 26, 30);
  await simpleQuests.setWeeklyReward(1, 2, 2, '0x0000000000000000000000000000000000000000', 0, 27, 25);
  await simpleQuests.setWeeklyReward(2, 3, 1, '0x0000000000000000000000000000000000000000', 0, 28, 30);
  await simpleQuests.setWeeklyReward(2, 2, 3, '0x0000000000000000000000000000000000000000', 0, 29, 25);
  await simpleQuests.setWeeklyReward(3, 1, 1, '0x0000000000000000000000000000000000000000', 0, 30, 30);

  await simpleQuests.setWeeklyReward(2, 3, 2, '0x0000000000000000000000000000000000000000', 0, 31, 45);
  await simpleQuests.setWeeklyReward(1, 1, 5, '0x0000000000000000000000000000000000000000', 0, 32, 25);
  await simpleQuests.setWeeklyReward(1, 2, 4, '0x0000000000000000000000000000000000000000', 0, 33, 40);
  await simpleQuests.setWeeklyReward(3, 1, 2, '0x0000000000000000000000000000000000000000', 0, 34, 40);
  await simpleQuests.setWeeklyReward(2, 4, 1, '0x0000000000000000000000000000000000000000', 0, 35, 45);
  await simpleQuests.setWeeklyReward(3, 0, 38, '0x0000000000000000000000000000000000000000', 0, 36, 35);
  await simpleQuests.setWeeklyReward(3, 0, 20, '0x0000000000000000000000000000000000000000', 0, 37, 25);
  await simpleQuests.setWeeklyReward(3, 0, 60, '0x0000000000000000000000000000000000000000', 0, 38, 45);
  await simpleQuests.setWeeklyReward(1, 2, 3, '0x0000000000000000000000000000000000000000', 0, 39, 30);
  await simpleQuests.setWeeklyReward(1, 3, 1, '0x0000000000000000000000000000000000000000', 0, 40, 40);
  await simpleQuests.setWeeklyReward(2, 2, 4, '0x0000000000000000000000000000000000000000', 0, 41, 30);
  await simpleQuests.setWeeklyReward(1, 2, 2, '0x0000000000000000000000000000000000000000', 0, 42, 25);
  await simpleQuests.setWeeklyReward(2, 3, 1, '0x0000000000000000000000000000000000000000', 0, 43, 30);
  await simpleQuests.setWeeklyReward(2, 2, 3, '0x0000000000000000000000000000000000000000', 0, 44, 25);
  await simpleQuests.setWeeklyReward(3, 1, 1, '0x0000000000000000000000000000000000000000', 0, 45, 30);

  await simpleQuests.setWeeklyReward(2, 3, 2, '0x0000000000000000000000000000000000000000', 0, 46, 45);
  await simpleQuests.setWeeklyReward(1, 1, 5, '0x0000000000000000000000000000000000000000', 0, 47, 25);
  await simpleQuests.setWeeklyReward(1, 2, 4, '0x0000000000000000000000000000000000000000', 0, 48, 40);
  await simpleQuests.setWeeklyReward(3, 1, 2, '0x0000000000000000000000000000000000000000', 0, 49, 40);
  await simpleQuests.setWeeklyReward(2, 4, 1, '0x0000000000000000000000000000000000000000', 0, 50, 45);
  await simpleQuests.setWeeklyReward(3, 0, 38, '0x0000000000000000000000000000000000000000', 0, 51, 35);
  await simpleQuests.setWeeklyReward(3, 0, 20, '0x0000000000000000000000000000000000000000', 0, 52, 25);
  await simpleQuests.setWeeklyReward(3, 0, 60, '0x0000000000000000000000000000000000000000', 0, 53, 45);
};
