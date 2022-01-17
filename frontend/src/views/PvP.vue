<template>
  <div class="pvpWrapper">
    <div class="noCharacter" v-if="!currentCharacterId && currentCharacterId !== 0">
      {{$t('pvp.atLeastOneChar')}}
    </div>
    <div v-else>
      <pvp-nav-bar :tabNumber="tab" :hasRewards="hasRewards" @changeTab="onChangeTab" v-if="!isCharacterMatchMaking" />
      <pvp-arena
        v-if="tab === 0"
        @enterMatchMaking="handleEnterMatchMaking"
        @leaveMatchMaking="handleLeaveMatchMaking"
      />
      <pvp-leaderboards v-if="tab === 1" />
      <pvp-rewards v-if="tab === 2" />
    </div>
  </div>
</template>

<script>
import { mapState } from 'vuex';
import PvPNavBar from '../components/smart/PvPNavBar.vue';
import PvPLeaderboards from '../components/smart/PvPLeaderboards.vue';
import PvPRewards from '../components/smart/PvPRewards.vue';
import PvPArena from '../components/smart/PvPArena.vue';

export default {
  components: {
    'pvp-nav-bar': PvPNavBar,
    'pvp-rewards': PvPRewards,
    'pvp-arena': PvPArena,
    'pvp-leaderboards': PvPLeaderboards
  },

  data() {
    return {
      tab: 0,
      isCharacterMatchMaking: false,
      hasRewards: false,
    };
  },

  computed: {
    ...mapState(['currentCharacterId', 'contracts', 'defaultAccount']),
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
  },

  async created() {
    const playerRewards = await this.contracts().PvpArena.methods.getPlayerPrizePoolRewards().call({ from: this.defaultAccount });
    this.hasRewards = !!+playerRewards;
  },

  async updated() {
    const playerRewards = await this.contracts().PvpArena.methods.getPlayerPrizePoolRewards().call({ from: this.defaultAccount });

    this.hasRewards = !!+playerRewards;
  }
};
</script>

<style scoped lang="scss">
@font-face {
  font-family: 'Trajan';
  src: url('../assets/fonts/Trajan.ttf') format('truetype');
}
.pvpWrapper {
  min-height: 100vh;
  background-image: url('../assets/pvpBackgroundImage.png');
  padding: 1rem 4rem 4rem 4rem;
  margin: -2rem -1rem 0 -1rem;

  .noCharacter {
    margin-top: 3rem;
    font-size: 1rem;
    font-family: 'Roboto';
  }

  @media only screen and (min-width: 1440px) {
    padding: 1rem 6rem 6rem 6rem;
  }
  @media only screen and (min-width: 1980px) {
    padding: 3rem 18rem 18rem 18rem;
  }
}
</style>