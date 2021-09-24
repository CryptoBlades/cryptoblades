const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const CryptoBlades = artifacts.require("CryptoBlades");
const Blacksmith = artifacts.require("Blacksmith");
const Weapons = artifacts.require("Weapons");
const WeaponCosmetics = artifacts.require("WeaponCosmetics");
const Characters = artifacts.require("Characters");
const CharacterCosmetics = artifacts.require("CharacterCosmetics");

module.exports = async function (deployer, network, accounts) {

  await upgradeProxy(CryptoBlades.address, CryptoBlades, { deployer });

  const weapons = await upgradeProxy(Weapons.address, Weapons, { deployer });
  
  const weaponCosmetics = await deployProxy(WeaponCosmetics, [weapons.address], { deployer });
  
  const characters = await Characters.deployed();

  const charactersCosmetics = await deployProxy(CharacterCosmetics, [characters.address], { deployer });
  
  const blacksmith = await upgradeProxy(Blacksmith.address, Blacksmith, { deployer });

  let weaponCosmeticItemIndex = await blacksmith.ITEM_COSMETIC_WEAPON();
  let characterCosmeticItemIndex = await blacksmith.ITEM_COSMETIC_CHARACTER();
  let cosmeticWeaponSeriesIndices = [];
  let cosmeticWeaponFlatPrices = [];
  let cosmeticCharacterSeriesIndices = [];
  let cosmeticCharacterFlatPrices = [];

  // basic effects
  for(let i = 1; i < 6; i++) {
    cosmeticWeaponSeriesIndices.push(i);
    cosmeticWeaponFlatPrices.push(web3.utils.toWei('0.1', 'ether'));

    cosmeticCharacterSeriesIndices.push(i);
    cosmeticCharacterFlatPrices.push(web3.utils.toWei('0.1', 'ether'));
  }

  // premium effects weapons
  for(let i = 6; i < 16; i++) {
    cosmeticWeaponSeriesIndices.push(i);
    cosmeticWeaponFlatPrices.push(web3.utils.toWei('0.5', 'ether'));
  }
  // plain borders weapons
  cosmeticWeaponSeriesIndices.push(16);
  cosmeticWeaponFlatPrices.push(web3.utils.toWei('0.4', 'ether'));
  cosmeticWeaponSeriesIndices.push(17);
  cosmeticWeaponFlatPrices.push(web3.utils.toWei('0.3', 'ether'));
  cosmeticWeaponSeriesIndices.push(18);
  cosmeticWeaponFlatPrices.push(web3.utils.toWei('0.2', 'ether'));
  cosmeticWeaponSeriesIndices.push(19);
  cosmeticWeaponFlatPrices.push(web3.utils.toWei('0.1', 'ether'));

  // premium effects characters
  for(let i = 6; i < 15; i++) {
    cosmeticCharacterSeriesIndices.push(i);
    cosmeticCharacterFlatPrices.push(web3.utils.toWei('0.5', 'ether'));
  }        
  // plain borders characters
  cosmeticCharacterSeriesIndices.push(15);
  cosmeticCharacterFlatPrices.push(web3.utils.toWei('0.4', 'ether'));
  cosmeticCharacterSeriesIndices.push(16);
  cosmeticCharacterFlatPrices.push(web3.utils.toWei('0.3', 'ether'));
  cosmeticCharacterSeriesIndices.push(17);
  cosmeticCharacterFlatPrices.push(web3.utils.toWei('0.2', 'ether'));
  cosmeticCharacterSeriesIndices.push(18);
  cosmeticCharacterFlatPrices.push(web3.utils.toWei('0.1', 'ether'));

  await blacksmith.setFlatPriceOfItemSeries(
    weaponCosmeticItemIndex,
    cosmeticWeaponSeriesIndices,
    cosmeticWeaponFlatPrices
  );
  await blacksmith.setFlatPriceOfItemSeries(
    characterCosmeticItemIndex,
    cosmeticCharacterSeriesIndices,
    cosmeticCharacterFlatPrices
  );
  await blacksmith.setAddressOfItem(weaponCosmeticItemIndex, weaponCosmetics.address);
  await blacksmith.setAddressOfItem(characterCosmeticItemIndex, charactersCosmetics.address);

  const weaponCosmetics_GAME_ADMIN = await weaponCosmetics.GAME_ADMIN();
  await weaponCosmetics.grantRole(weaponCosmetics_GAME_ADMIN, blacksmith.address);
  
  const charactersCosmetics_GAME_ADMIN = await charactersCosmetics.GAME_ADMIN();
  await charactersCosmetics.grantRole(charactersCosmetics_GAME_ADMIN, blacksmith.address);
};