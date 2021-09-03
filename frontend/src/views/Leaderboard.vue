<template>
  <div class="body main-font">
    <b-card no-body>
      <div class="outcome" v-if="waitingLeaderboardOutcome">
        <i class="fas fa-spinner fa-spin"></i>
        Loading...
      </div>
      <b-tabs pills card vertical>
        <b-tab v-for="leaderboard in leaderboards" :key="leaderboard.key" :title="leaderboard.key">
          <b-card-text>
            <div class="offset-md-2 col-md-8 col-sm-12 col-xs-12">
              <div class="row">
                <div class="col-12">
                  <h3 class="text-center">{{ leaderboard.key }}</h3>
                </div>
              </div>

              <div class="row mt-2" v-for="(entry, pos) of leaderboard.leaderboard" :key="entry.name">
                <div class="col-7">
                  <strong class="mr-2 position-marker">#{{ pos + 1 }}</strong>
                  {{ entry.name }}
                  <b-icon v-if="matchesCharIdOrWallet(entry.name)" icon="star-fill" />
                </div>

                <div class="col-5 text-right">
                  {{ entry.value }} {{ leaderboard.units }}
                </div>
              </div>
            </div>
          </b-card-text>
        </b-tab>
      </b-tabs>
    </b-card>
  </div>
</template>

<script>
import { mapState } from 'vuex';
import { apiUrl } from '../utils/common';

export default {
  data() {
    return {
      leaderboards: [],
      waitingLeaderboardOutcome: false,
    };
  },

  async created() {
    this.waitingLeaderboardOutcome = true;
    const leaderboardData = await fetch(apiUrl('static/leaderboard'));
    const leaderboards = await leaderboardData.json();

    this.leaderboards = leaderboards.leaderboard;
    this.waitingLeaderboardOutcome = false;
  },

  methods: {
    matchesCharIdOrWallet(str) {
      return str.includes(this.defaultAcccount) || this.ownedCharacterIds.some(x => str.includes(`(ID ${x})`));
    }
  },

  computed: {
    ...mapState(['defaultAccount', 'ownedCharacterIds']),
  },
};
</script>

<style scoped>
.card {
  background-color: transparent !important;
}

.position-marker {
  display: inline-block;
  min-width: 30px;
}

.outcome {
  margin: auto;
  text-align: center;
  font-size: 1em;
}
</style>
