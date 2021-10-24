<template>
  <div>
    <div>
    <pvp-divider>
    </pvp-divider>
    </div>

    <b-row
      id="arena-character-buttons"
      v-if="!isDuelResult">
      <b-col
        v-for="character in inPvPCharacters"
        :key="character.id">
      <pvp-character
              :character="character"
              :currentCharacterId="currentPvPCharacterId"
              :inPvP="false"></pvp-character>
      </b-col>
    </b-row>

    <b-row>
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
      v-if="!isDuelResult">
      <div class="timer-container">
        <span id="timer" v-text="this.pvp.decisionTime"/>
      </div>
    </b-row>

    <b-row
      v-if="!isDuelResult">
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
            v-if="!getIsShown"
            class="find-opponent-container"
            @click="findOpponent(currentPvPCharacterId)">
              <img id="find-opponent-img" src="../../assets/winged-shield.svg"/>
          </div>
          <div
            v-if="getIsShown"
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
            v-if="getIsShown"
            class="reroll-container">
              <span
                @click="reRollOpponent(currentPvPCharacterId)">
                <img
                  id="reroll-img"
                  src="../../assets/rolling-dices.svg"/>REROLL</span>
          </div>
        </b-row>
        <b-row>
          <div
            class="total-duel-earnings-container">
              <span
                @click="checkIfWithdrawableAllUnclaimed"
                class="total-duel-earnings-label">
                Total Duel Earnings
                <span class="total-duel-earnings-value"> {{getAllUnclaimedDuelEarnings}}</span>Skill</span>
          </div>
        </b-row>
        <b-row>
          <div
            class="duel-earnings-container">
              <span
                @click="checkIfWithdrawableUnclaimedById"
                class="duel-earnings-label">
                Duel Earnings
                <span class="total-duel-earnings-value"> {{getDuelEarnings}}</span>Skill</span>
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
                <div
                  class="ranking-rewards-pool-container">
                    <span
                      class="ranking-rewards-pool-label">
                        Rewards Pool
                      <span class="ranking-rewards-pool-value"> {{getRankingRewardsPool}}</span>Skill</span>
                </div>
              </div>
            </b-col>
          </b-row>
      </b-col>

      <b-col>
        <b-row>
          <pvp-fighter
            :characterId="this.pvp.duelByAttacker.defenderId"
            :show="getIsShown"
            :isAttacker="false"></pvp-fighter>
        </b-row>
      </b-col>
    </b-row>

    <b-row
      v-if="isDuelResult">
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
        <div class="duel-result-rewards">
            <span
              class="duel-result-rewards-label">Reward
            </span>
            <span
              class="duel-result-rewards-value"
              v-text="getDuelReward"/><br>
            <span
              class="duel-result-rewards-label">Duel Earnings
            </span>
            <span
              class="duel-result-rewards-value"
              v-text="getDuelEarnings"/><br>
        </div>
        <div class="duel-result-ok-button">
              <span
                @click="isDuelResult = !isDuelResult">OK
              </span>
        </div>
      </div>
    </b-row>

    <div class="arena-footer">
    </div>

    <pvp-duel
      v-if="isPerformDuel"
      :attackerId="this.duelResult.attackerId"
      :defenderId="this.duelResult.defenderId"
      :isWon="true"></pvp-duel>

    <b-modal id="withdraw-warning" title="STOP RIGHT THERE!" ok-only>
      <span class="withdraw-modal-question">Come on, you can't withdraw
        <span class="withdraw-modal-variable">{{getDuelEarnings}}</span> earnings.</span>
    </b-modal>

    <b-modal
        id='withdraw-duel-earnings'
        title="WITHDRAW DUEL EARNINGS"
        @ok="withdrawUnclaimedDuelEarningsByCharacterId(currentPvPCharacterId)">
      <span class="withdraw-modal-question">Are you sure you want to withdraw
        <span class="withdraw-modal-variable">{{getDuelEarnings}}</span> Skill?</span>
    </b-modal>

    <b-modal
        id='withdraw-all-duel-earnings'
        title="WITHDRAW TOTAL DUEL EARNINGS"
        @ok="withdrawAllUnclaimedDuelEarnings()">
      <span class="withdraw-modal-question">Are you sure you want to withdraw
        <span class="withdraw-modal-variable">{{getAllUnclaimedDuelEarnings}}</span> Skill?</span>
    </b-modal>

    <b-modal
      id="withdraw-character"
      title="WITHDRAW CHARACTER"
      @ok="withdrawFromArena(currentPvPCharacterId)">
        <span class="withdraw-modal-question">Are you sure you want to withdraw
          <span class ="withdraw-modal-variable">{{getCharacterName(currentPvPCharacterId)}}</span> ?
        </span><br>
      <div class="withdraw-skill-balance-container">
        <div class="withdraw-skill-balance-header">Skill Balance</div>
        <div class="withdraw-skill-balance-content">

        <span class="withdraw-skill-balance-label">Duel Earnings</span>
        <span class="withdraw-skill-balance-value">{{getDuelEarnings}}</span><br>
        <span class="withdraw-skill-balance-label">Wagered Skill</span>
        <span class="withdraw-skill-balance-value">{{getWageredSkill}}</span><br>
        <span class="withdraw-skill-balance-label">Total Withdrawable Skill</span>
        <span class="withdraw-skill-balance-value">{{getTotalWithdrawableSkill}}</span><br>
        </div>
      </div>
    </b-modal>

  </div>
