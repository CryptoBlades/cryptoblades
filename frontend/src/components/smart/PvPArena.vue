<template>
  <div>

    <div v-if="!isLoading">
    <pvp-divider>
    </pvp-divider>
    </div>

        <b-row>
          <b-col>
            <div class="preloader-container"
              v-if="isLoading">
                <pvp-preloader></pvp-preloader>
                  <div class="preloader-text">
                    <span v-if="isLoading">Please wait ...</span>
                  </div>
            </div>
          </b-col>
        </b-row>

    <b-row
      id="arena-character-buttons"
      v-if="!isDuelResult && !isLoading">
      <b-col
        v-for="character in inPvPCharacters"
        :key="character.id">
      <pvp-character
              :character="character"
              :currentCharacterId="currentPvPCharacterId"
              :inPvP="false"></pvp-character>
      </b-col>
    </b-row>

    <b-row v-if="!isLoading">
      <div
        class="go-back-container">
        <span
            @click="goTo">
          <img
            id="go-back-img"
            src="../../assets/go-back.svg"/>GO BACK</span>
      </div>
    </b-row>

    <b-row
      v-if="!isDuelResult && !isLoading">
      <div class="timer-container">
        <span id="timer" v-text="this.pvp.decisionTime"/>
      </div>
    </b-row>

    <b-row
      v-if="!isDuelResult && !isLoading">
      <b-col>
        <b-row>
          <pvp-fighter
            :characterId="currentPvPCharacterId"
            :show="true"
            :isAttacker="true"></pvp-fighter>
        </b-row>
      </b-col>

      <b-col>
        <b-row>
          <div
            v-if="!this.pvp.hasPendingDuel && this.pvp.decisionTime == '00:00'"
            class="find-opponent-container"
            @click="findOpponent(currentPvPCharacterId)">
              <img id="find-opponent-img" src="../../assets/winged-shield.svg"/>
          </div>
          <div
            v-if="this.pvp.hasPendingDuel && this.pvp.decisionTime !== '00:00'"
            class="duel-container">
              <img
                  id="duel-img"
                  src="../../assets/crossed-swords.svg"
                  @click="performDuel(currentPvPCharacterId)"/>
          </div>
        </b-row>
        <b-row>
          <div
            class="withdraw-container">
              <span
                @click="characterWithdraw()">
                <img
                  id="withdraw-img"
                  src="../../assets/run.svg"/>WITHDRAW</span>
          </div>
          <div
            v-if="this.pvp.hasPendingDuel"
            class="reroll-container">
              <span
                @click="reRollOpponent(currentPvPCharacterId)">
                <img
                  id="reroll-img"
                  src="../../assets/rolling-dices.svg"/>REROLL</span>
          </div>
        </b-row>
        <b-row>
            <b-col>
              <div class="pvp-rewards-container">
                <span class="pvp-rewards-header">PvP Rewards</span>
                <div
                  class="arena-tier-container">
                    <span
                      class="arena-tier-label">
                        Arena Tier
                      <span class="arena-tier-value">{{getRewardsArenaTier}}</span></span>
                </div>
                <div class="ranking-rewards-pool-container">
                    <span
                      class="ranking-rewards-pool-label">
                        Rewards Pool
                      <span class="ranking-rewards-pool-value"> {{getRankingRewardsPool}}</span>Skill</span>
                </div>
                <div class="view-stats-container">
                  <span
                    class="view-stats-label"
                    @click="openStats()">VIEW STATS</span>
                </div>
              </div>
            </b-col>
        </b-row>
      </b-col>

      <b-col>
        <b-row>
          <pvp-fighter
            :characterId="this.pvp.duelByAttacker.defenderId"
            :show="this.pvp.hasPendingDuel && this.pvp.decisionTime !== '00:00'"
            :isAttacker="false"></pvp-fighter>
        </b-row>
      </b-col>
    </b-row>

    <b-row
      v-if="isDuelResult && !isLoading">
      <div class="duel-result-container">
        <div class="duel-result">
         <p
          class="duel-win-result-text"
          v-if="duelResult.attackerWon">YOU WIN</p>
         <p
          class="duel-lose-result-text"
          v-if="!duelResult.attackerWon">YOU LOST</p>
          <span
              class="duel-result-roll-label">You rolled
            </span>
            <span
              class="duel-result-roll-value"
              v-text="duelResult.attackerRoll"/><br>
            <span
              class="duel-result-roll-label">Enemy rolled
            </span>
            <span
              class="duel-result-roll-value"
              v-text="duelResult.defenderRoll"/><br>
        </div>
        <div class="duel-result-rewards"
          v-if="duelResult.attackerWon">
            <span
              class="duel-result-rewards-label">SKILL
            </span>
            <span
              class="duel-result-rewards-won-value">+ {{getDuelReward}}</span><br>
            <span
              class="duel-result-rewards-label">RANK POINTS
            </span>
            <span
              class="duel-result-rewards-won-value">+ {{winningPoints}}</span><br>
               <span
              class="duel-result-rewards-label">NEW RANK
            </span>
            <span
              class="duel-result-rewards-won-value">{{getNewRankAfterVictory}}</span><br>
        </div>
        <div class="duel-result-rewards"
          v-if="!duelResult.attackerWon">
            <span
              class="duel-result-rewards-label">SKILL
            </span>
            <span
              class="duel-result-rewards-lost-value">- {{getDuelReward}}</span><br>
            <span
              class="duel-result-rewards-label">RANK POINTS
            </span>
            <span
              class="duel-result-rewards-lost-value">- {{losingPoints}}</span><br>
              <span
              class="duel-result-rewards-label">NEW RANK
            </span>
            <span
              class="duel-result-rewards-lost-value">{{getNewRankAfterLoss}}</span><br>
        </div>

        <div class="duel-result-ok-button">
              <span
                @click="afterDuelChecks()">OK
              </span>
        </div>
      </div>
    </b-row>

    <div class="arena-footer">
    </div>

    <pvp-duel
      v-if="isPerformDuel"
      :attackerId="this.duelResult.attackerId"
      :defenderId="this.duelResult.defenderId"></pvp-duel>

    <b-modal
      id="withdraw-character"
      title="WITHDRAW CHARACTER"
      @ok="withdrawFromArena(currentPvPCharacterId)">
        <span class="withdraw-modal-question">Are you sure you want to withdraw
          <span class ="withdraw-modal-variable">{{getCharacterName(currentPvPCharacterId)}}</span> ?
        </span><br>
      <div class="withdraw-skill-balance-container">
        <div class="withdraw-skill-balance-header">Wagered Skill Balance</div>
        <div class="withdraw-skill-balance-content">
          <span class="withdraw-skill-balance-label">Wagered Skill</span>
          <span class="withdraw-skill-balance-value">{{getWageredSkill}}</span><br>
        </div>
      </div>
    </b-modal>

      <div>
        <pvp-stats v-if="this.pvp.showStats" :characterID="this.currentPvPCharacterId"></pvp-stats>
      </div>

  </div>
