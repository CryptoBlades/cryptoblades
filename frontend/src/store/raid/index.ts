import {
  IState,
} from '@/interfaces';
import {Dispatch, Commit} from 'vuex';
import {approveFeeFromAnyContract} from '@/contract-call-utils';

const defaultCallOptions = (rootState:  IState) => ({ from: rootState.defaultAccount });
import { getGasPrice } from '../store';
import { IRaidState } from '@/interfaces';
import {raid as featureFlagRaid, stakeOnly as featureFlagStakeOnly} from '@/feature-flags';
import { raidFromContract} from '@/contract-models';

const raid = {
  state: {
    index: '0',
    expectedFinishTime: '0',
    raiderCount: '0',
    playerPower: '0',
    bossPower: '0',
    bossTrait: '0',
    status: '0',
    joinSkill: '0',
    staminaCost: '0',
    durabilityCost: '0',
    xpReward: '0',
    accountPower: '0',
  } as IRaidState,
  getters: {
    getRaidState(state: IRaidState) {
      return state;
    }
  },
  mutations: {
    updateRaidState(state: IRaidState, payload: { raidState: IRaidState }) {
      state.index = payload.raidState.index;
      state.expectedFinishTime = payload.raidState.expectedFinishTime;
      state.raiderCount = payload.raidState.raiderCount;
      state.playerPower = payload.raidState.playerPower;
      state.bossPower = payload.raidState.bossPower;
      state.bossTrait = payload.raidState.bossTrait;
      state.status = payload.raidState.status;
      state.joinSkill = payload.raidState.joinSkill;
      state.staminaCost = payload.raidState.staminaCost;
      state.durabilityCost = payload.raidState.durabilityCost;
      state.xpReward = payload.raidState.xpReward;
      state.accountPower = payload.raidState.accountPower;
    },
  },
  actions: {
    async joinRaid({ rootState, dispatch }: {rootState: IState, dispatch: Dispatch}, { characterId, weaponId }: {characterId: string, weaponId: string}) {
      const { CryptoBlades, SkillToken, Raid1 } = rootState.contracts();
      if(!Raid1 || !CryptoBlades || !SkillToken || !rootState.defaultAccount) {
        return;
      }

      await approveFeeFromAnyContract(
        CryptoBlades,
        Raid1,
        SkillToken,
        rootState.defaultAccount,
        getGasPrice(),
        rootState.skillRewards,
        defaultCallOptions(rootState),
        defaultCallOptions(rootState),
        raidsFunctions => raidsFunctions.getJoinCostInSkill(),
        {},
        true
      );

      await Raid1!.methods
        .joinRaid(characterId, weaponId)
        .send(defaultCallOptions(rootState));

      await dispatch('fetchSkillBalance');
    },

    async fetchRaidState({ rootState, commit }: {rootState: IState, commit: Commit}) {
      if(featureFlagStakeOnly || !featureFlagRaid) return;

      const Raid1 = rootState.contracts().Raid1!;

      await Promise.all([
        (async () => {
          const raidState: IRaidState = raidFromContract(
            await Raid1.methods.getRaidData().call(defaultCallOptions(rootState))
          );

          commit('updateRaidState', { raidState });
        })(),
      ]);
    },

    async fetchRaidRewards({ rootState }: {rootState: IState}, { startIndex, endIndex }: {startIndex: string, endIndex: string}) {
      const Raid1 = rootState.contracts().Raid1!;

      return await Raid1.methods
        .getEligibleRewardIndexes(startIndex, endIndex)
        .call(defaultCallOptions(rootState));
    },

    async fetchRaidingCharacters({ rootState }: {rootState: IState}) {
      const Raid1 = rootState.contracts().Raid1!;

      return await Raid1.methods
        .getParticipatingCharacters()
        .call(defaultCallOptions(rootState));
    },

    async fetchRaidingWeapons({ rootState }: {rootState: IState}) {
      const Raid1 = rootState.contracts().Raid1!;

      return await Raid1.methods
        .getParticipatingWeapons()
        .call(defaultCallOptions(rootState));
    },

    async fetchRaidJoinEligibility({ rootState }: {rootState: IState}, { characterID, weaponID }: {characterID: string, weaponID: string}) {
      const Raid1 = rootState.contracts().Raid1!;

      return await Raid1.methods
        .canJoinRaid(characterID, weaponID)
        .call(defaultCallOptions(rootState));
    },

    async fetchIsRaidStarted({ rootState }: {rootState: IState}) {
      const Raid1 = rootState.contracts().Raid1!;

      return await Raid1.methods
        .isRaidStarted()
        .call(defaultCallOptions(rootState));
    },

    async fetchHaveEnoughEnergy({ rootState }: {rootState: IState}, { characterID, weaponID }: { characterID: string, weaponID: string }) {
      const Raid1 = rootState.contracts().Raid1!;

      return await Raid1.methods
        .haveEnoughEnergy(characterID, weaponID)
        .call(defaultCallOptions(rootState));
    },

    async fetchIsCharacterRaiding({ rootState }: {rootState: IState}, { characterID }: { characterID: string }) {
      const Raid1 = rootState.contracts().Raid1!;

      return await Raid1.methods
        .isCharacterRaiding(characterID)
        .call(defaultCallOptions(rootState));
    },

    async fetchIsWeaponRaiding({ rootState }: {rootState: IState}, { weaponID }: { weaponID: string }) {
      const Raid1 = rootState.contracts().Raid1!;

      return await Raid1.methods
        .isWeaponRaiding(weaponID)
        .call(defaultCallOptions(rootState));
    },


    async claimRaidRewards({ rootState, dispatch }: {rootState: IState, dispatch: Dispatch}, { rewardIndex }: { rewardIndex: string }) {
      const Raid1 = rootState.contracts().Raid1!;

      const res = await Raid1!.methods
        .claimReward(rewardIndex)
        .send(defaultCallOptions(rootState));

      // claimreward does not reward trinket, those are given at raidcompletion by the bot

      if(res.events.RewardedJunk) {
        const junkIds = res.events.RewardedJunk.length ?
          res.events.RewardedJunk.map((x: { returnValues: { tokenID: any; }; }) => x.returnValues.tokenID) :
          [res.events.RewardedJunk.returnValues.tokenID];
        await dispatch('fetchJunks', junkIds);
      }

      if(res.events.RewardedKeyBox) {
        const keyboxIds = res.events.RewardedKeyBox.length ?
          res.events.RewardedKeyBox.map((x: { returnValues: { tokenID: any; }; }) => x.returnValues.tokenID) :
          [res.events.RewardedKeyBox.returnValues.tokenID];
        await dispatch('fetchKeyLootboxes', keyboxIds);
      }

      // there may be other events fired that can be used to obtain the exact loot
      // RewardedWeapon, RewardedJunk, RewardedTrinket, RewardedKeyBox etc
      const rewards = {
        rewardsClaimed: res.events.RewardClaimed?.returnValues,
        weapons: res.events.RewardedWeapon && (res.events.RewardedWeapon.length ?
          res.events.RewardedWeapon.map((x: { returnValues: any; })=> x.returnValues) :
          [res.events.RewardedWeapon.returnValues]),

        junks: res.events.RewardedJunk && (res.events.RewardedJunk.length ?
          res.events.RewardedJunk.map((x: { returnValues: any; })=> x.returnValues) :
          [res.events.RewardedJunk.returnValues]),

        keyboxes: res.events.RewardedKeyBox && (res.events.RewardedKeyBox.length ?
          res.events.RewardedKeyBox.map((x: { returnValues: any; })=> x.returnValues) :
          [res.events.RewardedKeyBox.returnValues]),

        bonusXp: res.events.RewardedXpBonus && (res.events.RewardedXpBonus.length ?
          res.events.RewardedXpBonus.map((x: { returnValues: any; })=> x.returnValues) :
          [res.events.RewardedXpBonus.returnValues]),

        dustLb: res.events.RewardedDustLB && (res.events.RewardedDustLB.length ?
          res.events.RewardedDustLB.map((x: { returnValues: any; })=> x.returnValues) :
          [res.events.RewardedDustLB.returnValues]),

        dust4b: res.events.RewardedDust4B && (res.events.RewardedDust4B.length ?
          res.events.RewardedDust4B.map((x: { returnValues: any; })=> x.returnValues) :
          [res.events.RewardedDust4B.returnValues]),

        dust5b: res.events.RewardedDust5B && (res.events.RewardedDust5B.length ?
          res.events.RewardedDust5B.map((x: { returnValues: any; })=> x.returnValues) :
          [res.events.RewardedDust5B.returnValues]),
      };
      return rewards;
    },
  },
};


export default raid;