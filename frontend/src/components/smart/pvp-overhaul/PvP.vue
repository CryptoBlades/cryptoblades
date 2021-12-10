<template>
  <div>
    <div v-if="!currentCharacterId && currentCharacterId !== 0">
      You need at least one character to enter PvP!
    </div>
    <div v-else>
      <pvp-nav-bar @changeTab="onChangeTab"/>
      <pvp-arena v-if="tab === 0" />
      <pvp-leaderboards v-if="tab === 1" />
    </div>
  </div>
</template>

<script>
import { mapState } from 'vuex';
import PvPNavBar from './components/PvPNavBar.vue';
import PvPLeaderboards from './leaderboards/PvPLeaderboards.vue';
import PvPArena from './pvp-arena/PvPArena.vue';

export default {
  components: {
    'pvp-nav-bar': PvPNavBar,
    'pvp-arena': PvPArena,
    'pvp-leaderboards': PvPLeaderboards
  },

  data() {
    return {
      tab: 0,
    };
  },

  computed: {
    ...mapState(['currentCharacterId']),
  },

  methods: {
    // TODO: Use router for this.
    onChangeTab(tabNumber) {
      this.tab = tabNumber;
    }
  }
};
</script>