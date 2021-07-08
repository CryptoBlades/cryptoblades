<template>
  <div class="body main-font">
    <b-card no-body>
      <b-tabs pills card vertical>
        <b-tab v-for="leaderboard in leaderboards" :key="leaderboard.key" :title="leaderboard.key">
          <b-card-text>
            <div class="offset-md-3 col-md-6 col-sm-12 col-xs-12">
              <div class="row">
                <div class="col-12">
                  <h3 class="text-center">{{ leaderboard.key }}</h3>
                </div>
              </div>

              <div class="row mt-2" v-for="(entry, pos) of leaderboard.leaderboard" :key="entry.name">
                <div class="col-9">
                  <strong class="mr-2 position-marker">#{{ pos + 1 }}</strong> {{ entry.name }}
                </div>

                <div class="col-3 text-right">
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

export default {
  data() {
    return {
      leaderboards: []
    };
  },

  async created() {
    const leaderboardData = await fetch('https://cryptoblades-api.herokuapp.com/static/leaderboard');
    const leaderboards = await leaderboardData.json();

    this.leaderboards = leaderboards.leaderboard;
  },

  methods: {
  },

  components: {
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
</style>