</template>

<script>
import { mapGetters, mapMutations, mapState } from 'vuex';
import PvPCharacter from './PvPCharacter.vue';
import PvPFighter from './PvPFighter.vue';
import PvPDuel from './PvPDuel.vue';
import PvPDivider from './PvPDivider.vue';
import PvPStats from './PvPStats.vue';
import PvPPreloader from './Preloader.vue';
import BN from 'bignumber.js';

export default {

  data(){
    return{
      isPerformDuel: false,
      isDuelResult: false,
      duelResult: null,
      totalWithdrawableSkill: '',
      isShown: false,
      previousDuelReward: '',
      newDuelReward: '',
      previousRankPoints: '',
      newRankPoints: '',
      showStats: false,
      winningPoints: 0,
      losingPoints: 0
    };
  },

  computed:{
    ...mapState(['pvp','isLoading']),
    ...mapGetters([
      'inPvPCharacters',
      'currentPvPCharacterId',
      'getCharacterName'
    ]),

    getDuelReward(){
      const duelReward = Math.abs(parseFloat(this.newDuelReward) - parseFloat(this.previousDuelReward)).toFixed(4);
      return duelReward;
    },

    getRankingPointAdjustment(){
      const rankPointAdjustment = Math.abs(this.previousRankPoints - this.newRankPoints);
      return rankPointAdjustment;
    },

    getWageredSkill(){
      const wageredSkill = new BN(this.pvp.wageredSkill).div(new BN(10).pow(18)).toFixed(4);
      return wageredSkill;
    },

    getNewRankAfterVictory() {
      return +(this.pvp.characterRankingPoints) + +(this.winningPoints);
    },

    getNewRankAfterLoss() {
      return +(this.pvp.characterRankingPoints) - +(this.losingPoints) < 0 ? 0 : +(this.pvp.characterRankingPoints) - +(this.losingPoints);
    },

    getRewardsArenaTier(){
      const rewardsArenaTier = this.pvp.rewards.tier;
      return rewardsArenaTier;
    },

    getRankingRewardsPool(){
      const rankingRewardsPool = new BN(this.pvp.rewards.rankingRewardsPool).div(new BN(10).pow(18)).toFixed(4);
      return rankingRewardsPool;
    }
  },

  methods:{
    ...mapMutations([
      'setCurrentCharacter',
      'setCurrentPvPCharacter',
      'updateShowStats',
      'updateIsLoading',
      'updateHasPendingDuel'
    ]),

    openStats(){
      this.updateShowStats(true);
    },

    async afterDuelChecks(){
      this.isDuelResult = !this.isDuelResult;

      if(this.pvp.participatingCharacters.length < 1){
        await this.$store.dispatch('fetchArenaPage', {page: '0'});
      }
      else{
        this.setCurrentPvPCharacter(this.pvp.participatingCharacters[0]);
        await this.$store.dispatch('updatePvPDetails', {characterID: this.pvp.participatingCharacters[0]});

      }
    },

    async goTo(){
      this.setCurrentCharacter(this.currentPvPCharacterId);

      await Promise.all([
        this.$store.dispatch('updatePvPDetails', {characterID: this.currentPvPCharacterId}),
        this.$store.dispatch('fetchArenaPage', {page: '0'})
      ]);
    },

    async findOpponent(characterID){
      this.updateIsLoading(true);
      try{
        await this.$store.dispatch('getOpponent', {characterID});
      }catch(err){
        console.log(err);
      }
      finally{
        this.updateIsLoading(false);
        this.clearAllTicker();
        this.ticker();
      }
    },

    async reRollOpponent(characterID){
      this.updateIsLoading(true);
      try{
        await this.$store.dispatch('reRollOpponent',{characterID});
      }catch(err){
        console.log(err);
      }
      finally{
        this.updateIsLoading(false);
        this.clearAllTicker();
        this.ticker();
      }
    },

    async performDuel(characterID){
      this.updateIsLoading(true);
      this.previousDuelReward = '';
      this.previousDuelReward = new BN(this.pvp.wageredSkill).div(new BN(10).pow(18)).toFixed(4);
      const currentBlock = await this.$store.dispatch('preparePerformDuel', {characterID});

      this.waitForDuel(characterID, currentBlock);

      this.updateIsLoading(false);
    },

    async waitForDuel(characterID, currentBlock){
      this.duelResult = await this.$store.dispatch('waitForDuelResult', {characterID, previousBlock: currentBlock});

      if(this.duelResult === undefined){
        this.isPerformDuel = false;
        this.isDuelResult = false;
      }
      else{
        this.isPerformDuel = true;
        this.isDuelResult = true;
        setTimeout(() => {
          this.isPerformDuel = false;
          this.clearAllTicker();
          this.ticker();
        },6000);
        this.newDuelReward = '';
        this.newDuelReward = new BN(this.duelResult.newDuelReward).div(new BN(10).pow(18)).toFixed(4);
      }
    },

    async withdrawFromArena(characterID){
      try{
        const inDuel = this.pvp.hasPendingDuel;

        await this.$store.dispatch('withdrawFromArena',{inDuel,characterID});
      }catch(err){
        console.log(err);
      }
    },

    ticker(){
      window.setInterval(this.getDecisionTime, 1000);
    },

    getDecisionTime(){

      const decisionTimeInterval = (this.pvp.duelByAttacker.createdAt * 1000) - 60000;

      const decisionTime = new Date(decisionTimeInterval);

      const currentDate = new Date();

      const distance =  decisionTime - currentDate;

      const minutes = new Date(distance).getMinutes();
      const seconds = new Date(distance).getSeconds();

      let formattedMinutes;
      let formattedSeconds;

      if(minutes < 10 ){
        formattedMinutes = `0${minutes.toString()}`;
      } else{
        formattedMinutes = minutes.toString();
      }
      if(seconds < 10 ){
        formattedSeconds = `0${seconds.toString()}`;
      } else {
        formattedSeconds = seconds.toString();
      }

      this.$store.dispatch('fetchDecisionTime',{decisionTime:`${formattedMinutes}:${formattedSeconds}`});

      if(distance < 0 || !this.pvp.hasPendingDuel){
        this.$store.dispatch('fetchDecisionTime',{decisionTime:'00:00'});
        this.clearAllTicker();
      }
    },

    clearAllTicker(){
      this.$store.dispatch('fetchDecisionTime',{decisionTime:'00:00'});
      for(let i=0;i<999999;i++){
        clearInterval(i);
      }
    },

    characterWithdraw(){
      this.$bvModal.show('withdraw-character');
    }

  },

  async created(){
    this.updateIsLoading(true);
    this.winningPoints = await this.$store.dispatch('fetchWinningPoints');
    this.losingPoints = await this.$store.dispatch('fetchLosingPoints');
    this.clearAllTicker();
    this.ticker();
    this.updateIsLoading(false);
  },

  components:{
    'pvp-character': PvPCharacter,
    'pvp-fighter': PvPFighter,
    'pvp-duel': PvPDuel,
    'pvp-divider': PvPDivider,
    'pvp-stats': PvPStats,
    'pvp-preloader': PvPPreloader
  }

};
</script>