</template>

<script>
import { mapGetters, mapMutations, mapState } from 'vuex';
import PvPCharacter from './PvPCharacter.vue';
import PvPFighter from './PvPFighter.vue';
import PvPDuel from './PvPDuel.vue';
import PvPDivider from './PvPDivider.vue';
import BN from 'bignumber.js';

export default {

  data(){
    return{
      isPerformDuel: false,
      isDuelResult: false,
      duelResult: null,
      allUnclaimedDuelEarnings: '',
      duelEarnings: '',
      totalWithdrawableSkill: '',
      isShown: false,
      previousDuelReward: '',
      newDuelReward: ''
    };
  },

  computed:{
    ...mapState(['pvp']),
    ...mapGetters([
      'inPvPCharacters',
      'currentPvPCharacterId',
      'getCharacterName'
    ]),

    getDuelReward(){
      const duelReward = Math.abs(parseFloat(this.newDuelReward) - parseFloat(this.previousDuelReward)).toFixed(4);
      return duelReward;
    },

    getIsShown(){
      return this.pvp.duelByAttacker.isPending && this.pvp.decisionTime !== '00:00';
    },

    getTotalWithdrawableSkill(){
      const duelEarnings = new BN(this.pvp.rewards.unclaimedDuelEarningsById).div(new BN(10).pow(18)).toFixed(4);
      const wageredSkill = new BN(this.pvp.wageredSkill).div(new BN(10).pow(18)).toFixed(4);
      const totalWithdrawableSkill = (parseFloat(duelEarnings) + parseFloat(wageredSkill)).toFixed(4);
      return totalWithdrawableSkill;
    },

    getWageredSkill(){
      const wageredSkill = new BN(this.pvp.wageredSkill).div(new BN(10).pow(18)).toFixed(4);
      return wageredSkill;
    },

    getDuelEarnings(){
      // eslint-disable-next-line vue/no-side-effects-in-computed-properties
      this.duelEarnings = new BN(this.pvp.rewards.unclaimedDuelEarningsById).div(new BN(10).pow(18)).toFixed(4);
      return this.duelEarnings;
    },
    getAllUnclaimedDuelEarnings(){
      // eslint-disable-next-line vue/no-side-effects-in-computed-properties
      this.allUnclaimedDuelEarnings = new BN(this.pvp.rewards.allUnclaimedDuelEarnings).div(new BN(10).pow(18)).toFixed(4);
      return this.allUnclaimedDuelEarnings;
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
    ]),

    async goTo(){
      this.setCurrentCharacter(this.currentPvPCharacterId);

      await Promise.all([
        this.$store.dispatch('updatePvPDetails', {characterID: this.currentPvPCharacterId}),
        this.$store.dispatch('fetchArenaPage', {page: '0'})
      ]);
    },

    async findOpponent(characterID){
      await this.$store.dispatch('getOpponent', {characterID});

      this.clearAllTicker();
      this.ticker();
    },

    async reRollOpponent(characterID){
      await this.$store.dispatch('reRollOpponent',{characterID});

      this.clearAllTicker();
      this.ticker();
    },

    async performDuel(characterID){
      this.previousDuelReward = '';
      this.previousDuelReward = this.duelEarnings;
      this.duelResult = await this.$store.dispatch('performDuel',{characterID});
      this.isPerformDuel = true;
      this.isDuelResult = true;
      setTimeout(() => {
        this.isPerformDuel = false;
        this.clearAllTicker();
        this.ticker();
      },6000);
      this.newDuelReward = '';
      this.newDuelReward = this.duelEarnings;
    },

    async withdrawFromArena(characterID){
      const inDuel = this.pvp.duelByAttacker.isPending;

      this.$store.dispatch('withdrawFromArena',{inDuel,characterID});
    },
    async withdrawUnclaimedDuelEarningsByCharacterId(characterID){
      // await this.$store.dispatch('withdrawUnclaimedDuelEarningsById',{ characterID });
    },
    async withdrawAllUnclaimedDuelEarnings(){
      // await this.$store.dispatch('withdrawAllUnclaimedDuelEarnings');
    },
    async getFighter(characterID){
      console.log(await this.$store.dispatch('fetchFighterByCharacterId', { characterID }));
    },

    ticker(){
      window.setInterval(this.getDecisionTime, 1000);
    },

    getDecisionTime(){
      const decisionTimeInterval = (this.pvp.duelByAttacker.createdAt * 1000) + (180000);

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

      if(distance < 0 || !this.pvp.duelByAttacker.isPending){
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
    },

    checkIfWithdrawableAllUnclaimed(){
      if(this.allUnclaimedDuelEarnings !== '0.0000'){
        this.$bvModal.show('withdraw-all-duel-earnings');
      }
      else{
        this.$bvModal.show('withdraw-warning');
      }
    },

    checkIfWithdrawableUnclaimedById(){
      if(this.duelEarnings !== '0.0000'){
        this.$bvModal.show('withdraw-duel-earnings');
      }
      else{
        this.$bvModal.show('withdraw-warning');
      }
    }

  },

  async created(){
    await Promise.all([
      this.$store.dispatch('fetchUnclaimedDuelEarningsById', { characterID: this.currentPvPCharacterId }),
      this.$store.dispatch('fetchAllUnclaimedDuelEarnings')
    ]);
    this.clearAllTicker();
    this.ticker();
  },

  components:{
    'pvp-character': PvPCharacter,
    'pvp-fighter': PvPFighter,
    'pvp-duel': PvPDuel,
    'pvp-divider': PvPDivider,
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

.duel-result-rewards-value {
  font-size: 15px;
  font-weight: bold;
  color: #fff;
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

.total-duel-earnings-container{
  margin: 20px auto;
  height: 25px;
  width: auto;
  cursor: pointer;
}

.total-duel-earnings-container:hover{
  text-shadow: 0 0 10px #fff, 0 0 20px #fff;
  animation: burn 1s 1 forwards;
}

.total-duel-earnings-label{
  font-size: 20px;
  font-weight: bolder;
  color: #968332;
  letter-spacing: 1px;
}

.total-duel-earnings-value{
  font-size: 15px;
  margin-left: 10px;
  margin-right: 10px;
  color: #fff;
}

.duel-earnings-container{
  margin: 20px auto;
  height: 25px;
  width: auto;
  cursor: pointer;
}

.duel-earnings-container:hover{
  text-shadow: 0 0 10px #fff, 0 0 20px #fff;
  animation: burn 1s 1 forwards;
}

.duel-earnings-label{
  font-size: 20px;
  font-weight: bolder;
  color: #968332;
  letter-spacing: 1px;
}

.duel-earnings-value{
  font-size: 15px;
  margin-left: 10px;
  margin-right: 10px;
  color: #fff;
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

.pvp-rewards-container {
  cursor: none;
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
  margin-top: 10px;
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
