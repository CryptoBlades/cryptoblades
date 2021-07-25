import VueRouter, { RouteConfig } from 'vue-router';

import Plaza from './views/Plaza.vue';
import Blacksmith from './views/Blacksmith.vue';
import Combat from './views/Combat.vue';
import Stake from './views/Stake.vue';
import SelectStakeType from './views/SelectStakeType.vue';
import Raid from './views/Raid.vue';
import Market from './views/Market.vue';
import Seller from './views/Seller.vue';
import Leaderboard from './views/Leaderboard.vue';
import Portal from './views/Portal.vue';
import Options from './views/Options.vue';

import {
  raid as featureFlagRaid,
  stakeOnly as featureFlagStakeOnly,
  market as featureFlagMarket,
  portal as featureFlagPortal
} from './feature-flags';

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

  let marketRoutes: RouteConfig[] = [];
  if(featureFlagMarket) {
    marketRoutes = [
      { path: '/market/:category/:type/:id', name: 'marketSearch', component: Market },
      { path: '/market/seller/:sellerAddress', name: 'seller', component: Seller },
      { path: '/market/:category', name: 'market', component: Market, props: (route) => ({ category: route.params.category || '' })}
    ];
  }

  const router = new VueRouter({
    routes: [
      { path: '/', name: 'plaza', component: Plaza },
      { path: '/blacksmith', name: 'blacksmith', component: Blacksmith },
      { path: '/combat', name: 'combat', component: Combat },
      { path: '/leaderboard', name: 'leaderboard', component: Leaderboard },
      ...marketRoutes,
      { path: '/stake', name: 'select-stake-type', component: SelectStakeType },
      { path: '/stake/:stakeType', name: 'stake', component: Stake, props: true },
      { path: '/options', name: 'options', component: Options }
    ]
  });

  if(featureFlagRaid) {
    router.addRoute({ path: '/raid/', name: 'raid', component: Raid });
  }

  if(featureFlagPortal) {
    router.addRoute({ path: '/portal', name: 'portal', component: Portal });
  }

  return router;
}

export default createRouter;
