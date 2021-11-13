<template>
  <div class="pvp-stats-overlay">

    <b-row>
      <div class="pvp-stats-close-button">
        <span @click="closeStats()" >X</span>
      </div>
    </b-row>

  <div class="pvp-stats-container"
    v-if="!isLoading">
    <b-row>
      <b-col class="pvp-stats-character-info" cols="6">
        <div class="pvp-stats-character">
          <img class="pvp-stats-character-image" :src="getCharacterArtById(characterID)"/>
        </div>
        <div class="pvp-stats-character-stats">
          <span class="pvp-stats-character-id-label">ID</span>
          <span class="pvp-stats-character-text"> {{characterID}}</span>
          <span class="pvp-stats-character-name-label">{{getCharacterName(characterID).toUpperCase()}}</span><br>
          <span class="pvp-stats-character-rank-points-label"> RANK POINTS </span>
          <span class="pvp-stats-character-text">{{getCharacterRankingPoints}}</span><br>
        </div>
        <div class="pvp-stats-season">
          <div class="pvp-stats-current-ranked-season">
            <span>SEASON {{this.pvp.currentRankedSeason}}</span>
          </div>
          <div>
            <span class="pvp-stats-current-ranked-season-begin-label">SEASON DURATION</span>
            <span class="pvp-stats-current-ranked-season-begin-text">{{convertDateTime(this.pvp.seasonStartedAt)}} - </span>
            <span class="pvp-stats-current-ranked-season-end-text">{{getDuration}}</span>
          </div>
        </div>
      </b-col>

      <b-col cols="6">
        <b-row>
          <b-col>
        <b-tabs class="pvp-stats" justified>
          <b-tab class="duel-history" title="DUEL HISTORY">
            <div class="duel-history-data-filter-container">
              <b-row>
                <b-col>
                  <span
                    v-bind:class="duelHistoryFilter === 0 ? 'active-duel-history-filter' : ''"
                    class="duel-history-filter"
                    @click="updateDuelHistoryFilter(0)">ALL</span>
                </b-col>
                <b-col>
                  <span
                  v-bind:class="duelHistoryFilter === 1 ? 'active-duel-history-filter' : ''"
                  class="duel-history-filter"
                  @click="updateDuelHistoryFilter(1)">ATTACK</span>
                </b-col>
                <b-col>
                  <span
                  v-bind:class="duelHistoryFilter === 2 ? 'active-duel-history-filter' : ''"
                  class="duel-history-filter"
                  @click="updateDuelHistoryFilter(2)">DEFEND</span>
                </b-col>
              </b-row>
            </div>
            <div v-if="duelHistory.attack.length > 0 || duelHistory.defend.length > 0">
              <div class="duel-history-data-header-container">
                <b-row>
                  <b-col>
                    <span>DATE</span>
                  </b-col>
                  <b-col>
                    <span>ATTACKER</span>
                  </b-col>
                  <b-col>
                    <span>DMG DEALT</span>
                  </b-col>
                  <b-col>
                    <span>DEFENDER</span>
                  </b-col>
                  <b-col>
                    <span>DMG DEALT</span>
                  </b-col>
                </b-row>
              </div>
              <div class="duel-history-data-container"
                   v-if="duelHistoryFilter === 0 || duelHistoryFilter === 1">
                <b-row
                  v-bind:class="duel.attackerWon ? 'duel-history-data-row-win' : 'duel-history-data-row-lose'"
                  v-for="duel in duelHistory.attack"
                  :key="duel.timestamp">
                    <b-col>
                      <span>{{duel.timestamp}}</span>
                    </b-col>
                    <b-col>
                      <span>{{duel.attackerId}}</span>
                    </b-col>
                    <b-col>
                      <span>{{duel.attackerRoll}}</span>
                    </b-col>
                    <b-col>
                      <span>{{duel.defenderId}}</span>
                    </b-col>
                    <b-col>
                      <span>{{duel.defenderRoll}}</span>
                    </b-col>
                </b-row>
              </div>
              <div class="duel-history-data-container"
                   v-if="duelHistoryFilter === 0 || duelHistoryFilter === 2">
                <b-row
                  v-bind:class="!duel.attackerWon ? 'duel-history-data-row-win' : 'duel-history-data-row-lose'"
                  v-for="duel in duelHistory.defend"
                  :key="duel.timestamp">
                    <b-col>
                      <span>{{duel.timestamp}}</span>
                    </b-col>
                    <b-col>
                      <span>{{duel.attackerId}}</span>
                    </b-col>
                    <b-col>
                      <span>{{duel.attackerRoll}}</span>
                    </b-col>
                    <b-col>
                      <span>{{duel.defenderId}}</span>
                    </b-col>
                    <b-col>
                      <span>{{duel.defenderRoll}}</span>
                    </b-col>
                </b-row>
              </div>
            </div>
            <div class="pvp-no-duel-found"
              v-if="duelHistory.attack.length === 0 && duelHistory.defend.length === 0">
              <span>No duel/s found.</span><br>
            </div>
          </b-tab>
          <b-tab class="leaderboards" title="LEADERBOARDS">
            <div class="leaderboard-tier">
              <span>Tier {{arenaTier}}</span>
            </div>
            <div class="leaderboard-ranks">
              <b-row>
                <b-col>
                  <div class="leaderboard-rank-header">
                    <span>RANK</span>
                  </div>
                </b-col>
                <b-col>
                  <div class="leaderboard-character-header">
                    <span>CHARACTER</span>
                  </div>
                </b-col>
                <b-col>
                  <div class="leaderboard-points-header">
                    <span>POINTS</span>
                  </div>
                </b-col>
                <b-col>
                  <div class="leaderboard-prize-header">
                    <span>PRIZE</span>
                  </div>
                </b-col>
              </b-row>
              <b-row
                v-bind:class="player.toString() === characterID.toString() ? 'top-rank-highlight' : ''"
                v-for="(player,index) in topRankers.characterID" :key="index">
                <b-col>
                  <div class="leaderboard-rank-body">
                    <span>{{index+1}}</span>
                  </div>
                </b-col>
                <b-col>
                  <div class="leaderboard-character-body">
                    <span>{{topRankers.characterID[index]}}</span>
                  </div>
                </b-col>
                <b-col>
                  <div class="leaderboard-points-body">
                    <span>{{topRankers.characterRankPoints[index]}}</span>
                  </div>
                </b-col>
                <b-col>
                  <div class="leaderboard-prize-body">
                    <span>{{getPrize(index)}} SKILL</span>
                  </div>
                </b-col>
              </b-row>
            </div>
            <div class="withdraw-reward" v-if="isTopRanker && getIsEndOfSeason">
                <span @click="withdrawReward()">WITHDRAW REWARD</span>
            </div>
          </b-tab>
        </b-tabs>
          </b-col>
        </b-row>
      </b-col>
    </b-row>
  </div>

  <b-row>
    <b-col>
      <div class="preloader-container"
        v-if="isLoading">
          <pvp-preloader></pvp-preloader>
          <div class="preloader-text" >
            <span v-if="isLoading">Please wait ...</span>
          </div>
      </div>
    </b-col>
  </b-row>

  </div>
