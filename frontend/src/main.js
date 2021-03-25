import Vue from 'vue';
import VueRouter from 'vue-router';
import Web3 from 'web3';

import router from './router';

import App from './App.vue';

const web3 = new Web3(Web3.givenProvider || process.env.VUE_APP_WEB3_FALLBACK_PROVIDER);

Vue.config.productionTip = false;

Vue.use(VueRouter);

new Vue({
  render: h => h(App),
  router,
  provide: {
    web3
  }
}).$mount('#app');