<style>
#arena-character-buttons {
  border-bottom: 2px solid #968332;
  margin-bottom: 50px;
  padding-bottom: 40px;
  text-align: center;
}

.find-opponent-container {
  margin: auto;
  height: 200px;
  width: 200px;
}

#find-opponent-img:hover {
  text-shadow: 0 0 10px #fff, 0 0 20px #fff;
  animation: burn 1s 1 forwards;
  cursor: pointer;
}

.duel-container {
  margin: auto;
  height: 200px;
  width: 200px;
  margin-bottom: 50px;
}

#duel-img:hover {
  text-shadow: 0 0 10px #fff, 0 0 20px #fff;
  animation: burn 1s 1 forwards;
  cursor: pointer;
}

.withdraw-container {
  margin: auto;
  height: 25px;
  width: auto;
  cursor: pointer;
}

.withdraw-container:hover {
  text-shadow: 0 0 10px #fff, 0 0 20px #fff;
  animation: burn 1s 1 forwards;
}

#withdraw-img {
  height: 25px;
  width: 25px;
}

.go-back-container {
  margin-bottom: 10px;
  height: 25px;
  width: 200px;
  cursor: pointer;
}

.go-back-container:hover {
  text-shadow: 0 0 10px #fff, 0 0 20px #fff;
  animation: burn 1s 1 forwards;
}

