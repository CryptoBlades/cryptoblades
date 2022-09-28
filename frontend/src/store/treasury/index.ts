import {IState, IPartnerProject} from '@/interfaces';
import {Dispatch, Commit} from 'vuex';
import Web3 from 'web3';
const defaultCallOptions = (rootState:  IState) => ({ from: rootState.defaultAccount });
import {getGasPrice} from '../store';
import {SupportedProject} from '@/views/Treasury.vue';
import {NewPartnerProject} from '@/components/smart/AdminTabs/TreasuryAdmin.vue';
import {values} from 'lodash';
import Vue from 'vue';

export interface ITreasuryState {
  partnerProjects: Record<number, IPartnerProject>;
  partnerProjectMultipliers: Record<number, string>;
  partnerProjectRatios: Record<number, string>;
  defaultSlippage: string;
  payoutCurrencyId: string;
}

const treasury = {
  namespaced: true,
  state: {
    partnerProjects: {},
    partnerProjectMultipliers: {},
    partnerProjectRatios: {},
    defaultSlippage: '0',
    payoutCurrencyId: localStorage.getItem('payoutCurrencyId') || '-1',
  } as ITreasuryState,
  getters: {
    getPartnerProjects(state: ITreasuryState): IPartnerProject[] {
      return values(state.partnerProjects);
    }
  },
  mutations: {
    updatePartnerProjectsState(state: ITreasuryState, { partnerProjectId, partnerProject }: { partnerProjectId: number, partnerProject: IPartnerProject }) {
      Vue.set(state.partnerProjects, partnerProjectId, partnerProject);
    },

    updateDefaultSlippage(state: ITreasuryState, slippage: string) {
      state.defaultSlippage = slippage;
    },

    updatePartnerProjectMultiplier(state: ITreasuryState, { partnerProjectId, multiplier }: { partnerProjectId: number, multiplier: string }) {
      Vue.set(state.partnerProjectMultipliers, partnerProjectId, multiplier);
    },

    updatePartnerProjectRatio(state: ITreasuryState, { partnerProjectId, ratio }: { partnerProjectId: number, ratio: string }) {
      Vue.set(state.partnerProjectRatios, partnerProjectId, ratio);
    },
    updatePayoutCurrencyId(state: ITreasuryState, newPayoutCurrencyId: string) {
      localStorage.setItem('payoutCurrencyId', newPayoutCurrencyId);
      state.payoutCurrencyId = newPayoutCurrencyId;
    },
  },
  actions: {
    async addPartnerProject({ rootState }: {rootState: IState}, {partnerProject}: {partnerProject: NewPartnerProject}) {
      const { Treasury } = rootState.contracts();
      if(!Treasury || !rootState.defaultAccount) return;

      return await Treasury.methods.addPartnerProject(
        partnerProject.name,
        partnerProject.tokenSymbol,
        partnerProject.tokenAddress,
        partnerProject.tokenSupply!,
        Web3.utils.toWei(partnerProject?.tokenPrice?.toString()!, 'ether').toString(),
        partnerProject.distributionTime!,
        partnerProject.isActive,
        partnerProject.logo,
        partnerProject.details,
        partnerProject.website,
        partnerProject.note,
        partnerProject.isGold
      ).send({from: rootState.defaultAccount, gasPrice: getGasPrice()});
    },

    async getActivePartnerProjects({ rootState }: {rootState: IState}) {
      const { Treasury } = rootState.contracts();
      if(!Treasury || !rootState.defaultAccount) return;

      const ids = await Treasury.methods.getActivePartnerProjectsIds().call(defaultCallOptions(rootState));
      const projects = [];
      for(let i = 0; i < ids.length; i++) {
        const project = await Treasury.methods.partneredProjects(ids[i]).call(defaultCallOptions(rootState));
        projects.push(project);
      }
      return projects;
    },

    async setPartnerProjectLogo({ rootState }: {rootState: IState}, {id, logo}: {id: number | string, logo: string}) {
      const { Treasury } = rootState.contracts();
      if(!Treasury || !rootState.defaultAccount) return;

      await Treasury.methods.setProjectLogo(id, logo).send({from: rootState.defaultAccount, gasPrice: getGasPrice()});
    },

    async setPartnerProjectDetails({ rootState }: {rootState: IState}, {id, details}: {id: number | string, details: string}) {
      const { Treasury } = rootState.contracts();
      if(!Treasury || !rootState.defaultAccount) return;

      await Treasury.methods.setProjectDetails(id, details).send({from: rootState.defaultAccount, gasPrice: getGasPrice()});
    },

    async setPartnerProjectWebsite({ rootState }: {rootState: IState}, {id, website}: {id: number | string, website: string}) {
      const { Treasury } = rootState.contracts();
      if(!Treasury || !rootState.defaultAccount) return;

      await Treasury.methods.setProjectWebsite(id, website).send({from: rootState.defaultAccount, gasPrice: getGasPrice()});
    },

    async setPartnerProjectNote({ rootState }: {rootState: IState}, {id, note}: {id: number | string, note: string}) {
      const { Treasury } = rootState.contracts();
      if(!Treasury || !rootState.defaultAccount) return;

      await Treasury.methods.setProjectNote(id, note).send({from: rootState.defaultAccount, gasPrice: getGasPrice()});
    },

    async setPartnerProjectIsActive({ rootState }: {rootState: IState}, {id, isActive}: {id: number | string, isActive: boolean}) {
      const { Treasury } = rootState.contracts();
      if(!Treasury || !rootState.defaultAccount) return;

      await Treasury.methods.setIsActive(id, isActive).send({from: rootState.defaultAccount, gasPrice: getGasPrice()});
    },

    async setPartnerProjectIsGold({ rootState }: {rootState: IState}, {id, isGold}: {id: number | string, isGold: boolean}) {
      const { Treasury } = rootState.contracts();
      if(!Treasury || !rootState.defaultAccount) return;

      await Treasury.methods.setIsGold(id, isGold).send({from: rootState.defaultAccount, gasPrice: getGasPrice()});
    },

    async fetchPartnerProjects({ rootState, dispatch }: {rootState: IState, dispatch: Dispatch}) {
      const { Treasury } = rootState.contracts();
      if(!Treasury || !rootState.defaultAccount) return;

      const activePartnerProjectIds = await Treasury.methods.getActivePartnerProjectsIds().call(defaultCallOptions(rootState));
      activePartnerProjectIds.forEach(async (id: string) => {
        await dispatch('fetchPartnerProject', id);
      });

      await dispatch('fetchDefaultSlippage');
    },

    async fetchPartnerProject({ rootState, commit }: {rootState: IState, commit: Commit}, id: number | string) {
      const { Treasury } = rootState.contracts();
      if(!Treasury || !rootState.defaultAccount) return;
      const partnerProjectRaw = await Treasury.methods.partneredProjects(id).call(defaultCallOptions(rootState));
      const [
        isGold,
        tokensClaimed,
        data
      ] = await Promise.all([
        await Treasury.methods.projectIsGold(id).call(defaultCallOptions(rootState)),
        await Treasury.methods.tokensClaimed(id).call(defaultCallOptions(rootState)),
        await Treasury.methods.getProjectData(id).call(defaultCallOptions(rootState))
      ]);

      const partnerProject = {
        id: +partnerProjectRaw[0],
        name: partnerProjectRaw[1],
        tokenSymbol: partnerProjectRaw[2],
        tokenAddress: partnerProjectRaw[3],
        tokenSupply: +partnerProjectRaw[4],
        tokensClaimed: +tokensClaimed,
        tokenPrice: +partnerProjectRaw[5],
        isActive: partnerProjectRaw[6],
        isGold,
        logo: data[0],
        details: data[1],
        website: data[2],
        note: data[3],
      } as SupportedProject;

      commit('updatePartnerProjectsState', { partnerProjectId: partnerProject.id, partnerProject });
    },

    async fetchDefaultSlippage({ rootState, commit }: {rootState: IState, commit: Commit}) {
      const { Treasury } = rootState.contracts();
      if(!Treasury || !rootState.defaultAccount) return;

      const slippage = await Treasury.methods.defaultSlippage().call(defaultCallOptions(rootState));

      commit('updateDefaultSlippage', slippage);
    },

    async getPartnerProjectMultiplier({ rootState, commit }: {rootState: IState, commit: Commit}, id: number | string) {
      const { Treasury } = rootState.contracts();
      if(!Treasury || !rootState.defaultAccount) return;

      const multiplier = await Treasury.methods.getProjectMultiplier(id).call(defaultCallOptions(rootState));
      commit('updatePartnerProjectMultiplier', { partnerProjectId: id, multiplier });

      return multiplier;
    },

    async getPartnerProjectDistributionTime({ rootState }: {rootState: IState}, id: number | string) {
      const { Treasury } = rootState.contracts();
      if(!Treasury || !rootState.defaultAccount) return;

      return await Treasury.methods.projectDistributionTime(id).call(defaultCallOptions(rootState));
    },

    async getPartnerProjectClaimedAmount({ rootState }: {rootState: IState}, id: number | string) {
      const { Treasury } = rootState.contracts();
      if(!Treasury || !rootState.defaultAccount) return;

      return await Treasury.methods.tokensClaimed(id).call(defaultCallOptions(rootState));
    },

    async getSkillToPartnerRatio({ rootState, commit }: {rootState: IState, commit: Commit}, id: number | string) {
      const { Treasury } = rootState.contracts();
      if(!Treasury || !rootState.defaultAccount) return;

      const ratio = await Treasury.methods.getSkillToPartnerRatio(id).call(defaultCallOptions(rootState));
      commit('updatePartnerProjectRatio', { partnerProjectId: id, ratio });

      return ratio;
    },

    async getCurrentBestMultiplier({ rootState }: {rootState: IState}) {
      const { Treasury } = rootState.contracts();
      if(!Treasury || !rootState.defaultAccount) return;

      const ids = await Treasury.methods.getActivePartnerProjectsIds().call(defaultCallOptions(rootState));
      let bestMultiplier = 0;
      for(const id of ids) {
        const mul = +await Treasury.methods.getProjectMultiplier(id).call(defaultCallOptions(rootState));
        if(mul > bestMultiplier) {
          bestMultiplier = mul;
        }
      }

      return bestMultiplier;
    },

    async claimPartnerToken({ rootState, dispatch }: {rootState: IState, dispatch: Dispatch},
                            { id, skillAmount, currentMultiplier, slippage }:
                            {id: number, skillAmount: string, currentMultiplier: string, slippage: string}) {
      const { Treasury } = rootState.contracts();
      if(!Treasury || !rootState.defaultAccount) return;

      await Treasury.methods.claim(id, skillAmount, currentMultiplier, slippage).send({
        from: rootState.defaultAccount,
        gasPrice: getGasPrice()
      });

      await Promise.all([
        dispatch('fetchSkillBalance'),
        dispatch('combat/fetchFightRewardSkill'),
        dispatch('combat/fetchFightRewardGold'),
        dispatch('fetchPartnerProject', id)
      ]);
    },
  },
};


export default treasury;
