<template>
  <div class="pvp-stats-overlay">

    <b-row>
      <div class="pvp-stats-close-button">
        <span @click="closeStats()" >Close</span>
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
      </b-col>

      <b-col class="pvp-stats" cols="6">
        <b-tabs justified>
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
                    <span>{{getCharacterName(player).toUpperCase()}}</span>
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
            <div class="withdraw-reward" v-if="isTopRanker">
                <span @click="withdrawReward()">WITHDRAW REWARD</span>
            </div>
          </b-tab>
        </b-tabs>
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
        const convertedTimestamp = (attack.timestamp * 1000) - 240000;
        let duelMonth = new Date(convertedTimestamp).getUTCMonth();
        const duelDay = new Date(convertedTimestamp).getUTCDate();
        const duelYear = new Date(convertedTimestamp).getFullYear();
        const duelHour = new Date(convertedTimestamp).getHours();
        const duelMinutes = new Date(convertedTimestamp).getMinutes();
        const duelSeconds = new Date(convertedTimestamp).getSeconds();

        if(duelMonth.toString() === '0'){
          duelMonth = 'Jan';
        }
        else if (duelMonth.toString() === '1'){
          duelMonth = 'Feb';
        }
        else if (duelMonth.toString() === '2'){
          duelMonth = 'Mar';
        }
        else if (duelMonth.toString() === '3'){
          duelMonth = 'Apr';
        }
        else if (duelMonth.toString() === '4'){
          duelMonth = 'May';
        }
        else if (duelMonth.toString() === '5'){
          duelMonth = 'June';
        }
        else if (duelMonth.toString() === '6'){
          duelMonth = 'July';
        }
        else if (duelMonth.toString() === '7'){
          duelMonth = 'Aug';
        }
        else if (duelMonth.toString() === '8'){
          duelMonth = 'Sept';
        }
        else if (duelMonth.toString() === '9'){
          duelMonth = 'Oct';
        }
        else if (duelMonth.toString() === '10'){
          duelMonth = 'Nov';
        }
        else if (duelMonth.toString() === '11'){
          duelMonth = 'Dec';
        }

        let adjustedDuelDay = '';
        let adjustedDuelHour = '';
        let adjustedDuelMinutes = '';
        let adjustedDuelSeconds = '';

        if(toInteger(duelHour) < 10){
          adjustedDuelHour = '0'+ duelHour;
        }
        else{
          adjustedDuelHour = duelHour;
        }
        if(toInteger(duelMinutes) < 10){
          adjustedDuelMinutes = '0'+ duelMinutes;
        }
        else{
          adjustedDuelMinutes = duelMinutes;
        }
        if(toInteger(duelSeconds) < 10){
          adjustedDuelSeconds = '0'+ duelSeconds;
        }
        else{
          adjustedDuelSeconds = duelSeconds;
        }

        adjustedDuelDay = toInteger(duelDay) + 1;

        const convertedDate = duelMonth + ' ' + adjustedDuelDay + ' ' + duelYear + ' '
          + adjustedDuelHour + ':' + adjustedDuelMinutes + ':' + adjustedDuelSeconds;

        attack.timestamp = convertedDate;

      });


      duelHistory.defend.forEach(defend => {
        const convertedTimestamp = (defend.timestamp * 1000) - 240000;
        let duelMonth = new Date(convertedTimestamp).getUTCMonth();
        const duelDay = new Date(convertedTimestamp).getUTCDate();
        const duelYear = new Date(convertedTimestamp).getFullYear();
        const duelHour = new Date(convertedTimestamp).getHours();
        const duelMinutes = new Date(convertedTimestamp).getMinutes();
        const duelSeconds = new Date(convertedTimestamp).getSeconds();

        if(duelMonth.toString() === '0'){
          duelMonth = 'Jan';
        }
        else if (duelMonth.toString() === '1'){
          duelMonth = 'Feb';
        }
        else if (duelMonth.toString() === '2'){
          duelMonth = 'Mar';
        }
        else if (duelMonth.toString() === '3'){
          duelMonth = 'Apr';
        }
        else if (duelMonth.toString() === '4'){
          duelMonth = 'May';
        }
        else if (duelMonth.toString() === '5'){
          duelMonth = 'June';
        }
        else if (duelMonth.toString() === '6'){
          duelMonth = 'July';
        }
        else if (duelMonth.toString() === '7'){
          duelMonth = 'Aug';
        }
        else if (duelMonth.toString() === '8'){
          duelMonth = 'Sept';
        }
        else if (duelMonth.toString() === '9'){
          duelMonth = 'Oct';
        }
        else if (duelMonth.toString() === '10'){
          duelMonth = 'Nov';
        }
        else if (duelMonth.toString() === '11'){
          duelMonth = 'Dec';
        }

        let adjustedDuelDay = '';
        let adjustedDuelHour = '';
        let adjustedDuelMinutes = '';
        let adjustedDuelSeconds = '';

        if(toInteger(duelHour) < 10){
          adjustedDuelHour = '0'+ duelHour;
        }
        else{
          adjustedDuelHour = duelHour;
        }
        if(toInteger(duelMinutes) < 10){
          adjustedDuelMinutes = '0'+ duelMinutes;
        }
        else{
          adjustedDuelMinutes = duelMinutes;
        }
        if(toInteger(duelSeconds) < 10){
          adjustedDuelSeconds = '0'+ duelSeconds;
        }
        else{
          adjustedDuelSeconds = duelSeconds;
        }

        adjustedDuelDay = toInteger(duelDay) + 1;

        const convertedDate = duelMonth + ' ' + adjustedDuelDay + ' ' + duelYear + ' '
          + adjustedDuelHour + ':' + adjustedDuelMinutes + ':' + adjustedDuelSeconds;

        defend.timestamp = convertedDate;

      });


      return duelHistory;
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
      await this.processDuelHistory(),
      await this.processLeaderboards()]);

    setTimeout(() => {
      this.updateIsLoading(false);
    }, 3000);
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
  margin-left: auto;
  margin-right: 25px;
  margin-bottom: 20px;
  margin-top: 10px;
  cursor: pointer;
}

