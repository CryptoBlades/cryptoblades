/* eslint-disable no-empty-pattern */
/* this sucks, but I couldn't find a way to get the correct arguments of the getters properly without having unused vars*/
/* using {rootState} is undefined. Getters args are defined as: (state: S, getters: any, rootState: R, rootGetters: any) (index.d.ts of vuex L118)*/
import {
  Contract,
  Contracts,
  isNftStakeType,
  isStakeType,
  IStakeOverviewState,
  IStakeState,
  IState,
  NftStakeType,
  StakeType
} from '@/interfaces';

import {IERC20, INftStakingRewards, IStakingRewards} from '@/../../build/abi-interfaces';

import {Dispatch, Commit} from 'vuex';
import Vue from 'vue';

const defaultCallOptions = (rootState:  IState) => ({ from: rootState.defaultAccount });
import {IERC721} from '@/../../build/abi-interfaces';
import { getGasPrice } from '../store';
import { stakeTypeThatCanHaveUnclaimedRewardsStakedTo } from '@/stake-types';


interface StakingContracts {
  StakingRewards: NftStakingRewardsAlias | StakingRewardsAlias,
  StakingToken: Contract<IERC20> | Contract<IERC721> | null,
  RewardToken: Contracts['SkillToken'],
}

type StakingRewardsAlias = Contract<IStakingRewards> | null;
type NftStakingRewardsAlias = Contract<INftStakingRewards> | null;


const defaultStakeState: IStakeState = {
  ownBalance: '0',
  stakedBalance: '0',
  remainingCapacityForDeposit: '0',
  remainingCapacityForWithdraw: '0',
  contractBalance: '0',
  currentRewardEarned: '0',
  rewardMinimumStakeTime: 0,
  rewardDistributionTimeLeft: 0,
  unlockTimeLeft: 0,
};

const defaultStakeOverviewState: IStakeOverviewState = {
  rewardRate: '0',
  rewardsDuration: 0,
  totalSupply: '0',
  minimumStakeTime: 0,
  rewardDistributionTimeLeft: 0
};


function getStakingContracts(contracts: Contracts, stakeType: StakeType | NftStakeType): StakingContracts {
  if(isNftStakeType(stakeType)) {
    return {
      StakingRewards: contracts.nftStaking[stakeType]?.StakingRewards || null,
      StakingToken: contracts.nftStaking[stakeType]?.StakingToken || null,
      RewardToken: contracts.SkillToken
    };
  }
  return {
    StakingRewards: contracts.staking[stakeType]?.StakingRewards || null,
    StakingToken: contracts.staking[stakeType]?.StakingToken || null,
    RewardToken: contracts.SkillToken
  };
}

interface IStake {
  staking: Record<StakeType | NftStakeType, IStakeState>;
  stakeOverviews: Record<StakeType | NftStakeType, IStakeOverviewState>;
}