#go-back-img {
  height: 25px;
  width: 25px;
}

.reroll-container {
  margin: auto;
  height: 25px;
  width: auto;
  cursor: pointer;
}

.reroll-container:hover {
  text-shadow: 0 0 10px #fff, 0 0 20px #fff;
  animation: burn 1s 1 forwards;
}

#reroll-img {
  height: 25px;
  width: 25px;
}

.arena-footer {
  border-top: 2px solid #968332;
  margin-top: 50px;
  height: 100px;
  width: auto;
}

.timer-container {
  margin: auto;
  height: 100px;
  margin-bottom: 10px;
}

#timer {
  color: white;
  font-size: 50px;
}

.duel-result-container {
  background-image: url('../../assets/duel-result-bg.svg');
  background-repeat: no-repeat;
  background-size: cover;
  background-color: transparent;
  background-position-x: -83px;
  background-position-y: -16px;
  height: 600px;
  width: 500px;
  margin: auto;
  animation: glow 3s infinite linear;
}

.duel-result {
  position: relative;
  top: 50px;
  text-align: center;
  height: 200px;
}

.duel-result-ok-button {
  text-align: center;
  font-weight: bold;
  font-size: 20px;
  margin: 180px auto;
  height: 30px;
  width: 100px;
  box-shadow: -10px 10px 20px #000;
  color: #fff;
}

.duel-result-ok-button:hover {
  cursor: pointer;
}

.duel-win-result-text {
  margin-bottom: 30px;
  font-size: 30px;
  font-weight: 900;
  font-family: initial;
  letter-spacing: 10px;
  color: #ffd20b;
  text-shadow: 0 0 10px #000, 0 0 20px #fff;
}

