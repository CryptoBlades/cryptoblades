const { expectEvent, time } = require('@openzeppelin/test-helpers');

const Characters = artifacts.require('Characters');
const Weapons = artifacts.require('Weapons');

/**
 * @param {string} receiver address of who receives the character
 * @param {string} seed seed for generating the character
 * @param {Characters} [context.characters] instance of the Characters contract
 * 
 * @return {Promise<string>} characterID of the newly created character
 */
async function createCharacter(receiver, seed, context = {}) {
  const characters = context.characters || await Characters.deployed();

  const { tx: mintCharaTx } = await characters.mint(receiver, seed);

  const newCharaEvt = await expectEvent.inTransaction(mintCharaTx, characters, 'NewCharacter', { minter: receiver });
  await time.advanceBlock();
  return newCharaEvt.args.character;
}

/**
 * @param {string} receiver address of who receives the weapon
 * @param {string} seed seed for generating the weapon
 * @param {Weapons} [context.weapons] instance of the Weapons contract
 * 
 * @return {Promise<string>} weaponID of the newly created weapon
 */
async function createWeapon(receiver, seed, context = {}) {
  const weapons = context.weapons || await Weapons.deployed();
  const { tx: mintWeaponTx } = await weapons.mint(receiver, seed);

  const newWeaponEvt = await expectEvent.inTransaction(mintWeaponTx, weapons, 'NewWeapon', { minter: receiver });
  await time.advanceBlock();
  return newWeaponEvt.args.weapon;
}

module.exports = {
  createCharacter,
  createWeapon,
};