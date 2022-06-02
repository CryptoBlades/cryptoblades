import VueRouter from 'vue-router';

import Dashboard from './views/Dashboard.vue';
import Character from './views/Character.vue';
import Blacksmith from './views/Blacksmith.vue';
import Combat from './views/Combat.vue';
import SelectStakeType from './views/SelectStakeType.vue';
import Raid from './views/Raid.vue';
import Leaderboard from './views/Leaderboard.vue';
import Portal from './views/Portal.vue';
import Options from './views/Options.vue';
import PvP from './views/PvP.vue';
import Quests from './views/Quests.vue';
import Admin from './views/Admin.vue';
import NftDisplay from './views/NftDisplay.vue';
import Bridge from './views/Bridge.vue';
import Treasury from './views/Treasury.vue';
import PlayToEarn from './views/PlayToEarn.vue';

import { portal, pvp, quests, raid} from './feature-flags';
import { currentChainSupportsPvP, currentChainSupportsQuests} from '@/utils/common';

export default function createRouter() {

  const router = new VueRouter({
    routes: [
      {path: '/', name: 'dashboard', component: Dashboard},
      {path: '/plaza', name: 'plaza', component: Character},
      {path: '/blacksmith', name: 'blacksmith', component: Blacksmith},
      {path: '/combat', name: 'combat', component: Combat},
      {path: '/leaderboard', name: 'leaderboard', component: Leaderboard},
      {path: '/stake', name: 'select-stake-type', component: SelectStakeType},
      {path: '/options', name: 'options', component: Options},
      {path: '/nft-display', name: 'nft-display', component: NftDisplay},
      {path: '/nft-display/:nftTypeProp/:nftIdProp', component: NftDisplay, props: true},
      {path: '/bridge', name: 'bridge', component: Bridge},
      {path: '/treasury', name: 'treasury', component: Treasury},
      {path: '/admin', name: 'admin', component: Admin},
      {path: '/play-to-earn', name: 'play-to-earn', component: PlayToEarn},
    ]
  });

  if (raid) {
    router.addRoute({path: '/raid', name: 'raid', component: Raid});
  }

  if (portal) {
    router.addRoute({path: '/portal', name: 'portal', component: Portal});
  }

  if (quests) {
    const questsRoute = {
      path: '/quests', name: 'quests', component: Quests,
      beforeEnter: (to: any, from: any, next: any) => {
        if (to.name === 'quests' && !currentChainSupportsQuests()) next(from);
        else next();
      }
    };
    router.addRoute(questsRoute);
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

  return router;
}