const staking = {
  namespaced: true,
  state: {
    staking: {
      skill: { ...defaultStakeState },
      skill2: { ...defaultStakeState },
      lp: { ...defaultStakeState },
      lp2: { ...defaultStakeState },
      king: { ...defaultStakeState },
      king90: { ...defaultStakeState },
      king180: { ...defaultStakeState },
      skill90: { ...defaultStakeState },
      skill180: { ...defaultStakeState },
      cbkLandT1: { ...defaultStakeState },
      cbkLandT2: { ...defaultStakeState },
      cbkLandT3: { ...defaultStakeState }
    },
    stakeOverviews: {
      skill: { ...defaultStakeOverviewState },
      skill2: { ...defaultStakeOverviewState },
      lp: { ...defaultStakeOverviewState },
      lp2: { ...defaultStakeOverviewState },
      king: { ...defaultStakeOverviewState },
      king90: { ...defaultStakeOverviewState },
      king180: { ...defaultStakeOverviewState },
      skill90: { ...defaultStakeOverviewState },
      skill180: { ...defaultStakeOverviewState },
      cbkLandT1: { ...defaultStakeOverviewState },
      cbkLandT2: { ...defaultStakeOverviewState },
      cbkLandT3: { ...defaultStakeOverviewState }
    },
  } as IStake,
  getters: {
    availableStakeTypes({}, {}, rootState: IState): StakeType[] {
      return Object.keys(rootState.contracts().staking).filter(isStakeType);
    },

    availableNftStakeTypes({}, {}, rootState: IState): NftStakeType[] {
      return Object.keys(rootState.contracts().nftStaking).filter(isNftStakeType);
    },

    hasStakedBalance(state: IStake, {}, rootState: IState): boolean {
      if(!rootState.contracts) return false;

      const staking = rootState.contracts().staking;
      for(const stakeType of Object.keys(staking).filter(isStakeType)) {
        if(state.staking[stakeType].stakedBalance !== '0') {
          return true;
        }
      }
      return false;
    },

    stakedSkillBalanceThatCanBeSpent(state: IStake) {
      return state.staking[stakeTypeThatCanHaveUnclaimedRewardsStakedTo].stakedBalance;
    },
    stakeState(state: IStake) {
      return (stakeType: StakeType): IStakeState => state.staking[stakeType];
    },
  },
  mutations: {
    updateStakeData(state: IStake, { stakeType, ...payload }: { stakeType: StakeType } & IStakeState) {
      Vue.set(state.staking, stakeType, payload);
    },

    updateStakeOverviewDataPartial(state: IStake, payload: { stakeType: StakeType } & IStakeOverviewState) {
      const { stakeType, ...data } = payload;
      Vue.set(state.stakeOverviews, stakeType, data);
    },
  },
  actions: {
    async fetchStakeOverviewData({ getters, dispatch }: { getters: any, dispatch: Dispatch }) {
      await Promise.all(
        (getters.availableStakeTypes as StakeType[])
          .map(stakeType =>
            dispatch('fetchStakeOverviewDataPartial', { stakeType })
          ),
      );
      await Promise.all(
        (getters.availableNftStakeTypes as NftStakeType[])
          .map(stakeType =>
            dispatch('fetchStakeOverviewDataPartial', { stakeType })
          )
      );
    },

    async fetchStakeOverviewDataPartial({ rootState, commit }: {rootState: IState, commit: Commit}, { stakeType }: { stakeType: StakeType }) {
      const { StakingRewards } = getStakingContracts(rootState.contracts(), stakeType);
      if(!StakingRewards) return;

      const [
        rewardRate,
        rewardsDuration,
        totalSupply,
        minimumStakeTime,
        rewardDistributionTimeLeft,
      ] = await Promise.all([
        StakingRewards.methods.rewardRate().call(defaultCallOptions(rootState)),
        StakingRewards.methods.rewardsDuration().call(defaultCallOptions(rootState)),
        StakingRewards.methods.totalSupply().call(defaultCallOptions(rootState)),
        StakingRewards.methods.minimumStakeTime().call(defaultCallOptions(rootState)),
        StakingRewards.methods.getStakeRewardDistributionTimeLeft().call(defaultCallOptions(rootState)),
      ]);

      const stakeSkillOverviewData: IStakeOverviewState = {
        rewardRate,
        rewardsDuration: parseInt(rewardsDuration, 10),
        totalSupply,
        minimumStakeTime: parseInt(minimumStakeTime, 10),
        rewardDistributionTimeLeft: parseInt(rewardDistributionTimeLeft, 10),
      };
      commit('updateStakeOverviewDataPartial', { stakeType, ...stakeSkillOverviewData });
    },
    async fetchStakeDetails({ rootState, commit }: {rootState: IState, commit: Commit}, { stakeType }: { stakeType: StakeType }) {
      if(!rootState.defaultAccount) return;

      const { StakingRewards, StakingToken } = getStakingContracts(rootState.contracts(), stakeType);
      if(!StakingRewards || !StakingToken) return;

      const [
        ownBalance,
        stakedBalance,
        remainingCapacityForDeposit,
        remainingCapacityForWithdraw,
        contractBalance,
        currentRewardEarned,
        rewardMinimumStakeTime,
        rewardDistributionTimeLeft,
        unlockTimeLeft
      ] = await Promise.all([
        StakingToken.methods.balanceOf(rootState.defaultAccount).call(defaultCallOptions(rootState)),
        StakingRewards.methods.balanceOf(rootState.defaultAccount).call(defaultCallOptions(rootState)),
        Promise.resolve(null as string | null),
        StakingRewards.methods.totalSupply().call(defaultCallOptions(rootState)),
        StakingToken.methods.balanceOf(StakingRewards.options.address).call(defaultCallOptions(rootState)),
        StakingRewards.methods.earned(rootState.defaultAccount).call(defaultCallOptions(rootState)),
        StakingRewards.methods.minimumStakeTime().call(defaultCallOptions(rootState)),
        StakingRewards.methods.getStakeRewardDistributionTimeLeft().call(defaultCallOptions(rootState)),
        StakingRewards.methods.getStakeUnlockTimeLeft().call(defaultCallOptions(rootState)),
      ]);
      const stakeData: { stakeType: StakeType | NftStakeType } & IStakeState = {
        stakeType,
        ownBalance,
        stakedBalance,
        remainingCapacityForDeposit,
        remainingCapacityForWithdraw,
        contractBalance,
        currentRewardEarned,
        rewardMinimumStakeTime: parseInt(rewardMinimumStakeTime, 10),
        rewardDistributionTimeLeft: parseInt(rewardDistributionTimeLeft, 10),
        unlockTimeLeft: parseInt(unlockTimeLeft, 10)
      };
      commit('updateStakeData', stakeData);
    },

    async stake({ rootState, dispatch }: {rootState: IState, dispatch: Dispatch}, { amount, stakeType }: { amount: string, stakeType: StakeType }) {
      const { StakingRewards, StakingToken } = getStakingContracts(rootState.contracts(), stakeType);
      if(!StakingRewards || !StakingToken || !rootState.defaultAccount) return;

      await StakingToken.methods.approve(StakingRewards.options.address, amount).send({
        from: rootState.defaultAccount,
        gasPrice: getGasPrice(),
      });

      await StakingRewards.methods.stake(amount).send({
        from: rootState.defaultAccount,
        gasPrice: getGasPrice(),
      });

      await dispatch('fetchStakeDetails', { stakeType });
    },

    async stakeNfts({ rootState, dispatch }: {rootState: IState, dispatch: Dispatch}, { ids, stakeType }: { ids: string[], stakeType: StakeType }) {
      const { StakingRewards, StakingToken } = getStakingContracts(rootState.contracts(), stakeType);
      if(!StakingRewards || !StakingToken || !rootState.defaultAccount) return;

      if(ids.length === 1) {
        await StakingToken.methods.approve(StakingRewards.options.address, ids[0]).send({
          from: rootState.defaultAccount,
          gasPrice: getGasPrice(),
        });

        await StakingRewards.methods.stake(ids[0]).send({
          from: rootState.defaultAccount,
          gasPrice: getGasPrice(),
        });
      } else {
        await (StakingToken as Contract<IERC721>).methods.setApprovalForAll(StakingRewards.options.address, true).send({
          from: rootState.defaultAccount,
          gasPrice: getGasPrice(),
        });

        await (StakingRewards as Contract<INftStakingRewards>).methods.bulkStake(ids).send({
          from: rootState.defaultAccount,
          gasPrice: getGasPrice(),
        });
      }

      await dispatch('fetchStakeDetails', { stakeType });
    },

    async unstakeNfts({ rootState, dispatch }: {rootState: IState, dispatch: Dispatch}, { ids, stakeType }: { ids: string[], stakeType: StakeType }) {
      const { StakingRewards, StakingToken } = getStakingContracts(rootState.contracts(), stakeType);
      if(!StakingRewards || !StakingToken || !rootState.defaultAccount) return;

      if(ids.length === 1) {
        await StakingRewards.methods.withdraw(ids[0]).send({
          from: rootState.defaultAccount,
          gasPrice: getGasPrice(),
        });
      } else {
        await (StakingRewards as Contract<INftStakingRewards>).methods.bulkWithdraw(ids).send({
          from: rootState.defaultAccount,
          gasPrice: getGasPrice(),
        });
      }

      await dispatch('fetchStakeDetails', { stakeType });
    },

    async unstake({ rootState, dispatch }: {rootState: IState, dispatch: Dispatch}, { amount, stakeType }: { amount: string, stakeType: StakeType }) {
      const { StakingRewards } = getStakingContracts(rootState.contracts(), stakeType);
      if(!StakingRewards || !rootState.defaultAccount) return;

      await StakingRewards.methods.withdraw(amount).send({
        from: rootState.defaultAccount,
        gasPrice: getGasPrice(),
      });

      await dispatch('fetchStakeDetails', { stakeType });
    },

    async unstakeKing({ rootState, dispatch }: {rootState: IState, dispatch: Dispatch}, { amount }: { amount: string }) {
      const { KingStakingRewardsUpgradeable } = rootState.contracts();
      if(!KingStakingRewardsUpgradeable || !rootState.defaultAccount) return;

      await KingStakingRewardsUpgradeable.methods.withdrawWithoutFee(amount).send({
        from: rootState.defaultAccount,
        gasPrice: getGasPrice(),
      });

      await dispatch('fetchStakeDetails', { stakeType: 'king' });
    },

    async getStakedIds({ rootState }: {rootState: IState}, { stakeType }: { stakeType: StakeType }) {
      const { StakingRewards } = getStakingContracts(rootState.contracts(), stakeType);
      const CBKLand = rootState.contracts().CBKLand!;
      if(!StakingRewards || !CBKLand || !rootState.defaultAccount || !isNftStakeType(stakeType)) return;

      const stakedIds = await (StakingRewards as NftStakingRewardsAlias)?.methods.stakedIdsOf(rootState.defaultAccount).call({
        from: rootState.defaultAccount,
        gasPrice: getGasPrice(),
      });

      if(!stakedIds) return [];

      const landIdsWithTier = await Promise.all(stakedIds.map(async (landId: string) =>
      {
        const land = await CBKLand.methods.get(landId).call(defaultCallOptions(rootState));
        return { id: landId, tier: land[0] };
      }));

      return landIdsWithTier;
    },

    async claimKingReward({ rootState, dispatch }: {rootState: IState, dispatch: Dispatch}) {
      const { KingStakingRewardsUpgradeable } = rootState.contracts();
      if(!KingStakingRewardsUpgradeable) return;

      await KingStakingRewardsUpgradeable.methods.getRewardWithoutFee().send({
        from: rootState.defaultAccount,
        gasPrice: getGasPrice(),
      });

      await dispatch('fetchStakeDetails', { stakeType: 'king' });
    },

    async stakeUnclaimedRewards({ rootState, dispatch }: {rootState: IState, dispatch: Dispatch}, { stakeType }: { stakeType: StakeType }) {
      if(stakeType !== stakeTypeThatCanHaveUnclaimedRewardsStakedTo) return;

      const { CryptoBlades } = rootState.contracts();
      if(!CryptoBlades) return;

      await CryptoBlades.methods
        .stakeUnclaimedRewards()
        .send(defaultCallOptions(rootState));

      await Promise.all([
        dispatch('fetchSkillBalance'),
        dispatch('fetchStakeDetails', { stakeType }),
        dispatch('combat/fetchFightRewardSkill'),
        dispatch('combat/fetchFightRewardGold')
      ]);
    },

    async claimReward({ rootState, dispatch }: {rootState: IState, dispatch: Dispatch}, { stakeType }: { stakeType: StakeType }) {
      const { StakingRewards } = getStakingContracts(rootState.contracts(), stakeType);
      if(!StakingRewards) return;

      await StakingRewards.methods.getReward().send({
        from: rootState.defaultAccount,
        gasPrice: getGasPrice(),
      });

      await dispatch('fetchStakeDetails', { stakeType });
    },
  },
};


export default staking;
