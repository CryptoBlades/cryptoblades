import {
  IState,
} from '@/interfaces';
import {approveFeeFromAnyContractSimple} from '@/contract-call-utils';
import {abi as priceOracleAbi} from '@/../../build/contracts/IPriceOracle.json';
import {CartEntry} from '@/components/smart/VariantChoiceModal.vue';
import BigNumber from 'bignumber.js';
import {Dispatch} from 'vuex';


const defaultCallOptions = (rootState:  IState) => ({ from: rootState.defaultAccount });

interface IStateMerchandise {
  cartEntries: CartEntry[];
}

const merchandise = {
  state: {
    cartEntries: [],
  } as IStateMerchandise,
  getters: {
    getCartEntries(state: IStateMerchandise) {
      return state.cartEntries;
    }
  },
  mutations: {
    addCartEntry(state: IStateMerchandise, cartEntry: CartEntry) {
      const duplicatedEntry = state.cartEntries.find(entry => entry.variant.id === cartEntry.variant.id);
      if (duplicatedEntry) {
        const entryIndex = state.cartEntries.indexOf(duplicatedEntry);
        state.cartEntries.splice(entryIndex, 1);
      }
      state.cartEntries.push(cartEntry);
    },

    removeCartEntry(state: IStateMerchandise, cartEntry: CartEntry) {
      state.cartEntries.splice(state.cartEntries.indexOf(cartEntry), 1);
    },

    clearCartEntries(state: IStateMerchandise) {
      state.cartEntries = [];
    },
  },
  actions: {
    async currentSkillPrice({ rootState }: {rootState: IState}) {
      const { Merchandise } = rootState.contracts();
      if(!Merchandise || !rootState.defaultAccount) return;

      const skillOracle = await Merchandise.methods.skillOracle().call(defaultCallOptions(rootState));
      return await new rootState.web3.eth.Contract(priceOracleAbi as any[], skillOracle).methods
        .currentPrice().call(defaultCallOptions(rootState));
    },

    async createOrder(
      { rootState, dispatch }: {rootState: IState, dispatch: Dispatch},
      { orderNumber, payingAmount }: {orderNumber: number, payingAmount: string | number}) {
      const { CryptoBlades, SkillToken, Merchandise } = rootState.contracts();
      if(!CryptoBlades || !SkillToken || !Merchandise || !rootState.defaultAccount) return;

      const skillNeeded = await CryptoBlades.methods
        .getSkillNeededFromUserWallet(rootState.defaultAccount, payingAmount, true)
        .call(defaultCallOptions(rootState));

      await approveFeeFromAnyContractSimple(
        CryptoBlades,
        SkillToken,
        rootState.defaultAccount,
        defaultCallOptions(rootState),
        defaultCallOptions(rootState),
        new BigNumber(skillNeeded)
      );

      await Merchandise.methods
        .createOrder(orderNumber, payingAmount)
        .send({
          from: rootState.defaultAccount
        });

      dispatch('fetchSkillBalance');
    },
  },
};


export default merchandise;