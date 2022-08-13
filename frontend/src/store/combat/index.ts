import _ from 'lodash';
import {gasUsedToBnb} from '@/utils/common';
import {IState, ITarget} from '@/interfaces';
import {isUndefined} from 'lodash';
import {targetFromContract} from '@/contract-models';
import {Dispatch, Commit} from 'vuex';
import { getGasPrice } from '../store';
import BigNumber from 'bignumber.js';
import Vue from 'vue';
import { getFeeInSkillFromUsd } from '@/contract-call-utils';

export interface ICombatState {
  isInCombat: boolean;
  targetsByCharacterIdAndWeaponId: Record<number, Record<number, ITarget>>;
  fightBaseline: string;
  fightGasOffset: string;
}

const defaultCallOptions = (state:  IState) => ({ from: state.defaultAccount });

const combat = {
  namespaced: true,
  state: {
    isInCombat: false,
    targetsByCharacterIdAndWeaponId: {},
    fightBaseline: '0',
    fightGasOffset: '0',
  } as ICombatState,
  getters: {
    getTargetsByCharacterIdAndWeaponId(state: ICombatState) {
      return (characterId: number, weaponId: number) => {
        const targetsByWeaponId = state.targetsByCharacterIdAndWeaponId[characterId];
        if (!targetsByWeaponId) return [];

        return targetsByWeaponId[weaponId] ?? [];
      };
    },
    getIsInCombat(state: ICombatState) {
      return state.isInCombat;
    },
    fightGasOffset(state: ICombatState) {
      return state.fightGasOffset;
    },

    fightBaseline(state: ICombatState) {
      return state.fightBaseline;
    },
  },
  mutations: {
    setIsInCombat(state: ICombatState, isInCombat: boolean) {
      state.isInCombat = isInCombat;
    },
    updateTargets(state: ICombatState, { characterId, weaponId, targets }: {characterId: number, weaponId: number, targets: ITarget[]}) {
      if (!state.targetsByCharacterIdAndWeaponId[characterId]) {
        Vue.set(state.targetsByCharacterIdAndWeaponId, characterId, {});
      }

      Vue.set(state.targetsByCharacterIdAndWeaponId[characterId], weaponId, targets);
    },
    updateFightBaseline(state: ICombatState, { fightBaseline }: { fightBaseline: string }) {
      state.fightBaseline = fightBaseline;
    },
    updateFightGasOffset(state: ICombatState, { fightGasOffset }: { fightGasOffset: string }) {
      state.fightGasOffset = fightGasOffset;
    },
  },
  actions: {
    async fetchIgoRewardsPerFight({state}: {state: IState}) {
      const { CryptoBlades } = state.contracts();
      if(!CryptoBlades || !state.defaultAccount) return;

      return await CryptoBlades.methods
        .vars(27)
        .call(defaultCallOptions(state));
    },

    async fetchHourlyPowerAverage({state}: {state: IState}) {
      const { CryptoBlades } = state.contracts();
      if(!CryptoBlades) return;
      return await CryptoBlades.methods.vars(4).call(defaultCallOptions(state));
    },

    async fetchHourlyPayPerFight({state}: {state: IState}) {
      const { CryptoBlades } = state.contracts();
      if(!CryptoBlades) return;
      return await CryptoBlades.methods.vars(5).call(defaultCallOptions(state));
    },

    async fetchHourlyAllowance({state}: {state: IState}) {
      const { CryptoBlades } = state.contracts();
      if(!CryptoBlades) return;
      return await CryptoBlades.methods.vars(18).call(defaultCallOptions(state));
    },

    async fetchTargets(
      {state, commit}: {state: IState, commit: Commit},
      { characterId, weaponId }: {characterId: number, weaponId: number}) {
      if(isUndefined(characterId) || isUndefined(weaponId)) {
        commit('updateTargets', { characterId, weaponId, targets: [] });
        return;
      }

      const targets = await state.contracts().CryptoBlades!.methods
        .getTargets(characterId, weaponId)
        .call(defaultCallOptions(state));

      commit('updateTargets', { characterId, weaponId, targets: targets.map(targetFromContract) });
    },

    async getCharacterPower({ state }: {state: IState}, characterId: number) {
      const { Characters } = state.contracts();
      if (!Characters || !state.defaultAccount) return;

      return await Characters.methods.getPower(characterId).call({from: state.defaultAccount, gasPrice: getGasPrice()});
    },

    async fetchExpectedPayoutForMonsterPower({ state }: {state: IState}, { power, isCalculator = false }: {power: string | number, isCalculator: boolean}) {
      const { CryptoBlades } = state.contracts();
      if(!CryptoBlades) return;
      if(isCalculator) {
        return await CryptoBlades.methods.getTokenGainForFight(power, false).call(defaultCallOptions(state));
      }
      return await CryptoBlades.methods.getTokenGainForFight(power, true).call(defaultCallOptions(state));
    },

    async getNativeTokenPriceInUsd({ state }: {state: IState}) {
      const { TokensManager } = state.contracts();
      if (!TokensManager || !state.defaultAccount) return;

      return await TokensManager.methods.tokenPrice().call(defaultCallOptions(state));
    },

    async getCurrentSkillPrice({ state }: {state: IState}) {
      const { TokensManager } = state.contracts();
      if (!TokensManager || !state.defaultAccount) return;

      return await TokensManager.methods.skillTokenPrice().call(defaultCallOptions(state));
    },

    async doEncounter(
      { state, dispatch }: {state: IState, dispatch: Dispatch},
      { characterId, weaponId, targetString, fightMultiplier }:
      { characterId: number, weaponId: number, targetString: number, fightMultiplier: number }) {
      const res = await state.contracts().CryptoBlades!.methods
        .fight(
          characterId,
          weaponId,
          targetString,
          fightMultiplier
        )
        .send({ from: state.defaultAccount, gas: '300000', gasPrice: getGasPrice() });

      await dispatch('fetchTargets', { characterId, weaponId });

      const {
        /*owner,
        character,
        weapon,
        target,*/
        playerRoll,
        enemyRoll,
        xpGain,
        skillGain
      } = res.events.FightOutcome.returnValues;

      const {gasPrice} = await state.web3.eth.getTransaction(res.transactionHash);

      const bnbGasUsed = gasUsedToBnb(res.gasUsed, gasPrice);

      await dispatch('fetchWeaponDurability', weaponId);

      return {
        isVictory: parseInt(playerRoll, 10) >= parseInt(enemyRoll, 10),
        playerRoll,
        enemyRoll,
        xpGain,
        skillGain,
        bnbGasUsed
      };
    },

    async doEncounterPayNative(
      { state, dispatch }: {state: IState, dispatch: Dispatch},
      { characterId, weaponId, targetString, fightMultiplier, offsetCost }:
      { characterId: number, weaponId: number, targetString: number, fightMultiplier: number, offsetCost: BigNumber }) {
      const { TokensManager, CryptoBlades } = state.contracts();
      if (!TokensManager || !CryptoBlades || !state.defaultAccount) return;

      const res = await TokensManager.methods
        .fight(
          characterId,
          weaponId,
          targetString,
          fightMultiplier
        )
        .send({ from: state.defaultAccount, gasPrice: getGasPrice(), gas: '300000', value: (+offsetCost ? +offsetCost : 1)*fightMultiplier });

      let playerRoll = '';
      let enemyRoll = '';
      let xpGain;
      let skillGain;

      const fightOutcomeEvents = await CryptoBlades.getPastEvents('FightOutcome', {
        filter: { owner: state.defaultAccount!, character: characterId },
        toBlock: res.blockNumber,
        fromBlock: res.blockNumber
      });

      if (fightOutcomeEvents.length) {
        playerRoll = fightOutcomeEvents[fightOutcomeEvents.length - 1].returnValues.playerRoll;
        enemyRoll = fightOutcomeEvents[fightOutcomeEvents.length - 1].returnValues.enemyRoll;
        xpGain = fightOutcomeEvents[fightOutcomeEvents.length - 1].returnValues.xpGain;
        skillGain = fightOutcomeEvents[fightOutcomeEvents.length - 1].returnValues.skillGain;
      }

      const {gasPrice} = await state.web3.eth.getTransaction(res.transactionHash);

      const bnbGasUsed = gasUsedToBnb(res.gasUsed, gasPrice);
      await dispatch('fetchTargets', { characterId, weaponId });
      await dispatch('fetchWeaponDurability', weaponId);

      return {
        isVictory: parseInt(playerRoll, 10) >= parseInt(enemyRoll, 10),
        playerRoll,
        enemyRoll,
        xpGain,
        skillGain,
        bnbGasUsed
      };
    },

    async getCombatTokenChargePercent({ state }: {state: IState}) {
      const { TokensManager } = state.contracts();
      if(!TokensManager || !state.defaultAccount) return;

      return await TokensManager.methods
        .combatTokenChargePercent()
        .call(defaultCallOptions(state));
    },

    async fetchFightRewardSkill({ state, commit }: {state: IState, commit: Commit}) {
      const { CryptoBlades } = state.contracts();
      if(!CryptoBlades) return;

      const [skillRewards] = await Promise.all([
        (async () => {
          const skillRewards = await CryptoBlades.methods
            .getTokenRewards()
            .call(defaultCallOptions(state));

          commit('updateSkillRewards', { skillRewards });

          return skillRewards;
        })()
      ]);

      return skillRewards;
    },

    async fetchFightRewardXp({ rootState, commit }: {rootState: IState, commit: Commit}) {
      const { CryptoBlades } = rootState.contracts();
      if(!CryptoBlades) return;

      const xps = await CryptoBlades.methods.getXpRewards(rootState.ownedCharacterIds.map(x => x.toString())).call(defaultCallOptions(rootState));

      const xpCharaIdPairs = rootState.ownedCharacterIds.map((charaId, i) => {
        return [charaId, xps[i]];
      });

      commit('updateXpRewards', { xpRewards: _.fromPairs(xpCharaIdPairs) });
      return xpCharaIdPairs;
    },

    async fetchCharacterStamina({ rootState, commit }: {rootState: IState, commit: Commit}, characterId: number) {
      const staminaString = await rootState.contracts().Characters!.methods
        .getStaminaPoints('' + characterId)
        .call(defaultCallOptions(rootState));

      const stamina = parseInt(staminaString, 10);
      if (rootState.characterStaminas[characterId] !== stamina) {
        commit('updateCharacterStamina', { characterId, stamina });
      }
    },

    async fetchFightGasOffset({ rootState, commit }: {rootState: IState, commit: Commit}) {
      const { CryptoBlades } = rootState.contracts();
      if(!CryptoBlades) return;
      const fightGasOffset = await getFeeInSkillFromUsd(
        CryptoBlades,
        defaultCallOptions(rootState),
        cryptoBladesMethods => cryptoBladesMethods.fightRewardGasOffset()
      );

      commit('updateFightGasOffset', { fightGasOffset });
      return fightGasOffset;
    },

    async fetchFightBaseline({ rootState, commit }: {rootState: IState, commit: Commit}) {
      const { CryptoBlades } = rootState.contracts();
      if(!CryptoBlades) return;

      const fightBaseline = await getFeeInSkillFromUsd(
        CryptoBlades,
        defaultCallOptions(rootState),
        cryptoBladesMethods => cryptoBladesMethods.fightRewardBaseline()
      );

      commit('updateFightBaseline', { fightBaseline });
      return fightBaseline;
    },

    async getFightXpGain({rootState}: {rootState: IState}) {
      const {CryptoBlades} = rootState.contracts();
      if (!CryptoBlades) return;

      return +await CryptoBlades.methods.fightXpGain().call(defaultCallOptions(rootState));
    },

    async setFightXpGain({rootState}: {rootState: IState}, {xpGain}: {xpGain: number}) {
      const {CryptoBlades} = rootState.contracts();
      if (!CryptoBlades) return;

      await CryptoBlades.methods.setFightXpGain(xpGain).send({
        from: rootState.defaultAccount,
        gasPrice: getGasPrice(),
      });
    },
  },
};

export default combat;