</template>

<script>
import { toInteger } from 'lodash';
import { mapGetters, mapMutations, mapState } from 'vuex';
import { getCharacterArtById } from '../../character-arts-placeholder';
import PvPPreloader from './Preloader.vue';
import BN from 'bignumber.js';

export default {

  props: ['characterID'],

  data(){
    return {
      duelHistory: null,
      topRankers: null,
      prizePercentages: null,
      arenaTier: null,
      duelTimestamp: null,
      duelHistoryFilter: 0
    };
  },

  computed: {
    ...mapState(['pvp','isLoading']),
    ...mapGetters([
      'getCharacterName'
    ]),

    getDuration(){
      const endDate = toInteger(this.pvp.seasonStartedAt) + toInteger(this.pvp.seasonDuration);
      return this.convertDateTime(endDate);
    },

    getIsEndOfSeason(){
      const currentDate = new Date();
      const endDate = new Date((toInteger(this.pvp.seasonStartedAt) + toInteger(this.pvp.seasonDuration)) * 1000);

      return currentDate >= endDate;
    },

    isTopRanker(){
      const isTop = this.topRankers.characterID.includes(this.characterID.toString());
      return isTop;
    },

    getCharacterRankingPoints(){
      const characterRankingPoints = this.pvp.characterRankingPoints;
      return characterRankingPoints;
    },
  },

  methods:{
    ...mapMutations([
      'updateShowStats',
      'updateIsLoading'
    ]),

    getCharacterArtById,

    getPrize(index){
      const multiplier = this.prizePercentages[index];

      const rankingRewardsPool = new BN(this.pvp.rewards.rankingRewardsPool).div(new BN(10).pow(18)).toFixed(4);

      return (rankingRewardsPool*(multiplier/100)).toFixed(4);

    },

    closeStats(){
      this.updateShowStats(false);
    },

    async processLeaderboards(){
      this.arenaTier = await this.$store.dispatch('fetchArenaTier', {characterID: this.characterID});
      this.topRankers = await this.$store.dispatch('getTierTopRankers', {characterID: this.characterID});
      this.prizePercentages = await this.$store.dispatch('getPrizePercentages');
    },

    async processDuelHistory(){

      this.duelHistory = await this.$store.dispatch('fetchDuelHistory', {characterID: this.characterID});

      this.duelHistory = this.processDuelHistoryTimestamps(this.duelHistory);

    },

    processDuelHistoryTimestamps(duelHistory){

      duelHistory.attack.forEach(attack => {

        attack.timestamp = this.convertDateTime(attack.timestamp);

      });


      duelHistory.defend.forEach(defend => {

        defend.timestamp = this.convertDateTime(defend.timestamp);

      });


      return duelHistory;
    },

    convertDateTime(timestamp){
      const convertedTimestamp = (timestamp * 1000);
      let month = new Date(convertedTimestamp).getUTCMonth();
      const day = new Date(convertedTimestamp).getUTCDate();
      const year = new Date(convertedTimestamp).getFullYear();
      const hour = new Date(convertedTimestamp).getHours();
      const minutes = new Date(convertedTimestamp).getMinutes();
      const seconds = new Date(convertedTimestamp).getSeconds();

      if(month.toString() === '0'){
        month = 'Jan';
      }
      else if (month.toString() === '1'){
        month = 'Feb';
      }
      else if (month.toString() === '2'){
        month = 'Mar';
      }
      else if (month.toString() === '3'){
        month = 'Apr';
      }
      else if (month.toString() === '4'){
        month = 'May';
      }
      else if (month.toString() === '5'){
        month = 'June';
      }
      else if (month.toString() === '6'){
        month = 'July';
      }
      else if (month.toString() === '7'){
        month = 'Aug';
      }
      else if (month.toString() === '8'){
        month = 'Sept';
      }
      else if (month.toString() === '9'){
        month = 'Oct';
      }
      else if (month.toString() === '10'){
        month = 'Nov';
      }
      else if (month.toString() === '11'){
        month = 'Dec';
      }

      let adjustedDay = '';
      let adjustedHour = '';
      let adjustedMinutes = '';
      let adjustedSeconds = '';

      if(toInteger(hour) < 10){
        adjustedHour = '0'+ hour;
      }
      else{
        adjustedHour = hour;
      }
      if(toInteger(minutes) < 10){
        adjustedMinutes = '0'+ minutes;
      }
      else{
        adjustedMinutes = minutes;
      }
      if(toInteger(seconds) < 10){
        adjustedSeconds = '0'+ seconds;
      }
      else{
        adjustedSeconds = seconds;
      }

      adjustedDay = toInteger(day);

      const convertedDate = month + ' ' + adjustedDay + ' ' + year + ' '
          + adjustedHour + ':' + adjustedMinutes + ':' + adjustedSeconds;

      return convertedDate;
    },

    updateDuelHistoryFilter(filterFlag){
      this.duelHistoryFilter = filterFlag;
    },

    async withdrawReward(){
      this.$store.dispatch('withdrawRankedRewards');
    }

  },

  async created(){
    this.updateIsLoading(true);
    Promise.all([
      await this.$store.dispatch('fetchCurrentRankedSeason'),
      await this.$store.dispatch('fetchSeasonDuration'),
      await this.$store.dispatch('fetchSeasonStartedAt'),
      await this.processDuelHistory(),
      await this.processLeaderboards()]);
    this.updateIsLoading(false);
  },

  components:{
    'pvp-preloader': PvPPreloader
  }
};
</script>

