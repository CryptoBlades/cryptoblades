import VueRouter from 'vue-router';

import Plaza from './views/Plaza.vue';
import Blacksmith from './views/Blacksmith.vue';
import Combat from './views/Combat.vue';
import Stake from './views/Stake.vue';

const router = new VueRouter({
  routes: [
    { path: '/', name: 'plaza', component: Plaza },
    { path: '/blacksmith', name: 'blacksmith', component: Blacksmith },
    { path: '/combat', name: 'combat', component: Combat },
    { path: '/stake', name: 'stake', component: Stake }
  ]
});

export default router;
