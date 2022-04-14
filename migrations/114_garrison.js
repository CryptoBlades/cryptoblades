const {upgradeProxy, deployProxy} = require('@openzeppelin/truffle-upgrades');

const Characters = artifacts.require("Characters");
const Garrison = artifacts.require("Garrison");

module.exports = async function (deployer) {
  const characters = await upgradeProxy(Characters.address, Characters, {deployer});
  const garrison = await deployProxy(Garrison, [characters.address], { deployer });

  await characters.migrateTo_1a19cbb(garrison.address);
  const NO_OWN_LIMIT = await characters.NO_OWNED_LIMIT();
  const character_GAME_ADMIN = await characters.GAME_ADMIN();
  await characters.grantRole(NO_OWN_LIMIT, garrison.address);
  await characters.grantRole(character_GAME_ADMIN, garrison.address);

  const garrison_GAME_ADMIN = await garrison.GAME_ADMIN();
  await garrison.grantRole(garrison_GAME_ADMIN, characters.address);
  await garrison.allowToken(characters.address);
};
