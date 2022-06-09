import {IState} from '@/interfaces';
import {Dispatch, Commit} from 'vuex';
import Web3 from 'web3';
const defaultCallOptions = (rootState:  IState) => ({ from: rootState.defaultAccount });
import {getGasPrice} from '../store';
import {SupportedProject} from '@/views/Treasury.vue';
import {NewPartnerProject} from '@/components/smart/AdminTabs/TreasuryAdmin.vue';

const treasury = {
  actions: {
    async addPartnerProject({ rootState }: {rootState: IState}, {partnerProject}: {partnerProject: NewPartnerProject}) {
      const { Treasury } = rootState.contracts();
      if(!Treasury || !rootState.defaultAccount) return;

      return await Treasury.methods.addPartnerProject(
        partnerProject.name,
        partnerProject.tokenSymbol,
        partnerProject.tokenAddress,
        partnerProject?.tokenSupply,
        Web3.utils.toWei(partnerProject?.tokenPrice?.toString()!, 'ether').toString(),
        partnerProject.distributionTime!,
        partnerProject.isActive,
        partnerProject.logo,
        partnerProject.details,
        partnerProject.website,
        partnerProject.note,
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

    async setPartnerProjectLogo({ rootState }: {rootState: IState}, {id, logo}: {id: string, logo: string}) {
      const { Treasury } = rootState.contracts();
      if(!Treasury || !rootState.defaultAccount) return;

      await Treasury.methods.setProjectLogo(id, logo).send({from: rootState.defaultAccount, gasPrice: getGasPrice()});
    },

    async setPartnerProjectDetails({ rootState }: {rootState: IState}, {id, details}: {id: string, details: string}) {
      const { Treasury } = rootState.contracts();
      if(!Treasury || !rootState.defaultAccount) return;

      await Treasury.methods.setProjectDetails(id, details).send({from: rootState.defaultAccount, gasPrice: getGasPrice()});
    },

    async setPartnerProjectWebsite({ rootState }: {rootState: IState}, {id, website}: {id: string, website: string}) {
      const { Treasury } = rootState.contracts();
      if(!Treasury || !rootState.defaultAccount) return;

      await Treasury.methods.setProjectWebsite(id, website).send({from: rootState.defaultAccount, gasPrice: getGasPrice()});
    },

    async setPartnerProjectNote({ rootState }: {rootState: IState}, {id, note}: {id: string, note: string}) {
      const { Treasury } = rootState.contracts();
      if(!Treasury || !rootState.defaultAccount) return;

      await Treasury.methods.setProjectNote(id, note).send({from: rootState.defaultAccount, gasPrice: getGasPrice()});
    },

    async setPartnerProjectIsActive({ rootState }: {rootState: IState}, {id, isActive}: {id: string, isActive: boolean}) {
      const { Treasury } = rootState.contracts();
      if(!Treasury || !rootState.defaultAccount) return;

      await Treasury.methods.setIsActive(id, isActive).send({from: rootState.defaultAccount, gasPrice: getGasPrice()});
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

    async fetchPartnerProject({ rootState, commit }: {rootState: IState, commit: Commit},{id}: {id: string}) {
      const { Treasury } = rootState.contracts();
      if(!Treasury || !rootState.defaultAccount) return;

      const partnerProjectRaw = await Treasury.methods.partneredProjects(id).call(defaultCallOptions(rootState));
      const tokensClaimed = await Treasury.methods.tokensClaimed(id).call(defaultCallOptions(rootState));
      const data = await Treasury.methods.getProjectData(id).call(defaultCallOptions(rootState));

      const partnerProject = {
        id: +partnerProjectRaw[0],
        name: partnerProjectRaw[1],
        tokenSymbol: partnerProjectRaw[2],
        tokenAddress: partnerProjectRaw[3],
        tokenSupply: +partnerProjectRaw[4],
        tokensClaimed: +tokensClaimed,
        tokenPrice: +partnerProjectRaw[5],
        isActive: partnerProjectRaw[6],
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

    async getPartnerProjectMultiplier({ rootState, commit }: {rootState: IState, commit: Commit}, {id}: {id: string}) {
      const { Treasury } = rootState.contracts();
      if(!Treasury || !rootState.defaultAccount) return;

      const multiplier = await Treasury.methods.getProjectMultiplier(id).call(defaultCallOptions(rootState));
      commit('updatePartnerProjectMultiplier', { partnerProjectId: id, multiplier });

      return multiplier;
    },

    async getPartnerProjectDistributionTime({ rootState }: {rootState: IState}, {id}: {id: string}) {
      const { Treasury } = rootState.contracts();
      if(!Treasury || !rootState.defaultAccount) return;

      return await Treasury.methods.projectDistributionTime(id).call(defaultCallOptions(rootState));
    },

    async getPartnerProjectClaimedAmount({ rootState }: {rootState: IState}, {id}: {id: string}) {
      const { Treasury } = rootState.contracts();
      if(!Treasury || !rootState.defaultAccount) return;

      return await Treasury.methods.tokensClaimed(id).call(defaultCallOptions(rootState));
    },

    async getSkillToPartnerRatio({ rootState, commit }: {rootState: IState, commit: Commit}, {id}: {id: string}) {
      const { Treasury } = rootState.contracts();
      if(!Treasury || !rootState.defaultAccount) return;

      const ratio = await Treasury.methods.getSkillToPartnerRatio(id).call(defaultCallOptions(rootState));
      commit('updatePartnerProjectRatio', { partnerProjectId: id, ratio });

      return ratio;
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
        dispatch('fetchFightRewardSkill'),
        dispatch('fetchPartnerProject', id)
      ]);
    },
  },
};


export default treasury;