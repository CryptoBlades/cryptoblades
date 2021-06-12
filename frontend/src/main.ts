import Vue from 'vue';
import Vuex from 'vuex';
import VueRouter from 'vue-router';
import VTooltip from 'v-tooltip';
import Web3 from 'web3';

import { createStore } from './store';
import createRouter from './router';

import App from './App.vue';

import {
  raid as featureFlagRaid,
  stakeOnly as featureFlagStakeOnly,
  reforging as featureFlagReforging,
  market as featureFlagMarket,
  portal as featureFlagPortal
} from './feature-flags';

let expectedNetworkId: number | null = null;
if(process.env.VUE_APP_EXPECTED_NETWORK_ID) {
  expectedNetworkId = parseInt(process.env.VUE_APP_EXPECTED_NETWORK_ID, 10);
}
const expectedNetworkName = process.env.VUE_APP_EXPECTED_NETWORK_NAME;

const web3 = new Web3(Web3.givenProvider || process.env.VUE_APP_WEB3_FALLBACK_PROVIDER);

Vue.config.productionTip = false;

Vue.use(Vuex);
Vue.use(VueRouter);
Vue.use(VTooltip);

const store = createStore(web3);
const router = createRouter();

new Vue({
  render: h => h(App),
  router, store,
  provide: {
    web3,
    // maybe feature flags should just reference the feature-flags.ts module directly?
    featureFlagStakeOnly, featureFlagRaid, featureFlagReforging, featureFlagMarket, featureFlagPortal, expectedNetworkId, expectedNetworkName
  }
}).$mount('#app');
