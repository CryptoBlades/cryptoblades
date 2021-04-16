import VueRouter from 'vue-router';

import Plaza from './views/Plaza.vue';
import Blacksmith from './views/Blacksmith.vue';
import Combat from './views/Combat.vue';
import Stake from './views/Stake.vue';
import SelectStakeType from './views/SelectStakeType.vue';

function createRouter(featureFlagStakeOnly: boolean) {
  if (featureFlagStakeOnly) {
    return new VueRouter({
      routes: [
        { path: '/', redirect: 'stake' },
        { path: '/stake', name: 'select-stake-type', component: SelectStakeType },
        { path: '/stake/:stakeType', name: 'stake', component: Stake, props: true },
      ]
    });
  }

  return new VueRouter({
    routes: [
      { path: '/', name: 'plaza', component: Plaza },
      { path: '/blacksmith', name: 'blacksmith', component: Blacksmith },
      { path: '/combat', name: 'combat', component: Combat },
      { path: '/stake', name: 'select-stake-type', component: SelectStakeType },
      { path: '/stake/:stakeType', name: 'stake', component: Stake, props: true },
    ]
  });
}

export default createRouter;
