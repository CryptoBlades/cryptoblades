import _ from 'lodash';
import {gasUsedToBnb} from '@/utils/common';
import {IState, ITarget} from '@/interfaces';
import {isUndefined} from 'lodash';
import {targetFromContract} from '@/contract-models';
import {Dispatch, Commit} from 'vuex';
import { getGasPrice } from '../store';
import BigNumber from 'bignumber.js';
import Vue from 'vue';
import { getFeeInSkillFromUsd } from '@/utils/contract-call-utils';

export interface ICombatState {
  isInCombat: boolean;
  targetsByCharacterIdAndWeaponId: Record<number, Record<number, ITarget>>;
  fightBaseline: string;
  fightGasOffset: string;
}

const defaultCallOptions = (rootState:  IState) => ({ from: rootState.defaultAccount });

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
    async fetchIgoRewardsPerFight({ rootState }: {rootState: IState}) {
      const { CryptoBlades } = rootState.contracts();
      if(!CryptoBlades || !rootState.defaultAccount) return;
      const IGO = 28;
      return await CryptoBlades.methods
        .vars(IGO)
        .call(defaultCallOptions(rootState));
    },

    async fetchGasOffsetPerFight({ rootState }: {rootState: IState}) {
      const { CryptoBlades } = rootState.contracts();
      if(!CryptoBlades || !rootState.defaultAccount) return;

      return await CryptoBlades.methods
        .vars(27)
        .call(defaultCallOptions(rootState));
    },

    async fetchHourlyPowerAverage({ rootState }: {rootState: IState}) {
      const { CryptoBlades } = rootState.contracts();
      if(!CryptoBlades) return;
      return await CryptoBlades.methods.vars(4).call(defaultCallOptions(rootState));
    },

    async fetchHourlyPayPerFight({ rootState }: {rootState: IState}) {
      const { CryptoBlades } = rootState.contracts();
      if(!CryptoBlades) return;
      return await CryptoBlades.methods.vars(5).call(defaultCallOptions(rootState));
    },

    async fetchHourlyAllowance({ rootState }: {rootState: IState}) {
      const { CryptoBlades } = rootState.contracts();
      if(!CryptoBlades) return;
      return await CryptoBlades.methods.vars(18).call(defaultCallOptions(rootState));
    },

    async fetchTargets({rootState, commit}: {rootState: IState, commit: Commit}, { characterId, weaponId }: {characterId: number, weaponId: number}) {
      if(isUndefined(characterId) || isUndefined(weaponId)) {
        commit('updateTargets', { characterId, weaponId, targets: [] });
        return;
      }

      const targets = await rootState.contracts().CryptoBlades!.methods
        .getTargets(characterId, weaponId)
        .call(defaultCallOptions(rootState));

      commit('updateTargets', { characterId, weaponId, targets: targets.map(targetFromContract) });
    },

    async getCharacterPower({rootState}: {rootState: IState}, characterId: number) {
      const { Characters } = rootState.contracts();
      if (!Characters || !rootState.defaultAccount) return;

      return await Characters.methods.getPower(characterId).call({from: rootState.defaultAccount, gasPrice: getGasPrice()});
    },

    async fetchExpectedPayoutForMonsterPower(
      { rootState }: {rootState: IState}, { power }: {power: string | number}) {
      const { CryptoBlades } = rootState.contracts();
      if(!CryptoBlades) return;
      return await CryptoBlades.methods.getTokenGainForFight(power).call(defaultCallOptions(rootState));
    },

    async getNativeTokenPriceInUsd({ rootState }: {rootState: IState}) {
      const { TokensManager } = rootState.contracts();
      if (!TokensManager || !rootState.defaultAccount) return;

      return await TokensManager.methods.tokenPrice().call(defaultCallOptions(rootState));
    },

    async getCurrentSkillPrice({ rootState }: {rootState: IState}) {
      const { TokensManager } = rootState.contracts();
      if (!TokensManager || !rootState.defaultAccount) return;

      return await TokensManager.methods.skillTokenPrice().call(defaultCallOptions(rootState));
    },

    async doEncounterPayNative(
      { rootState, dispatch }: {rootState: IState, dispatch: Dispatch},
      { characterId, weaponId, targetString, fightMultiplier, offsetCost }:
      { characterId: number, weaponId: number, targetString: number, fightMultiplier: number, offsetCost: BigNumber }) {
      const { TokensManager, CryptoBlades } = rootState.contracts();
      if (!TokensManager || !CryptoBlades || !rootState.defaultAccount) return;

      const res = await TokensManager.methods
        .fight(
          characterId,
          weaponId,
          targetString,
          fightMultiplier
        )
        .send({ from: rootState.defaultAccount, gasPrice: getGasPrice(), gas: '300000', value: +offsetCost * fightMultiplier });

      let playerRoll = '';
      let enemyRoll = '';
      let xpGain;
      let skillGain;

      const fightOutcomeEvents = await CryptoBlades.getPastEvents('FightOutcome', {
        filter: { owner: rootState.defaultAccount!, character: characterId },
        toBlock: res.blockNumber,
        fromBlock: res.blockNumber
      });

      if (fightOutcomeEvents.length) {
        playerRoll = fightOutcomeEvents[fightOutcomeEvents.length - 1].returnValues.playerRoll;
        enemyRoll = fightOutcomeEvents[fightOutcomeEvents.length - 1].returnValues.enemyRoll;
        xpGain = fightOutcomeEvents[fightOutcomeEvents.length - 1].returnValues.xpGain;
        skillGain = fightOutcomeEvents[fightOutcomeEvents.length - 1].returnValues.skillGain;
      }

      const {gasPrice} = await rootState.web3.eth.getTransaction(res.transactionHash);

      const bnbGasUsed = gasUsedToBnb(res.gasUsed, gasPrice);
      await Promise.all([
        dispatch('combat/fetchTargets', {characterId, weaponId}),
        dispatch('fetchWeaponDurability', weaponId),
      ]);

      return {
        isVictory: parseInt(playerRoll, 10) >= parseInt(enemyRoll, 10),
        playerRoll,
        enemyRoll,
        xpGain,
        skillGain,
        bnbGasUsed
      };
    },

    async getCombatTokenChargePercent({ rootState }: {rootState: IState}) {
      const { TokensManager } = rootState.contracts();
      if(!TokensManager || !rootState.defaultAccount) return;

      return await TokensManager.methods
        .combatTokenChargePercent()
        .call(defaultCallOptions(rootState));
    },

    async fetchFightRewardSkill({ rootState, commit }: {rootState: IState, commit: Commit}) {
      const { CryptoBlades } = rootState.contracts();
      if(!CryptoBlades) return;

      const [skillRewards] = await Promise.all([
        (async () => {
          const skillRewards = await CryptoBlades.methods
            .getTokenRewards()
            .call(defaultCallOptions(rootState));

          commit('updateSkillRewards', { skillRewards }, { root: true });

          return skillRewards;
        })()
      ]);

      return skillRewards;
    },

    async fetchFightRewardValor({ rootState, commit }: {rootState: IState, commit: Commit}) {
      const { CryptoBlades } = rootState.contracts();
      const defaultAccount = rootState.defaultAccount;
      if(!CryptoBlades || !defaultAccount) return;

      const [valorRewards] = await Promise.all([
        (async () => {
          const valorRewards = await CryptoBlades.methods
            .userVars(defaultAccount, 10011)
            .call(defaultCallOptions(rootState));

          commit('updateValorRewards', { valorRewards }, { root: true });

          return valorRewards;
        })()
      ]);

      return valorRewards;
    },

    async fetchFightRewardXp({ rootState, commit }: {rootState: IState, commit: Commit}) {
      const { CryptoBlades } = rootState.contracts();
      if(!CryptoBlades) return;

      const xps = await CryptoBlades.methods.getXpRewards(rootState.ownedCharacterIds.map(x => x.toString())).call(defaultCallOptions(rootState));

      const xpCharaIdPairs = rootState.ownedCharacterIds.map((charaId, i) => {
        return [charaId, xps[i]];
      });

      commit('updateXpRewards', { xpRewards: _.fromPairs(xpCharaIdPairs) }, { root: true });
      return xpCharaIdPairs;
    },

    async fetchCharacterStamina({ rootState, commit }: {rootState: IState, commit: Commit}, characterId: number) {
      const staminaString = await rootState.contracts().Characters!.methods
        .getStaminaPoints('' + characterId)
        .call(defaultCallOptions(rootState));

      const stamina = parseInt(staminaString, 10);
      if (rootState.characterStaminas[characterId] !== stamina) {
        commit('updateCharacterStamina', { characterId, stamina }, { root: true });
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
