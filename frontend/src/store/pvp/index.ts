import {IState} from '@/interfaces';
import {Dispatch, Commit} from 'vuex';
import {approveFeeFromAnyContractSimple} from '@/contract-call-utils';
import BigNumber from 'bignumber.js';

const defaultCallOptions = (rootState:  IState) => ({ from: rootState.defaultAccount });

const pvp = {
  actions: {
    async getFighterByCharacter({ rootState }: {rootState: IState}, characterId: number) {
      const { PvpCore } = rootState.contracts();
      if (!PvpCore || !rootState.defaultAccount) return;

      const fighter = await PvpCore.methods.fighterByCharacter(characterId).call({ from: rootState.defaultAccount });

      return fighter;
    },

    async getCurrentRankedSeason({ rootState }: {rootState: IState}) {
      const { PvpRankings } = rootState.contracts();
      if (!PvpRankings || !rootState.defaultAccount) return;

      const currentRankedSeason = await PvpRankings.methods.currentRankedSeason().call({ from: rootState.defaultAccount });

      return currentRankedSeason;
    },

    async getSeasonStartedAt({ rootState }: {rootState: IState}) {
      const { PvpRankings } = rootState.contracts();
      if (!PvpRankings || !rootState.defaultAccount) return;

      const seasonStartedAt = await PvpRankings.methods.seasonStartedAt().call({ from: rootState.defaultAccount });

      return seasonStartedAt;
    },

    async getSeasonDuration({ rootState }: {rootState: IState}) {
      const { PvpRankings } = rootState.contracts();
      if (!PvpRankings || !rootState.defaultAccount) return;

      const seasonDuration = await PvpRankings.methods.seasonDuration().call({ from: rootState.defaultAccount });

      return seasonDuration;
    },

    async getCharacterLevel({ rootState }: {rootState: IState}, characterId: number) {
      const { Characters } = rootState.contracts();
      if (!Characters || !rootState.defaultAccount) return;

      const characterLevel = await Characters.methods.getLevel(characterId).call({ from: rootState.defaultAccount });

      return characterLevel;
    },

    async getCharacterFullPower({ rootState }: {rootState: IState}, characterId: number) {
      const { PvpCore } = rootState.contracts();
      if (!PvpCore || !rootState.defaultAccount) return;

      const characterFullPower = await PvpCore.methods.getCharacterPower(characterId).call({ from: rootState.defaultAccount });

      return characterFullPower;
    },

    async getRankingPointsByCharacter({ rootState }: {rootState: IState}, characterId: number) {
      const { PvpRankings } = rootState.contracts();
      if (!PvpRankings || !rootState.defaultAccount) return;

      const rankingPointsByCharacter = await PvpRankings.methods.rankingPointsByCharacter(characterId).call({ from: rootState.defaultAccount });

      return rankingPointsByCharacter;
    },

    async getRankingsPoolByTier({ rootState }: {rootState: IState}, tier: number) {
      const { PvpRankings } = rootState.contracts();
      if (!PvpRankings || !rootState.defaultAccount) return;

      const rankingsPoolByTier = await PvpRankings.methods.rankingsPoolByTier(tier).call({ from: rootState.defaultAccount });

      return rankingsPoolByTier;
    },

    async getTierTopCharacters({ rootState }: {rootState: IState}, tier: number) {
      const { PvpRankings } = rootState.contracts();
      if (!PvpRankings || !rootState.defaultAccount) return;

      const tierTopCharacters = await PvpRankings.methods.getTierTopCharacters(tier).call({ from: rootState.defaultAccount });

      return tierTopCharacters;
    },

    async getArenaTier({ rootState }: {rootState: IState}, characterId: number) {
      const { PvpCore } = rootState.contracts();
      if (!PvpCore || !rootState.defaultAccount) return;

      const arenaTier = await PvpCore.methods.getArenaTier(characterId).call({ from: rootState.defaultAccount });

      return arenaTier;
    },

    async getPreviousTierByCharacter({ rootState }: {rootState: IState}, characterId: number) {
      const { PvpCore } = rootState.contracts();
      if (!PvpCore || !rootState.defaultAccount) return;

      const arenaTier = await PvpCore.methods.previousTierByCharacter(characterId).call({ from: rootState.defaultAccount });

      return arenaTier;
    },

    async getEntryWagerByTier({ rootState }: {rootState: IState}, tier: number) {
      const { PvpCore } = rootState.contracts();
      if (!PvpCore || !rootState.defaultAccount) return;

      const entryWager = await PvpCore.methods.getEntryWagerByTier(tier).call({ from: rootState.defaultAccount });

      return entryWager;
    },

    async getIsWeaponInArena({ rootState }: {rootState: IState}, weaponId: number) {
      const { PvpCore } = rootState.contracts();
      if (!PvpCore || !rootState.defaultAccount) return;

      const isWeaponInArena = await PvpCore.methods.isWeaponInArena(weaponId).call({ from: rootState.defaultAccount });

      return isWeaponInArena;
    },

    async getIsShieldInArena({ rootState }: {rootState: IState}, shieldId: number) {
      const { PvpCore } = rootState.contracts();
      if (!PvpCore || !rootState.defaultAccount) return;

      const isShieldInArena = await PvpCore.methods.isShieldInArena(shieldId).call({ from: rootState.defaultAccount });

      return isShieldInArena;
    },

    async getIsCharacterInArena({ rootState, commit }: {rootState: IState, commit: Commit}, characterId: number) {
      const { PvpCore } = rootState.contracts();
      if (!PvpCore || !rootState.defaultAccount) return;
      const isCharacterInArena = await PvpCore.methods.isCharacterInArena(characterId).call({ from: rootState.defaultAccount });
      commit('updateCharacterInArena', { characterId, isCharacterInArena });

      return isCharacterInArena;
    },

    async getIsCharacterUnderAttack({ rootState }: {rootState: IState}, characterId: number) {
      const { PvpCore } = rootState.contracts();
      if (!PvpCore || !rootState.defaultAccount) return;

      const isCharacterUnderAttack = await PvpCore.methods.isCharacterUnderAttack(characterId).call({ from: rootState.defaultAccount });

      return isCharacterUnderAttack;
    },

    async getMatchByFinder({ rootState }: {rootState: IState}, characterId: number) {
      const { PvpCore } = rootState.contracts();
      if (!PvpCore || !rootState.defaultAccount) return;

      const matchByFinder = await PvpCore.methods.matchByFinder(characterId).call({ from: rootState.defaultAccount });

      return matchByFinder;
    },

    async getDuelQueue({ rootState }: {rootState: IState}) {
      const { PvpCore } = rootState.contracts();
      if (!PvpCore || !rootState.defaultAccount) return;

      const matchByFinder = await PvpCore.methods.getDuelQueue().call({ from: rootState.defaultAccount });

      return matchByFinder;
    },

    async getDuelCost({ rootState }: {rootState: IState}, characterId: number) {
      const { PvpCore } = rootState.contracts();
      if (!PvpCore || !rootState.defaultAccount) return;

      const matchByFinder = await PvpCore.methods.getDuelCost(characterId).call({ from: rootState.defaultAccount });

      return matchByFinder;
    },

    async getMatchablePlayerCount({ rootState }: {rootState: IState}, characterId: number) {
      const { PvpCore } = rootState.contracts();
      if (!PvpCore || !rootState.defaultAccount) return;

      const matchablePlayerCount = await PvpCore.methods.getMatchablePlayerCount(characterId).call({ from: rootState.defaultAccount });

      return matchablePlayerCount;
    },

    async getDecisionSeconds({ rootState }: {rootState: IState}) {
      const { PvpCore } = rootState.contracts();
      if (!PvpCore || !rootState.defaultAccount) return;

      const decisionSeconds = await PvpCore.methods.decisionSeconds().call({ from: rootState.defaultAccount });

      return decisionSeconds;
    },

    async getReRollFeePercent({ rootState }: {rootState: IState}) {
      const { PvpCore } = rootState.contracts();
      if (!PvpCore || !rootState.defaultAccount) return;

      const reRollFeePercent = await PvpCore.methods.reRollFeePercent().call({ from: rootState.defaultAccount });

      return reRollFeePercent;
    },

    async getPlayerPrizePoolRewards({ rootState }: {rootState: IState}) {
      const { PvpRankings } = rootState.contracts();
      if (!PvpRankings || !rootState.defaultAccount) return;

      const playerPrizePoolRewards = await PvpRankings.methods.getPlayerPrizePoolRewards().call({ from: rootState.defaultAccount });

      return playerPrizePoolRewards;
    },

    async getDuelOffsetCost({ rootState }: {rootState: IState}) {
      const { PvpCore } = rootState.contracts();
      if (!PvpCore || !rootState.defaultAccount) return;

      const duelOffsetCost = await PvpCore.methods.duelOffsetCost().call({ from: rootState.defaultAccount });

      return duelOffsetCost;
    },

    async enterArena(
      { rootState, dispatch }: {rootState: IState, dispatch: Dispatch},
      {characterId, weaponId, shieldId, useShield, tierless}:
      {characterId: number, weaponId: number, shieldId: number, useShield: boolean, tierless: boolean}){
      const { PvpCore } = rootState.contracts();
      if (!PvpCore || !rootState.defaultAccount) return;

      const res = await PvpCore.methods.enterArena(characterId, weaponId, shieldId, useShield, tierless).send({ from: rootState.defaultAccount });

      await dispatch('getIsCharacterInArena', characterId);

      return res;
    },

    async withdrawFromArena({ rootState, dispatch }: {rootState: IState, dispatch: Dispatch}, characterId: number) {
      const { PvpCore } = rootState.contracts();
      if (!PvpCore || !rootState.defaultAccount) return;

      const res = await PvpCore.methods.withdrawFromArena(characterId).send({ from: rootState.defaultAccount });

      await dispatch('getIsCharacterInArena', characterId);

      return res;
    },

    async findOpponent({ rootState }: {rootState: IState}, characterId: number) {
      const { PvpCore } = rootState.contracts();
      if (!PvpCore || !rootState.defaultAccount) return;

      const res = await PvpCore.methods.findOpponent(characterId).send({ from: rootState.defaultAccount });

      return res;
    },

    async reRollOpponent({ rootState }: {rootState: IState}, characterId: number) {
      const { PvpCore } = rootState.contracts();
      if (!PvpCore || !rootState.defaultAccount) return;

      const res = await PvpCore.methods.reRollOpponent(characterId).send({ from: rootState.defaultAccount });

      return res;
    },

    async prepareDuel({ rootState }: {rootState: IState}, { characterId, duelOffsetCost }: { characterId: number, duelOffsetCost: number }) {
      const { PvpCore } = rootState.contracts();
      if (!PvpCore || !rootState.defaultAccount) return;

      const res = await PvpCore.methods.prepareDuel(characterId).send({ from: rootState.defaultAccount, value: duelOffsetCost });

      return res;
    },

    async withdrawRankedRewards({ rootState }: {rootState: IState}) {
      const { PvpRankings } = rootState.contracts();
      if (!PvpRankings || !rootState.defaultAccount) return;

      const res = await PvpRankings.methods.withdrawRankedRewards().send({ from: rootState.defaultAccount });

      return res;
    },

    async getPvpCoreContract({ rootState }: {rootState: IState}) {
      const { PvpCore } = rootState.contracts();
      if (!PvpCore || !rootState.defaultAccount) return;

      return PvpCore;
    },

    async getPvpRankingsContract({ rootState }: {rootState: IState}) {
      const { PvpRankings } = rootState.contracts();
      if (!PvpRankings || !rootState.defaultAccount) return;

      return PvpRankings;
    },

    async approvePvpSkillSpending({ rootState }: {rootState: IState}, amount: number) {
      const { PvpCore, SkillToken } = rootState.contracts();
      if (!PvpCore || !SkillToken || !rootState.defaultAccount) return;

      return await approveFeeFromAnyContractSimple(
        PvpCore,
        SkillToken,
        rootState.defaultAccount,
        defaultCallOptions(rootState),
        defaultCallOptions(rootState),
        new BigNumber(`${amount}`)
      );
    },
    async fetchFreeOpponentRerollTimestamp({ rootState }: {rootState: IState}, weaponId: number) {
      const { PvpCore } = rootState.contracts();
      if(!PvpCore || !rootState.defaultAccount) return;

      return await PvpCore.methods.specialWeaponRerollTimestamp(weaponId).call(defaultCallOptions(rootState));
    },
  },
};


export default pvp;