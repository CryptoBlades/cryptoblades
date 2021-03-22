const CryptoBlades = artifacts.require('CryptoBlades');
CryptoBlades.numberFormat = 'String';
const Characters = artifacts.require('Characters');
Characters.numberFormat = 'String';
const Weapons = artifacts.require('Weapons');
Weapons.numberFormat = 'String';

function truffleTupleToArray(tuple) {
  const out = [];
  for (const key in tuple) {
    if (Object.hasOwnProperty.call(tuple, key)) {
      out[key] = tuple[key];
    }
  }
  return out;
}

function sample(arr) {
  const i = Math.floor(Math.random() * arr.length);
  return arr[i];
}

function mapValues(obj, fn) {
  const out = {};
  for (const key in obj) {
    if (Object.hasOwnProperty.call(obj, key)) {
      const element = obj[key];
      out[key] = fn(element, key);
    }
  }
  return out;
}

//stress test
//turn stamina off so we dont have to wait for days

// test 1
// mint 1000 characters
// battle for 10 days without addional mints (daily fights: 10)
// output contract balance
// output player wealth: total and richest player

// test 2
// mint 1000 characters
// craft as soon as the user has enough to mint (keep battling until then)
// use the strongest weapon they have .getPowerMultiplierForTrait(wepId,charTrait)
// 10 day duration
// output contract balance
// output player wealth: total and richest player

// test 3
// mint 1000 characters
// output

// const mintedCharacters = [];
// for (const event of await characters.getPastEvents('NewCharacter')) {
//   const characterId = event.args.character;

//   const [xp, level, trait, staminaTimestamp, appearance] =
//     truffleTupleToArray(await characters.get(characterId, { from: accounts[0] }));

//   mintedCharacters.push({ xp, level, trait, staminaTimestamp, appearance });
// }
// console.log(mintedCharacters);

contract('CryptoBlades', accounts => {
  describe('stress tests', () => {
    // it('mints 1000 characters', async function () {
    //   this.timeout(15 * 60 * 1000); // 15 minute timeout

    //   // const characters = await Characters.new(accounts[0], { from: accounts[0] });
    //   const cryptoBlades = await CryptoBlades.deployed();
    //   // const characters = await Characters.at(await cryptoBlades.characters());

    //   await cryptoBlades.giveMeSkill('100000000');

    //   const preSkillAmountAccount = await cryptoBlades.getMySkill();
    //   const preSkillAmountContract = await cryptoBlades.getContractSkillBalance();

    //   for (let i = 0; i < 1000; i++) {
    //     if (i % 20 === 0) {
    //       console.log(`Minted ${i} characters...`);
    //     }
    //     await cryptoBlades.mintCharacter({ from: accounts[0] });
    //   }

    //   const postSkillAmountAccount = await cryptoBlades.getMySkill();
    //   const postSkillAmountContract = await cryptoBlades.getContractSkillBalance();
    //   console.log(`Account: ${preSkillAmountAccount} -> ${postSkillAmountAccount} (diff: ${preSkillAmountAccount - postSkillAmountAccount})`);
    //   console.log(`Contract: ${preSkillAmountContract} -> ${postSkillAmountContract} (diff: ${preSkillAmountContract - postSkillAmountContract})`);
    // });

    it('mints 1000 characters and fights with them', async function () {
      this.timeout(30 * 60 * 1000); // 30 minute timeout

      // const characters = await Characters.new(accounts[0], { from: accounts[0] });
      const cryptoBlades = await CryptoBlades.deployed();
      const characters = await Characters.at(await cryptoBlades.characters());
      const weapons = await Weapons.at(await cryptoBlades.weapons());

      await cryptoBlades.giveMeSkill('100000000');

      const preSkillAmountAccount = await cryptoBlades.getMySkill();
      const preSkillAmountContract = await cryptoBlades.getContractSkillBalance();

      const initialBlockNumber = await web3.eth.getBlockNumber();

      for (let i = 0; i < 1000; i++) {
        if (i % 20 === 0) {
          console.log(`Minted ${i} characters...`);
        }
        await cryptoBlades.mintCharacter({ from: accounts[0] });
      }

      const mintedCharacterIds = [];
      for (const event of await characters.getPastEvents('NewCharacter', { fromBlock: initialBlockNumber })) {
        mintedCharacterIds.push(event.args.character);
      }

      for (let i = 0; i < 10; i++) {
        if (i % 20 === 0) {
          console.log(`Minted ${i} weapons...`);
        }
        await cryptoBlades.mintWeapon({ from: accounts[0] });
      }

      const mintedWeaponIds = [];
      for (const event of await weapons.getPastEvents('NewWeapon', { fromBlock: initialBlockNumber })) {
        mintedWeaponIds.push(event.args.weapon);
      }

      console.log('Characters:', mintedCharacterIds);
      console.log('Weapons:', mintedWeaponIds);

      assert.lengthOf(mintedCharacterIds, 10);
      assert.lengthOf(mintedWeaponIds, 10);

      for (let i = 0; i < 10 * 10; i++) {
        if (i % 20 === 0) {
          console.log(`Done ${i} fights...`);
        }

        const randomCharacterId = sample(mintedCharacterIds);
        const randomWeaponId = sample(mintedWeaponIds);

        const targetIdsBn = await cryptoBlades.getTargets(randomCharacterId, randomWeaponId, { from: accounts[0] });
        const targetIds = targetIdsBn.map(n => '' + n);

        const targetId = sample(targetIds);

        await cryptoBlades.fight(randomCharacterId, randomWeaponId, targetId, { from: accounts[0] });
      }

      const fightResults = [];
      for (const event of await cryptoBlades.getPastEvents('FightOutcome', { fromBlock: initialBlockNumber })) {
        const { character, weapon, target, playerRoll, enemyRoll } = mapValues(event.args, n => '' + n);

        fightResults.push({ character, weapon, target, playerRoll, enemyRoll });
      }

      const fs = require('fs');
      fs.writeFileSync('fight-results.json', JSON.stringify(fightResults));

      const postSkillAmountAccount = await cryptoBlades.getMySkill();
      const postSkillAmountContract = await cryptoBlades.getContractSkillBalance();
      console.log(`Account: ${preSkillAmountAccount} -> ${postSkillAmountAccount} (diff: ${preSkillAmountAccount - postSkillAmountAccount})`);
      console.log(`Contract: ${preSkillAmountContract} -> ${postSkillAmountContract} (diff: ${preSkillAmountContract - postSkillAmountContract})`);
    });
  });
});
