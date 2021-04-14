import Vue from 'vue';
import Vuex from 'vuex';
import _ from 'lodash';
import BN from "bignumber.js";
BN.config({ ROUNDING_MODE: BN.ROUND_DOWN });
BN.config({ EXPONENTIAL_AT: 100 });

import { setUpContracts } from "./contracts";
import {
  characterFromContract, targetFromContract, weaponFromContract
} from "./contract-models.js";

const defaultCallOptions = state => ({ from: state.defaultAccount });

export function createStore(web3, featureFlagStakeOnly) {
  return new Vuex.Store({
    state: {
      contracts: {},

      accounts: [],
      defaultAccount: null,

      skillBalance: '0',
      ownedCharacterIds: [],
      ownedWeaponIds: [],
      maxStamina: 0,
      currentCharacterId: null,

      characters: {},
      characterStaminas: {},
      weapons: {},

      targetsByCharacterIdAndWeaponId: {},

      stakedSkillBalance: '0',
      stakeRemainingCapacityForDeposit: '0',
      stakeRemainingCapacityForWithdraw: '0',
      stakeContractBalance: '0',

      stakeCurrentRewardEarned: '0',
      stakeRewardPeriodEndUnix: 0,
      stakeRewardPeriodDurationSeconds: 7 * 24 * 60 * 60,
      stakeLatestBlockTimestampUnix: 0
    },

    getters: {
      contractProvider(state) {
        return state.contracts;
      },

      getTargetsByCharacterIdAndWeaponId(state) {
        return (characterId, weaponId) => {
          const targetsByWeaponId = state.targetsByCharacterIdAndWeaponId[characterId];
          if (targetsByWeaponId == null) return [];
          return targetsByWeaponId[weaponId] || [];
        };
      },

      getCharacterName(state) {
        const names = [
          'Gaa Chestbrew',
          'Globrin Stun',
          'Grar Nelag',
          'Trudvurth Duskspirit',
          'Lur Farglade',
          'Lira-Zen Nizruzrik',
          'Thek-Duf Huenkruld'
        ];

        return (characterId) => {
          void (state);
          return names[characterId];
        };
      },

      ownCharacters(state) {
        const characters = state.ownedCharacterIds.map((id) => state.characters[id]);
        if (characters.some((w) => w == null)) return [];
        return characters;
      },

      ownWeapons(state) {
        const weapons = state.ownedWeaponIds.map((id) => state.weapons[id]);
        if (weapons.some((w) => w == null)) return [];
        return weapons;
      },

      currentCharacter(state) {
        if (state.currentCharacterId == null) return null;

        return state.characters[state.currentCharacterId];
      },

      currentCharacterStamina(state) {
        return state.currentCharacterId == null ? 0 : state.characterStaminas[state.currentCharacterId];
      },

      stakeRewardPeriodStartUnix(state) {
        return state.stakeRewardPeriodEndUnix - state.stakeRewardPeriodDurationSeconds;
      },
    },

    mutations: {
      setAccounts(state, payload) {
        state.accounts = payload.accounts;

        if (payload.accounts.length > 0) {
          state.defaultAccount = payload.accounts[0];
        }
        else {
          state.defaultAccount = null;
        }
      },

      setContracts(state, payload) {
        state.contracts = payload;
      },

      updateSkillBalance(state, { skillBalance }) {
        state.skillBalance = skillBalance;
      },

      updateUserDetails(state, payload) {
        const keysToAllow = ['ownedCharacterIds', 'ownedWeaponIds', 'maxStamina'];
        for (const key of keysToAllow) {
          if (Object.hasOwnProperty.call(payload, key)) {
            Vue.set(state, key, payload[key]);
          }
        }

        if (state.ownedCharacterIds.length > 0 &&
          (
            state.currentCharacterId == null ||
            !state.ownedCharacterIds.includes(state.currentCharacterId)
          )
        ) {
          state.currentCharacterId = state.ownedCharacterIds[0];
        }
        else if (state.ownedCharacterIds.length === 0) {
          state.currentCharacterId = null;
        }
      },

      setCurrentCharacter(state, characterId) {
        state.currentCharacterId = characterId;
      },

      addNewOwnedCharacterId(state, characterId) {
        if (!state.ownedCharacterIds.includes(characterId)) {
          state.ownedCharacterIds.push(characterId);
        }
      },

      addNewOwnedWeaponId(state, weaponId) {
        if (!state.ownedWeaponIds.includes(weaponId)) {
          state.ownedWeaponIds.push(weaponId);
        }
      },

      updateCharacter(state, { characterId, character }) {
        Vue.set(state.characters, characterId, character);
      },

      updateWeapon(state, { weaponId, weapon }) {
        Vue.set(state.weapons, weaponId, weapon);
      },

      updateCharacterStamina(state, { characterId, stamina }) {
        Vue.set(state.characterStaminas, characterId, stamina);
      },

      updateTargets(state, { characterId, weaponId, targets }) {
        if (state.targetsByCharacterIdAndWeaponId[characterId] == null) {
          Vue.set(state.targetsByCharacterIdAndWeaponId, characterId, {});
        }

        Vue.set(state.targetsByCharacterIdAndWeaponId[characterId], weaponId, targets);
      },

      updateStakeData(state, {
        stakedSkillBalance, stakeRemainingCapacityForDeposit,
        stakeRemainingCapacityForWithdraw, stakeContractBalance
      }) {
        state.stakedSkillBalance = stakedSkillBalance;
        state.stakeRemainingCapacityForDeposit = stakeRemainingCapacityForDeposit;
        state.stakeRemainingCapacityForWithdraw = stakeRemainingCapacityForWithdraw;
        state.stakeContractBalance = stakeContractBalance;
      },

      updateStakeRewardData(state, {
        stakeCurrentRewardEarned,
        stakeRewardPeriodEndUnix,
        stakeRewardPeriodDurationSeconds,
        stakeLatestBlockTimestampUnix
      }) {
        state.stakeCurrentRewardEarned = stakeCurrentRewardEarned;
        state.stakeRewardPeriodEndUnix = stakeRewardPeriodEndUnix;
        state.stakeRewardPeriodDurationSeconds = stakeRewardPeriodDurationSeconds;
        state.stakeLatestBlockTimestampUnix = stakeLatestBlockTimestampUnix;
      }
    },

    actions: {
      async initialize({ dispatch }) {
        await dispatch('setUpContracts');
        await dispatch('setUpContractEvents');

        await dispatch('fetchAccounts');
      },

      async fetchAccounts({ state, dispatch, commit }) {
        const accounts = await web3.eth.requestAccounts();

        if (!_.isEqual(state.accounts, accounts)) {
          commit('setAccounts', { accounts });
          await dispatch('fetchUserDetails');
        }
      },

      setUpContractEvents({ state, dispatch, commit }) {
        // TODO filter to only get own
        state.contracts.Characters.events.NewCharacter(async (err, data) => {
          if (err != null) {
            console.error(err);
            return;
          }

          console.log('NewCharacter', data);

          const characterId = data.returnValues.character;

          commit('addNewOwnedCharacterId', characterId);

          await Promise.all([
            dispatch('fetchCharacter', characterId),
            dispatch('fetchSkillBalance')
          ]);
        });

        // TODO filter to only get own
        state.contracts.Weapons.events.NewWeapon(async (err, data) => {
          if (err != null) {
            console.error(err);
            return;
          }

          console.log('NewWeapon', data);

          const weaponId = data.returnValues.weapon;

          commit('addNewOwnedWeaponId', weaponId);

          await Promise.all([
            dispatch('fetchWeapon', weaponId),
            dispatch('fetchSkillBalance')
          ]);
        });

        // TODO filter to only get own
        state.contracts.CryptoBlades.events.FightOutcome(async (err, data) => {
          if (err != null) {
            console.error(err);
            return;
          }

          console.log('FightOutcome', data);

          await Promise.all([
            dispatch('fetchCharacter', data.returnValues.character),
            dispatch('fetchSkillBalance')
          ]);
        });

        state.contracts.StakingRewards.events.RewardPaid({ filter: { user: state.defaultAccount } }, async (err, data) => {
          if (err != null) {
            console.error(err);
            return;
          }

          console.log('RewardPaid', data);

          await Promise.all([
            dispatch('fetchSkillBalance'),
            dispatch('fetchStakeRewardDetails'),
          ]);
        });

        state.contracts.StakingRewards.events.RewardAdded(async (err, data) => {
          if (err != null) {
            console.error(err);
            return;
          }

          console.log('RewardAdded', data);

          await dispatch('fetchStakeRewardDetails');
        });

        state.contracts.StakingRewards.events.RewardsDurationUpdated(async (err, data) => {
          if (err != null) {
            console.error(err);
            return;
          }

          console.log('RewardsDurationUpdated', data);

          await dispatch('fetchStakeRewardDetails');
        });
      },

      async setUpContracts({ commit }) {
        const contracts = await setUpContracts(web3);
        commit('setContracts', contracts);
      },

      async fetchUserDetails({ dispatch }) {
        const promises = [dispatch('fetchSkillBalance')];

        if (!featureFlagStakeOnly) {
          promises.push(dispatch('fetchUserGameDetails'));
        }

        await Promise.all([promises]);
      },

      async fetchUserGameDetails({ state, dispatch, commit }) {
        const [
          ownedCharacterIds,
          ownedWeaponIds,
          maxStamina,
        ] = await Promise.all([
          state.contracts.CryptoBlades.methods.getMyCharacters().call(defaultCallOptions(state)),
          state.contracts.CryptoBlades.methods.getMyWeapons().call(defaultCallOptions(state)),
          state.contracts.Characters.methods.maxStamina().call(defaultCallOptions(state)),
        ]);

        commit('updateUserDetails', {
          ownedCharacterIds: Array.from(ownedCharacterIds),
          ownedWeaponIds: Array.from(ownedWeaponIds),
          maxStamina: parseInt(maxStamina, 10)
        });

        await Promise.all([
          dispatch('fetchCharacters', ownedCharacterIds),
          dispatch('fetchWeapons', ownedWeaponIds),
        ]);
      },

      async updateWeaponIds({ state, dispatch, commit }) {
        const ownedWeaponIds = await state.contracts.CryptoBlades.methods.getMyWeapons().call(defaultCallOptions(state));
        commit('updateUserDetails', {
          ownedWeaponIds: Array.from(ownedWeaponIds)
        });
        await dispatch('fetchWeapons', ownedWeaponIds);
      },

      async fetchSkillBalance({ state, commit }) {
        const skillBalance = await state.contracts.CryptoBlades.methods.getMySkill().call(defaultCallOptions(state));
        commit('updateSkillBalance', { skillBalance });
      },

      async addMoreSkill({ state, dispatch }, skillToAdd) {
        await state.contracts.CryptoBlades.methods.giveMeSkill(skillToAdd).send({
          from: state.defaultAccount,
        });

        await dispatch('fetchSkillBalance');
      },

      async fetchCharacters({ dispatch }, characterIds) {
        await Promise.all(characterIds.map(id => dispatch('fetchCharacter', id)));
      },

      async fetchCharacter({ state, commit }, characterId) {
        const character = characterFromContract(
          characterId,
          await state.contracts.Characters.methods.get(characterId).call(defaultCallOptions(state))
        );

        commit('updateCharacter', { characterId, character });
      },

      async fetchWeapons({ dispatch }, weaponIds) {
        await Promise.all(weaponIds.map(id => dispatch('fetchWeapon', id)));
      },

      async fetchWeapon({ state, commit }, weaponId) {
        const weapon = weaponFromContract(
          weaponId,
          await state.contracts.Weapons.methods.get(weaponId).call(defaultCallOptions(state))
        );

        commit('updateWeapon', { weaponId, weapon });
      },

      async fetchCharacterStamina({ state, commit }, characterId) {
        const stamina = await state.contracts.Characters.methods.getStaminaPoints(characterId).call(defaultCallOptions(state));
        if (state.characterStaminas[characterId] !== stamina) {
          commit('updateCharacterStamina', { characterId, stamina });
        }
      },

      async mintCharacter({ state }) {
        await state.contracts.CryptoBlades.methods.mintCharacter().send({
          from: state.defaultAccount,
        });
      },

      async mintWeapon({ state }) {
        await state.contracts.CryptoBlades.methods.mintWeapon().send({
          from: state.defaultAccount,
        });
      },

      async reforgeWeapon({ state, dispatch }, { burnWeaponId, reforgeWeaponId }) {
        await state.contracts.Weapons.methods
          .approve(
            state.contracts.CryptoBlades.options.address,
            burnWeaponId
          )
          .send({
            from: state.defaultAccount,
          });

        await state.contracts.CryptoBlades.methods
          .reforgeWeapon(
            reforgeWeaponId,
            burnWeaponId
          )
          .send({
            from: state.defaultAccount,
          });

        await dispatch('updateWeaponIds');
      },

      async fetchTargets({ state, commit }, { characterId, weaponId }) {
        if (characterId == null || weaponId == null) {
          commit('updateTargets', { characterId, weaponId, targets: [] });
          return;
        }

        const targets = await state.contracts.CryptoBlades.methods
          .getTargets(characterId, weaponId)
          .call(defaultCallOptions(state));

        commit('updateTargets', { characterId, weaponId, targets: targets.map(targetFromContract) });
      },

      async doEncounter({ state, dispatch }, { characterId, weaponId, targetString }) {
        const res = await state.contracts.CryptoBlades.methods
          .fight(
            characterId,
            weaponId,
            targetString
          )
          .send({ from: state.defaultAccount });

        await dispatch('fetchTargets', { characterId, weaponId });

        const {
          playerRoll,
          enemyRoll,
        } = res.events.FightOutcome.returnValues;

        if (parseInt(playerRoll, 10) >= parseInt(enemyRoll, 10)) {
          return true;
        } else {
          return false;
        }
      },

      async fetchStakeDetails({ state, commit }) {
        const { StakingRewards, SkillToken } = state.contracts;

        const [
          stakedSkillBalance, stakeRemainingCapacityForDeposit,
          stakeRemainingCapacityForWithdraw, stakeContractBalance
        ] = await Promise.all([
          StakingRewards.methods.balanceOf(state.defaultAccount).call(defaultCallOptions(state)),
          Promise.resolve(null),
          StakingRewards.methods.totalSupply().call(defaultCallOptions(state)),
          SkillToken.methods.balanceOf(StakingRewards.options.address).call(defaultCallOptions(state)),
        ]);

        const stakeData = {
          stakedSkillBalance, stakeRemainingCapacityForDeposit,
          stakeRemainingCapacityForWithdraw, stakeContractBalance
        };
        // console.log(stakeData);
        commit('updateStakeData', stakeData);
      },

      async fetchStakeRewardDetails({ state, commit }) {
        const { StakingRewards } = state.contracts;

        const [
          stakeCurrentRewardEarned,
          stakeRewardPeriodEndUnix,
          stakeRewardPeriodDurationSeconds,
          stakeLatestBlockTimestampUnix
        ] = await Promise.all([
          StakingRewards.methods.earned(state.defaultAccount).call(defaultCallOptions(state)),
          StakingRewards.methods.periodFinish().call(defaultCallOptions(state)),
          StakingRewards.methods.rewardsDuration().call(defaultCallOptions(state)),
          web3.eth.getBlock('latest').then(b => b.timestamp),
        ]);

        const stateToChange = {
          stakeCurrentRewardEarned,
          stakeRewardPeriodEndUnix: parseInt(stakeRewardPeriodEndUnix, 10),
          stakeRewardPeriodDurationSeconds: parseInt(stakeRewardPeriodDurationSeconds, 10),
          stakeLatestBlockTimestampUnix: parseInt(stakeLatestBlockTimestampUnix, 10)
        };
        let doCommit = false;
        for (const key in stateToChange) {
          if (Object.hasOwnProperty.call(stateToChange, key) && stateToChange[key] !== state[key]) {
            doCommit = true;
            break;
          }
        }

        if (doCommit) {
          commit('updateStakeRewardData', stateToChange);
        }
      },

      async stake({ state, dispatch }, { amount, gas }) {
        const { StakingRewards, SkillToken } = state.contracts;

        await SkillToken.methods.increaseAllowance(StakingRewards.options.address, amount).send({
          from: state.defaultAccount
        });

        await StakingRewards.methods.stake(amount).send({
          from: state.defaultAccount,
          gas: 200_000,
          gasPrice: BN(gas).multipliedBy(1e9).toString(),
        });

        await Promise.all([
          dispatch('fetchSkillBalance'),
          dispatch('fetchStakeDetails'),
        ]);
      },

      async unstake({ state, dispatch }, { amount, gas }) {
        const { StakingRewards } = state.contracts;

        await StakingRewards.methods.withdraw(amount).send({
          from: state.defaultAccount,
          gas: 200_000,
          gasPrice: BN(gas).multipliedBy(1e9).toString(),
        });

        await Promise.all([
          dispatch('fetchSkillBalance'),
          dispatch('fetchStakeDetails'),
        ]);
      },

      async claimReward({ state, dispatch }) {
        const { StakingRewards } = state.contracts;

        await StakingRewards.methods.getReward().send({
          from: state.defaultAccount,
        });

        await Promise.all([
          dispatch('fetchSkillBalance'),
          dispatch('fetchStakeRewardDetails'),
        ]);
      }
    }
  });
}
