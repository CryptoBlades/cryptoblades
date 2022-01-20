import VueRouter, { RouteConfig } from 'vue-router';

import Plaza from './views/Plaza.vue';
import Blacksmith from './views/Blacksmith.vue';
import Combat from './views/Combat.vue';
import Stake from './views/Stake.vue';
import SelectStakeType from './views/SelectStakeType.vue';
import Raid from './views/Raid.vue';
import Market from './views/Market.vue';
import Leaderboard from './views/Leaderboard.vue';
import Portal from './views/Portal.vue';
import Options from './views/Options.vue';
import PvP from './views/PvP.vue';
import NftDisplay from './views/NftDisplay.vue';
import Bridge from './views/Bridge.vue';
import Treasury from './views/Treasury.vue';

import {
  raid as featureFlagRaid,
  stakeOnly as featureFlagStakeOnly,
  market as featureFlagMarket,
  portal as featureFlagPortal,
  pvp as featureFlagPvP,
  merchandise as featureFlagMerchandise,
} from './feature-flags';
import Merchandise from '@/components/smart/Merchandise.vue';
import {currentChainSupportsMerchandise, currentChainSupportsPvP} from '@/utils/common';

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
      { path: '/market', name: 'market', component: Market }
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
      { path: '/options', name: 'options', component: Options },
      { path: '/nft-display', name: 'nft-display', component: NftDisplay },
      { path: '/nft-display/:nftTypeProp/:nftIdProp', component: NftDisplay, props: true },
      { path: '/bridge', name:'bridge', component: Bridge },
      { path: '/treasury', name: 'treasury', component: Treasury },
    ]
  });

  if(featureFlagRaid) {
    router.addRoute({ path: '/raid/', name: 'raid', component: Raid });
  }

  if(featureFlagPortal) {
    router.addRoute({ path: '/portal', name: 'portal', component: Portal });
  }

  const pvpRoute = { path: '/pvp', name: 'pvp', component:PvP,
    beforeEnter: (to: any, from: any, next: any) => {
      if (to.name === 'pvp' && !currentChainSupportsPvP()) next(from);
      else next();
    }
  };

  if(featureFlagPvP){
    router.addRoute(pvpRoute);
  }

  const merchandiseRoute = { path: '/merchandise', name: 'merchandise', component:Merchandise,
    beforeEnter: (to: any, from: any, next: any) => {
      if (to.name === 'merchandise' && !currentChainSupportsMerchandise()) next(from);
      else next();
    }
  };

  if(featureFlagMerchandise){
    router.addRoute(merchandiseRoute);
  }

  return router;
}

export default createRouter;