<style>

.pvp-stats-overlay{
  position: fixed;
  top: 10%;
  margin: auto;
  background-color: #000;
  z-index: 99;
  height: 80%;
  width: 90%;
  overflow: hidden;
  border-radius: 10px;
  box-shadow: 0 0 10px #fff;
}

.pvp-stats-close-button{
  box-shadow: 0 0 10px #fff;
  border-radius: 50%;
  width: 25px;
  height: 25px;
  text-align: center;
  margin-left: auto;
  margin-right: 30px;
  margin-bottom: 20px;
  margin-top: 10px;
  cursor: pointer;
}

.pvp-stats-close-button:hover{
 background-color: #968332;
 color: #000;
}

.pvp-stats-container{
  margin: auto;
  height: 80%;
  width: 90%;
}

.pvp-stats{
  height: 450px;
  border-radius: 10px;
  box-shadow: 0 0 10px #fff;
}

.pvp-stats-character{
  margin: auto;
}

.pvp-stats-character-image{
  height: 100%;
  width: 100%;
}

.pvp-no-duel-found{
  font-size: 20px;
  font-weight: bold;
  width: 200px;
  height: 20px;
  margin: auto;
  margin-top: 20px;
  text-align: center;
}

.leaderboard-tier{
  margin: auto;
  font-size: 40px;
  font-weight: bold;
  width: 100px;
  text-align: center;
}