.duel-win-result-text::before {
    content: "";
    position: absolute;
    top: 20px;
    height: 80%;
    width: 40%;
    background-image: url("../../assets/victory-banner.svg");
    background-repeat: no-repeat;
    background-size: cover;
    filter: drop-shadow(0 0 10px #000) drop-shadow(0 0 20px #fff) drop-shadow(0 0 30px #ffd20b);
    z-index: -1;
}

.duel-lose-result-text {
  margin-bottom: 20px;
  font-size: 30px;
  font-weight: 900;
  font-family: initial;
  letter-spacing: 10px;
  color: rgb(107, 8, 8);
  text-shadow: 0 0 5px #000, 0 0 5px #fff;
}

.duel-lose-result-text::before {
    content: "";
    position: absolute;
    height: 90%;
    width: 46%;
    background-image: url("../../assets/blood.svg");
    background-repeat: no-repeat;
    background-size: cover;
    filter: drop-shadow(0 0 10px #000) drop-shadow(0 0 20px #fff) drop-shadow(0 0 30px #000);
    opacity: 0.8;
    z-index: -1;
}

.duel-result-rewards {
  text-align: center;
  font-weight: 900;
  font-size: 20px;
  margin: 60px auto;
}

.duel-result-rewards-label {
  font-size: 15px;
  font-weight: 900;
  color: #000;
}

.duel-result-rewards-won-value {
  font-size: 15px;
  font-weight: bold;
  color: greenyellow;
  text-shadow: 0 0 10px #fff;
}

.duel-result-rewards-lost-value {
  font-size: 15px;
  font-weight: bold;
  color: maroon;
  text-shadow: 0 0 10px #000;
}

.duel-result-roll-label {
  margin-right: 10px;
  font-size: 20px;
  font-weight: 900;
  color: #000;
  text-shadow: 0 0 10px #fff;
}

.duel-result-roll-value {
  font-size: 15px;
  letter-spacing: 1px;
  font-weight: bold;
  color: #fff;
  text-shadow: 0 0 10px #000;
}


.arena-tier-container {
  margin: auto;
  height: 25px;
}

.arena-tier-label {
  font-size: 15px;
  font-weight: bolder;
  color: #968332;
  letter-spacing: 1px;
}

.arena-tier-value {
  font-size: 15px;
  color: #fff;
}

.ranking-rewards-pool-container {
  margin: auto;
  height: 25px;
  width: auto;
}

.ranking-rewards-pool-label {
  font-size: 15px;
  font-weight: bolder;
  color: #968332;
  letter-spacing: 1px;
}

.ranking-rewards-pool-value {
  font-size: 15px;
  margin-right: 10px;
  color: #fff;
}

.view-stats-container {
  margin: auto;
  height: 25px;
  width: auto;
  margin-top: 20px;
  margin-bottom: 20px;
}

.view-stats-label {
  font-size: 15px;
  font-weight: bolder;
  color: #968332;
  letter-spacing: 1px;
  cursor: pointer;
}

.view-stats-label:hover{
  text-shadow: 0 0 10px #fff;
}

.pvp-rewards-container {
  margin: 40px auto;
  text-align: center;
  box-shadow: 0 0 10px #fff;
  border: 2px solid #968332;
  border-radius: 10px;
}

.pvp-rewards-header {
  font-size: 20px;
  font-weight: bolder;
  color: #968332;
  letter-spacing: 1px;
}

.not-withdrawable {
  cursor: not-allowed;
}

.withdraw-character {
  height: 200px;
}

.withdraw-modal-question {
  font-size: 15px;
  font-weight: bold;
  color:#968332;
}

.withdraw-modal-variable {
  font-size: 15px;
  font-weight: bold;
  color:#fff;
}

.withdraw-skill-balance-container {
  width: 80%;
  margin: 10px auto;
  text-align: center;
}

.withdraw-skill-balance-header {
  font-size: 20px;
  font-weight: 900;
  letter-spacing: 1px;
}

.withdraw-skill-balance-content {
  padding: 20px;
  margin-top: 10px;
  margin-bottom: 10px;
  border-radius: 10px;
  box-shadow: 0 0 20px #000;
}

.withdraw-skill-balance-label {
  font-size: 15px;
  font-weight: bold;
  letter-spacing: 1px;
  margin-right: 5px;
}

.withdraw-skill-balance-value {
  font-size: 15px;
  font-weight: bold;
  color: #fff;
}

.modal-title {
  font-size: 25px;
  letter-spacing: 2px;
  font-weight: bold;
  color: #968332;
}

.arena-preloader-container{
  height: 500px;
  margin-top: 10px;
  margin-bottom: 10px;
}


@keyframes burn {
  from {
    filter: drop-shadow( 0px 0px 0px #968332);
  }
  to {
    filter: drop-shadow( 0px 0px 50px #fff);
  }
}

@keyframes glow {
  0% {
    filter: drop-shadow( 0px 0px 0px #fff);
  }
  50% {
    filter: drop-shadow( 0px 0px 10px #fff);
  }
  100% {
    filter: drop-shadow( 0px 0px 0px #fff);
  }
}

</style>
