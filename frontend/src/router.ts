import VueRouter from 'vue-router';

import Plaza from './views/Plaza.vue';
import Blacksmith from './views/Blacksmith.vue';
import Combat from './views/Combat.vue';
import Stake from './views/Stake.vue';
import SelectStakeType from './views/SelectStakeType.vue';
import Raid from './views/Raid.vue';

import { raid as featureFlagRaid, stakeOnly as featureFlagStakeOnly } from './feature-flags';

function createRouter() {
  if (featureFlagStakeOnly) {
    return new VueRouter({
      routes: [
        { path: '/', redirect: 'stake' },
        { path: '/stake', name: 'select-stake-type', component: SelectStakeType },
        { path: '/stake/:stakeType', name: 'stake', component: Stake, props: true },
      ]
    });
  }

  const router = new VueRouter({
    routes: [
      { path: '/', name: 'plaza', component: Plaza },
      { path: '/blacksmith', name: 'blacksmith', component: Blacksmith },
      { path: '/combat', name: 'combat', component: Combat },
      { path: '/stake', name: 'select-stake-type', component: SelectStakeType },
      { path: '/stake/:stakeType', name: 'stake', component: Stake, props: true },
    ]
  });

  if(featureFlagRaid) {
    router.addRoute({ path: '/raid/', name: 'raid', component: Raid });
  }

  return router;
}

export default createRouter;
