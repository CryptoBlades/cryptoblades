import VueRouter from 'vue-router';

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
import Quests from './views/Quests.vue';
import NftDisplay from './views/NftDisplay.vue';
import Bridge from './views/Bridge.vue';
import Treasury from './views/Treasury.vue';

import {market, portal, raid, stakeOnly, pvp, quests, merchandise} from './feature-flags';
import Merchandise from '@/components/smart/Merchandise.vue';
import {currentChainSupportsMerchandise, currentChainSupportsPvP} from '@/utils/common';

export default function createRouter() {
  if (stakeOnly) {
    return new VueRouter({
      routes: [
        {path: '/', redirect: 'stake'},
        {path: '/stake', name: 'select-stake-type', component: SelectStakeType},
        {path: '/stake/:stakeType', name: 'stake', component: Stake, props: true},
      ]
    });
  }

  const router = new VueRouter({
    routes: [
      {path: '/', name: 'plaza', component: Plaza},
      {path: '/blacksmith', name: 'blacksmith', component: Blacksmith},
      {path: '/combat', name: 'combat', component: Combat},
      {path: '/leaderboard', name: 'leaderboard', component: Leaderboard},
      {path: '/stake', name: 'select-stake-type', component: SelectStakeType},
      {path: '/stake/:stakeType', name: 'stake', component: Stake, props: true},
      {path: '/options', name: 'options', component: Options},
      {path: '/nft-display', name: 'nft-display', component: NftDisplay},
      {path: '/nft-display/:nftTypeProp/:nftIdProp', component: NftDisplay, props: true},
      {path: '/bridge', name: 'bridge', component: Bridge},
      {path: '/treasury', name: 'treasury', component: Treasury},
    ]
  });

  if (market) {
    router.addRoute({path: '/market', name: 'market', component: Market});
  }

  if (raid) {
    router.addRoute({path: '/raid', name: 'raid', component: Raid});
  }

  if (portal) {
    router.addRoute({path: '/portal', name: 'portal', component: Portal});
  }

  if (quests) {
    router.addRoute({path: '/quests', name: 'quests', component: Quests});
  }

  if (pvp) {
    const pvpRoute = {
      path: '/pvp', name: 'pvp', component: PvP,
      beforeEnter: (to: any, from: any, next: any) => {
        if (to.name === 'pvp' && !currentChainSupportsPvP()) next(from);
        else next();
      }
    };
    router.addRoute(pvpRoute);
  }

  if (merchandise) {
    const merchandiseRoute = {
      path: '/merchandise', name: 'merchandise', component: Merchandise,
      beforeEnter: (to: any, from: any, next: any) => {
        if (to.name === 'merchandise' && !currentChainSupportsMerchandise()) next(from);
        else next();
      }
    };
    router.addRoute(merchandiseRoute);
  }

  return router;
}
