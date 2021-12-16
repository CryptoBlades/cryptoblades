import BootstrapVue from 'bootstrap-vue';
import { BootstrapVueIcons } from 'bootstrap-vue';
import BootstrapVueDialog from 'bootstrap-vue-dialog';
import 'bootstrap/dist/css/bootstrap.css';
import 'bootstrap-vue/dist/bootstrap-vue.css';

import Vue from 'vue';
import Vuex from 'vuex';
import VueRouter from 'vue-router';
import VTooltip from 'v-tooltip';

import Web3 from 'web3';

import { createStore } from './store';
import createRouter from './router';

import App from './App.vue';

import Ads from 'vue-google-adsense';

import {
  raid as featureFlagRaid,
  stakeOnly as featureFlagStakeOnly,
  reforging as featureFlagReforging
} from './feature-flags';
import { getConfigValue } from './contracts';

import i18n from './i18n';

let expectedNetworkId: number | null = null;
if(getConfigValue('VUE_APP_EXPECTED_NETWORK_ID')) {
  expectedNetworkId = parseInt(getConfigValue('VUE_APP_EXPECTED_NETWORK_ID'), 10);
}
const expectedNetworkName = getConfigValue('VUE_APP_EXPECTED_NETWORK_NAME');

const web3 = new Web3(Web3.givenProvider || process.env.VUE_APP_WEB3_FALLBACK_PROVIDER);

Vue.config.productionTip = false;

Vue.use(Vuex);
Vue.use(VueRouter);
Vue.use(VTooltip);
Vue.use(BootstrapVue);
Vue.use(BootstrapVueDialog);

Vue.use(BootstrapVueIcons);

Vue.use(require('vue-script2'));
Vue.use(Ads.Adsense);

const store = createStore(web3);
const router = createRouter();

new Vue({
  render: h => h(App),
  router, store, i18n,
  provide: {
    web3,
    // maybe feature flags should just reference the feature-flags.ts module directly?
    featureFlagStakeOnly, featureFlagRaid, featureFlagReforging,
    expectedNetworkId, expectedNetworkName
  }
}).$mount('#app');
