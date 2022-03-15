const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const Junk = artifacts.require("Junk");
const RaidTrinket = artifacts.require("RaidTrinket");
const KeyLootbox = artifacts.require("KeyLootbox");

module.exports = async function (deployer, network, accounts) {
    const junk = await upgradeProxy(Junk.address, Junk, { deployer });
    const trinket = await upgradeProxy(RaidTrinket.address, RaidTrinket, { deployer });
    const keybox = await upgradeProxy(KeyLootbox.address, KeyLootbox, { deployer });

    let junkSupply = await junk.totalSupply();
    let trinketSupply = await trinket.totalSupply();
    let keyboxSupply = await keybox.totalSupply();

    await junk.grantRole(await junk.GAME_ADMIN(), accounts[0]);
    await trinket.grantRole(await trinket.GAME_ADMIN(), accounts[0]);
    await keybox.grantRole(await keybox.GAME_ADMIN(), accounts[0]);

    // these calls and their functions can be removed once we've run the migration on all networks
    // (won't be needed for new networks)
    await junk.setNextTokenID(junkSupply);
    await trinket.setNextTokenID(trinketSupply);
    await keybox.setNextTokenID(keyboxSupply);
};