.leaderboard-rank-header{
  color: #fff;
  font-weight: bold;
  margin: auto;
  text-align: center;
}

.leaderboard-character-header{
  color: #fff;
  font-weight: bold;
  margin: auto;
  text-align: center;
}

.leaderboard-points-header{
  color: #fff;
  font-weight: bold;
  margin: auto;
  text-align: center;
}

.leaderboard-prize-header{
  color: #fff;
  font-weight: bold;
  margin: auto;
  text-align: center;
}

.leaderboard-rank-body{
  margin: auto;
  text-align: center;
  margin-top: 10px;
  margin-bottom: 10px;
  font-weight: bold;
}

.leaderboard-character-body{
  font-size: 15px;
  font-weight: bold;
  margin: auto;
  text-align: center;
  margin-top: 10px;
  margin-bottom: 10px;
  font-weight: bold;
}

.leaderboard-points-body{
  margin: auto;
  text-align: center;
  margin-top: 10px;
  margin-bottom: 10px;
  font-weight: bold;
}

.leaderboard-prize-body{
  margin: auto;
  text-align: center;
  margin-top: 10px;
  margin-bottom: 10px;
  font-weight: bold;
}

.withdraw-reward{
  height: auto;
  width: 200px;
  margin: auto;
  margin-top: 10px;
  margin-bottom: 10px;
  font-weight: bold;
  letter-spacing: 2px;
  text-align: center;
  cursor: pointer;
  box-shadow: 0 0 10px gold;
  border-radius: 10px;
}

.withdraw-reward:hover{
  text-shadow: 0 0px 5px #fff;
}

.pvp-stats-character-stats{
  background-color: #000;
  position: absolute;
  top: 340px;
  width: 80%;
  border-radius: 10px;
  box-shadow: 0 0 10px #fff;
  text-align: center;
  opacity: 0.8;
}

.pvp-stats-season{
  background-color: #000;
  position: absolute;
  top: 200px;
  height: 100px;
  width: 80%;
  border-radius: 10px;
  box-shadow: 0 0 10px #fff;
  text-align: center;
  opacity: 0.9;
}

.pvp-stats-character-id-label{
  opacity: 1 ;
  color: #fff;
}

.pvp-stats-character-name-label{
  opacity: 1;
  color: #fff;
  margin-left: 10px;
}

.pvp-stats-character-rank-points-label{
  opacity: 1;
  color: #fff;
}

.duel-history{
  height: 400px;
  overflow-y: scroll;
  overflow-x: hidden;
}

.duel-history-data-container{
  margin: auto;
  width: 90%;
  text-align: center;
}

.duel-history-data-header-container{
  margin: auto;
  margin-top: 10px;
  margin-bottom: 10px;
  width: 90%;
  text-align: center;
  text-align: center;
  font-weight: bold;
  color: #fff;
  border-top: 1px solid #968332;
  border-bottom: 1px solid #968332;
  border-radius: 5px;
  box-shadow: 0 0 5px #fff;
}

.duel-history-data-filter-container{
  margin: auto;
  margin-top: 10px;
  margin-bottom: 10px;
  width: 90%;
  text-align: center;
  font-weight: bold;
}

.duel-history-filter{
  cursor: pointer;
  color: #968332;
}

.duel-history-data-row-win{
  box-shadow: 0 0 5px greenyellow;
  border-radius: 5px;
  margin-top: 10px;
  margin-bottom: 10px;
  text-align: center;
}

.duel-history-data-row-lose{
  box-shadow: 0 0 5px red;
  border-radius: 5px;
  margin-top: 10px;
  margin-bottom: 10px;
  text-align: center;
}

.active-duel-history-filter{
  text-decoration: underline;
  text-decoration-color: #968332;
  text-decoration-style: double;
  text-decoration-thickness: 2px;
  text-shadow: 0 0 5px #fff;
  color: #fff;
}

.top-rank-highlight{
  text-shadow: 0 0 10px gold;
  color: #fff;
  text-decoration: underline;
  text-decoration-color: #968332;
}

.pvp-stats-current-ranked-season{
  margin: auto;
  font-size: 40px;
  font-weight: bold;
  text-align: center;
}

.pvp-stats-current-ranked-season-begin-label, .pvp-stats-current-ranked-season-end-label{
  margin-right: 20px;
  color: #fff;
  font-weight: bold;
}

.pvp-stats-current-ranked-season-begin-text, .pvp-stats-current-ranked-season-end-text{
  color: #968332;
  font-weight: bold;
}


</style>
