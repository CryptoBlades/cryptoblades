import Vue from 'vue';
import Vuex from 'vuex';
import VueRouter from 'vue-router';
import Web3 from 'web3';

import { createStore } from './store';
import router from './router';

import App from './App.vue';

const web3 = new Web3(Web3.givenProvider || process.env.VUE_APP_WEB3_FALLBACK_PROVIDER);

Vue.config.productionTip = false;

Vue.use(Vuex);
Vue.use(VueRouter);

const store = createStore(web3);

new Vue({
  render: h => h(App),
  router, store,
  provide: {
    web3
  }
}).$mount('#app');
