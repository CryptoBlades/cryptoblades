const { expectEvent, time } = require('@openzeppelin/test-helpers');

const prepareContracts = require('./prepareContracts');

const Characters = artifacts.require('Characters');
const Weapons = artifacts.require('Weapons');
const Shields = artifacts.require('Shields');
const elements = {
  fire: 0,
  earth: 1,
  lightning: 2,
  water: 3,
};

// NOTE: Duplicated from the Characters contract, must be updated if it is changed
const experienceTable = [
  16, 17, 18, 19, 20, 22, 24, 26, 28, 30, 33, 36, 39, 42, 46, 50, 55, 60, 66, 72, 79, 86, 94, 103, 113, 124, 136, 149,
  163, 178, 194, 211, 229, 248, 268, 289, 311, 334, 358, 383, 409, 436, 464, 493, 523, 554, 586, 619, 653, 688, 724,
  761, 799, 838, 878, 919, 961, 1004, 1048, 1093, 1139, 1186, 1234, 1283, 1333, 1384, 1436, 1489, 1543, 1598, 1654,
  1711, 1769, 1828, 1888, 1949, 2011, 2074, 2138, 2203, 2269, 2336, 2404, 2473, 2543, 2614, 2686, 2759, 2833, 2908,
  2984, 3061, 3139, 3218, 3298, 3379, 3461, 3544, 3628, 3713, 3799, 3886, 3974, 4063, 4153, 4244, 4336, 4429, 4523,
  4618, 4714, 4811, 4909, 5008, 5108, 5209, 5311, 5414, 5518, 5623, 5729, 5836, 5944, 6053, 6163, 6274, 6386, 6499,
  6613, 6728, 6844, 6961, 7079, 7198, 7318, 7439, 7561, 7684, 7808, 7933, 8059, 8186, 8314, 8443, 8573, 8704, 8836,
  8969, 9103, 9238, 9374, 9511, 9649, 9788, 9928, 10069, 10211, 10354, 10498, 10643, 10789, 10936, 11084, 11233, 11383,
  11534, 11686, 11839, 11993, 12148, 12304, 12461, 12619, 12778, 12938, 13099, 13261, 13424, 13588, 13753, 13919, 14086,
  14254, 14423, 14593, 14764, 14936, 15109, 15283, 15458, 15634, 15811, 15989, 16168, 16348, 16529, 16711, 16894, 17078,
  17263, 17449, 17636, 17824, 18013, 18203, 18394, 18586, 18779, 18973, 19168, 19364, 19561, 19759, 19958, 20158, 20359,
  20561, 20764, 20968, 21173, 21379, 21586, 21794, 22003, 22213, 22424, 22636, 22849, 23063, 23278, 23494, 23711, 23929,
  24148, 24368, 24589, 24811, 25034, 25258, 25483, 25709, 25936, 26164, 26393, 26623, 26854, 27086, 27319, 27553, 27788,
  28024, 28261, 28499, 28738, 28978,
];

/**
 * @param {string} receiver address of who receives the character
 * @param {string} seed seed for generating the character
 * @param {Characters} [context.characters] instance of the Characters contract
 *
 * @return {Promise<string>} ID of the newly created character
 */
async function createCharacter(receiver, seed, context = {}) {
  const characters = context.characters || (await Characters.deployed());

  const { tx: mintCharaTx } = await characters.mint(receiver, seed);

  const newCharaEvt = await expectEvent.inTransaction(mintCharaTx, characters, 'NewCharacter', { minter: receiver });
  await time.advanceBlock();
  return newCharaEvt.args.character;
}

/**
 * @param {string} receiver address of who receives the weapon
 * @param {string} seed seed for generating the weapon
 * @param {number} element weapon element
 * @param {Weapons} [context.weapons] instance of the Weapons contract
 *
 * @return {Promise<string>} ID of the newly created weapon
 */
async function createWeapon(receiver, seed, element = 0, context = {}) {
  const weapons = context.weapons || (await Weapons.deployed());
  const { tx: mintWeaponTx } = await weapons.mint(receiver, seed, element);

  const newWeaponEvt = await expectEvent.inTransaction(mintWeaponTx, weapons, 'NewWeapon', { minter: receiver });
  await time.advanceBlock();
  return newWeaponEvt.args.weapon;
}

/**
 * @param {string} receiver address of who receives the shield
 * @param {string} seed seed for generating the shield
 * @param {Shields} [context.shields] instance of the Shields contract
 *
 * @return {Promise<string>} ID of the newly created shield
 */
async function createShield(receiver, shieldType, seed, context = {}) {
  const shields = context.shields || (await Shields.deployed());
  const { tx: mintShieldTx } = await shields.mint(receiver, shieldType, seed);

  const newShieldEvt = await expectEvent.inTransaction(mintShieldTx, Shields, 'NewShield', { minter: receiver });
  await time.advanceBlock();
  return newShieldEvt.args.shield;
}

/**
 * @param {string} level level for which we want to get required experience
 *
 * @return {number} required experience for the given level
 */
function getExpForLevel(level) {
  let requiredExp = 0;

  for (let i = 0; i < level; i++) {
    requiredExp += experienceTable[i];
  }

  return requiredExp;
}

/**
 *
 * @param {BN} characterID the ID of the character
 * @param {number} level level to get the character to
 */
async function levelUpTo(characterID, level, context = {}) {
  const characters = context.characters || (await Characters.deployed());
  const currentExp = await characters.getXp(characterID);
  const totalExpRequired = getExpForLevel(level);
  const requiredExp = totalExpRequired - currentExp;

  await characters.gainXp(characterID, requiredExp);
}

/**
 * Ensures that a random result will always be the same for a given seed
 * WARNING: This forwards time to a future date
 * This is sensitive to time changes so it can break easily
 * TODO: Find a more maintainable way to do this
 *
 * @param {number} seed
 * @param {DummyRandom} randoms A DummyRandoms instance
 */
async function setDeterministicRandomSeed(seed, timestamp, randoms) {
  randoms.setRandomNumberForTestingPurposes(seed);
  await time.increaseTo(timestamp);
}

module.exports = {
  createCharacter,
  createWeapon,
  createShield,
  levelUpTo,
  getExpForLevel,
  prepareContracts,
  setDeterministicRandomSeed,
  elements,
};
