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
import NftDisplay from './views/NftDisplay.vue';
import Bridge from './views/Bridge.vue';
import Character from './views/Character.vue';

//new game UI
import Home from './views/Home.vue';

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
      { path: '/market', name: 'market', component: Market }
    ];
  }

  const router = new VueRouter({
    routes: [
      //new game ui
      { path: '/', name: 'home', component: Home },
      { path: '/play-to-earn', name: 'play-to-earn', component: Home },
      { path: '/character/:id', name: 'character', component: Character },
      { path: '/blacksmith', name: 'blacksmith', component: Blacksmith },
      { path: '/marketplace', name: 'marketplace', component: Market },
      { path: '/leaderboard', name: 'leaderboard', component: Leaderboard },
      //end new

      //old
      { path: '/plaza', name: 'plaza', component: Plaza },
      { path: '/combat', name: 'combat', component: Combat },
      ...marketRoutes,
      { path: '/stake', name: 'select-stake-type', component: SelectStakeType },
      { path: '/stake/:stakeType', name: 'stake', component: Stake, props: true },
      { path: '/options', name: 'options', component: Options },
      { path: '/nft-display', name: 'nft-display', component: NftDisplay },
      { path: '/nft-display/:nftTypeProp/:nftIdProp', component: NftDisplay, props: true },
      { path: '/bridge', name:'bridge', component: Bridge }
      //end old
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
