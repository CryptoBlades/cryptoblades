const { deployProxy } = require('@openzeppelin/truffle-upgrades');

const SkillToken = artifacts.require("SkillToken");
const CryptoBlades = artifacts.require("CryptoBlades");
const NFTMarket = artifacts.require("NFTMarket");

module.exports = async function (deployer, network) {
  let skillTokenAddress;
  if (network === 'bscmainnet' || network === 'bscmainnet-fork') {
    skillTokenAddress = '0x154a9f9cbd3449ad22fdae23044319d6ef2a1fab';
  }
  else {
    skillTokenAddress = SkillToken.address;
  }

  await deployProxy(NFTMarket, [skillTokenAddress, CryptoBlades.address], { deployer });
};
