import {IState} from '@/interfaces';
import {Dispatch, Commit} from 'vuex';
const defaultCallOptions = (rootState:  IState) => ({ from: rootState.defaultAccount });
import {getGasPrice} from '../store';
import {SpecialWeaponsEvent, OrderOption} from '@/components/smart/AdminTabs/SpecialWeaponsManagerAdmin.vue';
import {approveFeeWalletOnly} from '@/contract-call-utils';
import BigNumber from 'bignumber.js';
import Vue from 'vue';

const specialWeaponsManager = {
  mutattions: {
    updateShardsSupply(state: IState, { eventId, shardsSupply }: {eventId: number, shardsSupply: BigNumber}) {
      Vue.set(state.shardsSupply, eventId, shardsSupply);
    },
  },
  actions: {
    async fetchShardsSupply({ rootState, commit }: {rootState: IState, commit: Commit}) {
      const { SpecialWeaponsManager } = rootState.contracts();
      if(!SpecialWeaponsManager || !rootState.defaultAccount) return;

      const eventCount = +await SpecialWeaponsManager.methods.eventCount().call(defaultCallOptions(rootState));
      for(let i = 1; i <= eventCount; i++) {
        const eventShardsSupply = await SpecialWeaponsManager.methods.getUserSpecialShardsSupply(rootState.defaultAccount, i)
          .call(defaultCallOptions(rootState));
        commit('updateShardsSupply', { eventId: i, shardsSupply: +eventShardsSupply });
      }
    },
    async getActiveSpecialWeaponsEvents({ rootState }: {rootState: IState}) {
      const { SpecialWeaponsManager } = rootState.contracts();
      if(!SpecialWeaponsManager || !rootState.defaultAccount) return;

      const ids = await SpecialWeaponsManager.methods.getActiveEventsIds().call(defaultCallOptions(rootState));
      const events = [];
      for(let i = 0; i < ids.length; i++) {
        const project = await SpecialWeaponsManager.methods.eventInfo(ids[i]).call(defaultCallOptions(rootState));
        events.push({id: ids[i], ...project});
      }
      return events;
    },

    async startNewEvent({ rootState }: {rootState: IState}, event: SpecialWeaponsEvent) {
      const {SpecialWeaponsManager} = rootState.contracts();
      if (!SpecialWeaponsManager || !rootState.defaultAccount) return;

      await SpecialWeaponsManager.methods
        .startNewEvent(event.name!, event.element!, event.period!, event.supply!, event.art!, event.details!, event.website!, event.note!)
        .send({from: rootState.defaultAccount, gasPrice: getGasPrice()});
    },

    async setSpecialWeaponArt({ rootState }: {rootState: IState}, {eventId, art}: {eventId: number, art: string}) {
      const {SpecialWeaponsManager} = rootState.contracts();
      if (!SpecialWeaponsManager || !rootState.defaultAccount) return;

      await SpecialWeaponsManager.methods
        .setSpecialWeaponArt(eventId, art)
        .send({from: rootState.defaultAccount, gasPrice: getGasPrice()});
    },

    async setSpecialWeaponDetails({ rootState }: {rootState: IState}, {eventId, details}: {eventId: number, details: string}) {
      const {SpecialWeaponsManager} = rootState.contracts();
      if (!SpecialWeaponsManager || !rootState.defaultAccount) return;

      await SpecialWeaponsManager.methods
        .setSpecialWeaponDetails(eventId, details)
        .send({from: rootState.defaultAccount, gasPrice: getGasPrice()});
    },

    async setSpecialWeaponWebsite({ rootState }: {rootState: IState}, {eventId, website}: {eventId: number, website: string}) {
      const {SpecialWeaponsManager} = rootState.contracts();
      if (!SpecialWeaponsManager || !rootState.defaultAccount) return;

      await SpecialWeaponsManager.methods
        .setSpecialWeaponWebsite(eventId, website)
        .send({from: rootState.defaultAccount, gasPrice: getGasPrice()});
    },

    async setSpecialWeaponNote({ rootState }: {rootState: IState}, {eventId, note}: {eventId: number, note: string}) {
      const {SpecialWeaponsManager} = rootState.contracts();
      if (!SpecialWeaponsManager || !rootState.defaultAccount) return;

      await SpecialWeaponsManager.methods
        .setSpecialWeaponNote(eventId, note)
        .send({from: rootState.defaultAccount, gasPrice: getGasPrice()});
    },

    async incrementEventCount({ rootState }: {rootState: IState}) {
      const {SpecialWeaponsManager} = rootState.contracts();
      if (!SpecialWeaponsManager || !rootState.defaultAccount) return;

      await SpecialWeaponsManager.methods
        .incrementEventCount()
        .send({from: rootState.defaultAccount, gasPrice: getGasPrice()});
    },

    async addShards({ rootState }: {rootState: IState}, {user, eventId, shardsAmount}: {user: string, eventId: number, shardsAmount: number}) {
      const {SpecialWeaponsManager} = rootState.contracts();
      if (!SpecialWeaponsManager || !rootState.defaultAccount) return;

      await SpecialWeaponsManager.methods
        .addShards(user, eventId, shardsAmount)
        .send({from: rootState.defaultAccount, gasPrice: getGasPrice()});
    },

    async privatePartnerOrder(
      { rootState }: {rootState: IState},
      { receivers, eventId, orderOption}: {receivers: string[], eventId: number, orderOption: OrderOption}) {
      const {SpecialWeaponsManager} = rootState.contracts();
      if (!SpecialWeaponsManager || !rootState.defaultAccount) return;

      await SpecialWeaponsManager.methods
        .privatePartnerOrder(receivers, eventId, orderOption)
        .send({from: rootState.defaultAccount, gasPrice: getGasPrice()});
    },

    async privatePartnerMint(
      { rootState }: {rootState: IState},
      { receivers, eventId, orderOption}: {receivers: string[], eventId: number, orderOption: OrderOption}) {
      const {SpecialWeaponsManager} = rootState.contracts();
      if (!SpecialWeaponsManager || !rootState.defaultAccount) return;

      await SpecialWeaponsManager.methods
        .privatePartnerMint(receivers, eventId, orderOption)
        .send({from: rootState.defaultAccount, gasPrice: getGasPrice()});
    },

    async reserveForGiveaways(
      { rootState }: {rootState: IState},
      {reservingAddress, eventId, orderOption, amount}: {reservingAddress: string, eventId: number, orderOption: OrderOption, amount: number}) {
      const {SpecialWeaponsManager} = rootState.contracts();
      if (!SpecialWeaponsManager || !rootState.defaultAccount) return;

      await SpecialWeaponsManager.methods
        .reserveForGiveaways(reservingAddress, eventId, orderOption, amount)
        .send({from: rootState.defaultAccount, gasPrice: getGasPrice()});
    },

    async fetchSpecialWeaponEvents({ rootState, dispatch, commit }: {rootState: IState, dispatch: Dispatch, commit: Commit}) {
      const { SpecialWeaponsManager } = rootState.contracts();
      if(!SpecialWeaponsManager || !rootState.defaultAccount) return;

      const activeSpecialWeaponEventsIds = await SpecialWeaponsManager.methods.getActiveEventsIds().call(defaultCallOptions(rootState));
      commit('updateActiveSpecialWeaponEventsIds', activeSpecialWeaponEventsIds);

      const eventCount = await SpecialWeaponsManager.methods.eventCount().call(defaultCallOptions(rootState));
      const inactiveSpecialWeaponEventsIds = Array.from({length: +eventCount}, (_, i) =>
        (i + 1).toString()).filter(id => !activeSpecialWeaponEventsIds.includes(id));
      commit('updateInactiveSpecialWeaponEventsIds', inactiveSpecialWeaponEventsIds);

      await dispatch('fetchSpecialWeaponEventsInfo', activeSpecialWeaponEventsIds.concat(inactiveSpecialWeaponEventsIds));
      await dispatch('fetchShardsSupply');
    },

    async fetchSpecialWeaponArts({ rootState, commit }: {rootState: IState, commit: Commit}) {
      const { SpecialWeaponsManager } = rootState.contracts();
      if(!SpecialWeaponsManager || !rootState.defaultAccount) return;

      const allSpecialWeaponEventsIds = rootState.activeSpecialWeaponEventsIds.concat(rootState.inactiveSpecialWeaponEventsIds);
      for (let i = 0; i < allSpecialWeaponEventsIds.length; i++) {
        const eventId = allSpecialWeaponEventsIds[i];
        const art = await SpecialWeaponsManager.methods.specialWeaponArt(eventId).call(defaultCallOptions(rootState));
        commit('updateSpecialWeaponArt', { eventId, art });
      }
    },

    async fetchSpecialWeaponEventsInfo({ rootState, commit }: {rootState: IState, commit: Commit}, eventsIds: number[]) {
      const { SpecialWeaponsManager } = rootState.contracts();
      if(!SpecialWeaponsManager || !rootState.defaultAccount) return;

      eventsIds.forEach(async (eventId: number) => {
        const eventInfoRaw = await SpecialWeaponsManager.methods.getEventInfo(eventId).call(defaultCallOptions(rootState));
        const ordered = +await SpecialWeaponsManager.methods.userOrderOptionForEvent(rootState.defaultAccount!, eventId).call(defaultCallOptions(rootState))>0;
        const forged = await SpecialWeaponsManager.methods.userForgedAtEvent(rootState.defaultAccount!, eventId).call(defaultCallOptions(rootState));
        const eventData = await SpecialWeaponsManager.methods.getSpecialWeaponData(eventId).call(defaultCallOptions(rootState));
        const eventInfo = {
          name: eventInfoRaw[0],
          weaponElement: eventInfoRaw[1],
          endTime: eventInfoRaw[2],
          supply: eventInfoRaw[3],
          orderedCount: eventInfoRaw[4],
          ordered,
          forged,
          art: eventData[0],
          details: eventData[1],
          website: eventData[2],
          notes: eventData[3]
        };

        commit('updateSpecialWeaponEventsInfo', { eventId, eventInfo });
      });
    },

    async fetchForgeCosts({ rootState }: {rootState: IState}) {
      const { SpecialWeaponsManager } = rootState.contracts();
      if(!SpecialWeaponsManager || !rootState.defaultAccount) return;

      const shardsCostLow = await SpecialWeaponsManager.methods.vars(1).call(defaultCallOptions(rootState));
      const shardsCostMedium = await SpecialWeaponsManager.methods.vars(2).call(defaultCallOptions(rootState));
      const shardsCostHigh = await SpecialWeaponsManager.methods.vars(3).call(defaultCallOptions(rootState));
      const skillCostLow = await SpecialWeaponsManager.methods.getSkillForgeCost(1).call(defaultCallOptions(rootState));
      const skillCostMedium = await SpecialWeaponsManager.methods.getSkillForgeCost(2).call(defaultCallOptions(rootState));
      const skillCostHigh = await SpecialWeaponsManager.methods.getSkillForgeCost(3).call(defaultCallOptions(rootState));

      return [+shardsCostLow, +shardsCostMedium, +shardsCostHigh, +skillCostLow, +skillCostMedium, +skillCostHigh];
    },

    async convertShards(
      { rootState, dispatch }: {rootState: IState, dispatch: Dispatch},
      { eventFromId, eventToId, amount }: {eventFromId: number, eventToId: number, amount: number}) {
      const { SpecialWeaponsManager } = rootState.contracts();
      if(!SpecialWeaponsManager || !rootState.defaultAccount) return;

      await SpecialWeaponsManager.methods.convertShards(eventFromId, eventToId, amount).send({ from: rootState.defaultAccount, gasPrice: getGasPrice() });

      await dispatch('fetchShardsSupply');
    },

    async fetchShardsConvertDenominator({ rootState }: {rootState: IState}) {
      const { SpecialWeaponsManager } = rootState.contracts();
      if(!SpecialWeaponsManager || !rootState.defaultAccount) return;

      return +await SpecialWeaponsManager.methods.vars(10).call(defaultCallOptions(rootState));
    },

    async orderSpecialWeapon(
      { rootState, dispatch }: {rootState: IState, dispatch: Dispatch},
      { eventId, orderOption, orderWithSkill }: {eventId: number, orderOption: OrderOption, orderWithSkill: boolean}) {
      const { SpecialWeaponsManager, CryptoBlades, SkillToken } = rootState.contracts();
      if(!SpecialWeaponsManager || !CryptoBlades || !SkillToken || !rootState.defaultAccount) return;

      if(orderWithSkill) {
        const price = await SpecialWeaponsManager.methods.getSkillForgeCost(orderOption).call(defaultCallOptions(rootState));
        await approveFeeWalletOnly(
          CryptoBlades,
          SkillToken,
          rootState.defaultAccount,
          defaultCallOptions(rootState),
          defaultCallOptions(rootState),
          new BigNumber(price)
        );
        await SpecialWeaponsManager.methods.orderSpecialWeaponWithSkill(eventId, orderOption).send({ from: rootState.defaultAccount, gasPrice: getGasPrice()});
      }
      else {
        await SpecialWeaponsManager.methods.orderSpecialWeaponWithShards(eventId, orderOption).send({ from: rootState.defaultAccount, gasPrice: getGasPrice()});
      }

      await Promise.all([
        dispatch('fetchForgingStatus', eventId),
        dispatch('fetchShardsSupply'),
        dispatch('fetchSkillBalance')
      ]);
    },

    async forgeSpecialWeapon({ rootState, dispatch }: {rootState: IState, dispatch: Dispatch}, eventId: number) {
      const { SpecialWeaponsManager } = rootState.contracts();
      if(!SpecialWeaponsManager || !rootState.defaultAccount) return;

      await SpecialWeaponsManager.methods.forgeSpecialWeapon(eventId).send({ from: rootState.defaultAccount, gasPrice: getGasPrice() });

      await Promise.all([
        dispatch('updateWeaponIds'),
        dispatch('fetchForgingStatus', eventId),
      ]);
    },

    async fetchForgingStatus({ rootState, commit }: {rootState: IState, commit: Commit}, eventId: number) {
      const { SpecialWeaponsManager } = rootState.contracts();
      if(!SpecialWeaponsManager || !rootState.defaultAccount) return;

      const ordered = +await SpecialWeaponsManager.methods.userOrderOptionForEvent(rootState.defaultAccount!, eventId).call(defaultCallOptions(rootState)) > 0;
      const forged = await SpecialWeaponsManager.methods.userForgedAtEvent(rootState.defaultAccount, eventId).call(defaultCallOptions(rootState));

      commit('updateForgingStatus', { eventId, ordered, forged });
    },

    async fetchEventTotalOrderedCount({ rootState, commit }: {rootState: IState, commit: Commit}, eventId: number) {
      const { SpecialWeaponsManager } = rootState.contracts();
      if(!SpecialWeaponsManager || !rootState.defaultAccount) return;

      const orderedCount = await SpecialWeaponsManager.methods.getTotalOrderedCount(eventId).call(defaultCallOptions(rootState));

      commit('updateEventTotalOrderedCount', { eventId, orderedCount });
    },

    async fetchShardsStakingRewards({ rootState }: {rootState: IState}) {
      const { SpecialWeaponsManager } = rootState.contracts();
      if(!SpecialWeaponsManager || !rootState.defaultAccount) return;

      return await SpecialWeaponsManager.methods.getUserShardsRewards(rootState.defaultAccount).call(defaultCallOptions(rootState));
    },

    async claimShardsStakingRewards({ rootState, dispatch }: {rootState: IState, dispatch: Dispatch}, { eventId, amount }: {eventId: number, amount: number}) {
      const { SpecialWeaponsManager } = rootState.contracts();
      if(!SpecialWeaponsManager || !rootState.defaultAccount) return;

      await SpecialWeaponsManager.methods.claimShardRewards(eventId, amount).send(defaultCallOptions(rootState));

      await dispatch('fetchShardsSupply');
    },
  },
};


export default specialWeaponsManager;