const {upgradeProxy} = require('@openzeppelin/truffle-upgrades');

const SimpleQuests = artifacts.require('SimpleQuests');
const SkillToken = artifacts.require("SkillToken");
const CryptoBlades = artifacts.require("CryptoBlades");
const PartnerVault = artifacts.require("PartnerVault");
const Weapons = artifacts.require("Weapons");
const Junk = artifacts.require("Junk");

module.exports = async function (deployer, network, accounts) {
  const simpleQuests = await upgradeProxy(SimpleQuests.address, SimpleQuests, {deployer});
  const partnerVault = await upgradeProxy(PartnerVault.address, PartnerVault, {deployer});
  if (network === "development"
  || network === "development-fork"
  || network === 'bsctestnet'
  || network === 'bsctestnet-fork'
  || network === 'hecotestnet'
  || network === 'okextestnet'
  || network === 'polygontestnet'
  || network === 'avaxtestnet'
  || network === 'avaxtestnet-fork'
  || network === 'auroratestnet'
  || network === 'kavatestnet'
  || network === 'skaletestnet' || network === 'coinextestnet' || network === 'metertestnet') {
    const pickableTier = 20;
    const walletTier = 30;

    const nullAddress = "0x0000000000000000000000000000000000000000";
    
    // Test wallet quests
    simpleQuests.addNewQuestTemplate(walletTier,1,0,1,nullAddress,1,0,2,nullAddress,0,0,0); // weapon
    simpleQuests.addNewQuestTemplate(walletTier,2,0,1,nullAddress,2,0,2,nullAddress,0,0,0); // junk
    simpleQuests.addNewQuestTemplate(walletTier,3,0,5,nullAddress,3,0,6,nullAddress,0,0,0); // dust
    simpleQuests.addNewQuestTemplate(walletTier,7,0,10,nullAddress,7,0,11,nullAddress,0,0,0); // soul
    simpleQuests.addNewQuestTemplate(walletTier,10,0,1,Weapons.address,2,0,1,nullAddress,0,0,0); // external (weapon example)
    simpleQuests.addNewQuestTemplate(walletTier,11,0,1,Junk.address,12,0,1,nullAddress,0,0,0); // hold (junk example)
    simpleQuests.addNewQuestTemplate(walletTier,10,0,1000,SkillToken.address,12,0,1,nullAddress,0,0,0); // skill (ext erc20 test)

    // Test pickable quests
    simpleQuests.addNewQuestTemplate(pickableTier,1,0,1,nullAddress,1,0,2,nullAddress,0,0,0); // weapon
    simpleQuests.addNewQuestTemplate(pickableTier,2,0,1,nullAddress,2,0,2,nullAddress,0,0,0); // junk
    simpleQuests.addNewQuestTemplate(pickableTier,3,0,5,nullAddress,3,0,6,nullAddress,0,0,0); // dust
    simpleQuests.addNewQuestTemplate(pickableTier,7,0,10,nullAddress,7,0,11,nullAddress,0,0,0); // soul
    simpleQuests.addNewQuestTemplate(pickableTier,8,0,10,nullAddress,9,0,100,nullAddress,0,0,0); // raid
    simpleQuests.addNewQuestTemplate(pickableTier,10,0,1,Weapons.address,2,0,1,nullAddress,0,0,0); // external (weapon example)
    simpleQuests.addNewQuestTemplate(pickableTier,11,0,1,Junk.address,12,0,1,nullAddress,0,0,0); // hold (junk example)
  }
};
