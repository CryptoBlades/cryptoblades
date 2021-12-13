<template>
  <div class="pvpWrapper">
    <div v-if="!currentCharacterId && currentCharacterId !== 0">
      You need at least one character to enter PvP!
    </div>
    <div v-else>
      <pvp-nav-bar :tabNumber="tab" @changeTab="onChangeTab" v-if="!isCharacterMatchMaking" />
      <pvp-arena
        v-if="tab === 0"
        @enterMatchMaking="handleEnterMatchMaking"
        @leaveMatchMaking="handleLeaveMatchMaking"
      />
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
      isCharacterMatchMaking: false
    };
  },

  computed: {
    ...mapState(['currentCharacterId']),
  },

  methods: {
    // TODO: Use router for this.
    onChangeTab(tabNumber) {
      this.tab = tabNumber;
    },

    handleEnterMatchMaking() {
      this.isCharacterMatchMaking = true;
    },

    handleLeaveMatchMaking() {
      this.isCharacterMatchMaking = false;
    }
  }
};
</script>

<style scoped lang="scss">
@font-face {
  font-family: 'Trajan';
  src: url('../../../assets/fonts/Trajan.ttf') format('truetype');
}
.pvpWrapper {
  background-image: url('../../../assets/pvpBackgroundImage.png');
  padding: 1rem 4rem 4rem 4rem;
  margin: -2rem -1rem 0 -1rem;
  @media only screen and (min-width: 1440px) {
    padding: 1rem 6rem 6rem 6rem;
  }
  @media only screen and (min-width: 1980px) {
    padding: 3rem 18rem 18rem 18rem;
  }
}
</style>