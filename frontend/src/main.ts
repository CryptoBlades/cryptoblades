import Vue from 'vue';
import Vuex from 'vuex';
import VueRouter from 'vue-router';
import VTooltip from 'v-tooltip';
import Web3 from 'web3';

import { createStore } from './store';
import createRouter from './router';

import App from './App.vue';

const featureFlagStakeOnly = ['1', 'true', 't'].includes((process.env.VUE_APP_STAKING_ONLY + '').toLowerCase());

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

const store = createStore(web3, featureFlagStakeOnly);
const router = createRouter(featureFlagStakeOnly);

new Vue({
  render: h => h(App),
  router, store,
  provide: {
    web3, featureFlagStakeOnly, expectedNetworkId, expectedNetworkName
  }
}).$mount('#app');