.pvp-stats-close-button:hover{
  text-shadow: 0 0px 10px #fff;
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
  margin-left: 20px;
  height: 100%;
  width: 50%;
}

.pvp-stats-character-image{
  height: 150%;
  width: 150%;
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
  align-items: center;
}

.leaderboard-rank-header{
  color: #fff;
  font-weight: bold;
  margin: auto;
  align-items: center;
}

.leaderboard-character-header{
  color: #fff;
  font-weight: bold;
  margin: auto;
  align-items: center;
}

.leaderboard-points-header{
  color: #fff;
  font-weight: bold;
  margin: auto;
  align-items: center;
}

.leaderboard-prize-header{
  color: #fff;
  font-weight: bold;
  margin: auto;
  align-items: center;
}

.leaderboard-rank-body{
  margin: auto;
  align-items: center;
  margin-top: 10px;
  margin-bottom: 10px;
  font-weight: bold;
}

.leaderboard-character-body{
  font-size: 15px;
  font-weight: bold;
  margin: auto;
  align-items: center;
  margin-top: 10px;
  margin-bottom: 10px;
  font-weight: bold;
}

.leaderboard-points-body{
  margin: auto;
  align-items: center;
  margin-top: 10px;
  margin-bottom: 10px;
  font-weight: bold;
}

.leaderboard-prize-body{
  margin: auto;
  align-items: center;
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
  align-items: center;
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
  align-items: center;
}

.duel-history-data-row-lose{
  box-shadow: 0 0 5px red;
  border-radius: 5px;
  margin-top: 10px;
  margin-bottom: 10px;
  align-items: center;
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


</style>
