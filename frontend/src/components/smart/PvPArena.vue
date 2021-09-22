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
            v-if="!this.pvp.duelByAttacker.isPending"
            class="find-opponent-container"
            @click="findOpponent(currentPvPCharacterId)">
              <img id="find-opponent-img" src="../../assets/winged-shield.svg"/>
          </div>
          <div
            v-if="this.pvp.duelByAttacker.isPending"
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
                @click="withdrawFromArena(currentPvPCharacterId)">
                <img
                  id="withdraw-img"
                  src="../../assets/run.svg"/>WITHDRAW</span>
          </div>
          <div
            v-if="this.pvp.duelByAttacker.isPending"
            class="reroll-container">
              <span
                @click="reRollOpponent(currentPvPCharacterId)">
                <img
                  id="reroll-img"
                  src="../../assets/rolling-dices.svg"/>REROLL</span>
          </div>
        </b-row>
      </b-col>

      <b-col>
        <b-row>
        <pvp-fighter
          :characterId="this.pvp.duelByAttacker.defenderId"
          :show="this.pvp.duelByAttacker.isPending"
          :isAttacker="false"></pvp-fighter>
        </b-row>
      </b-col>
    </b-row>

    <b-row
      v-if="isDuelResult">
      <div class="duel-result-container">
        <div class="duel-result">
         <p
          class="duel-result-text"
          v-if="duelResult.attackerWon">YOU WIN</p>
         <p
          class="duel-result-text"
          v-if="!duelResult.attackerWon">YOU LOST</p>
          <span
          class="duel-result-roll-label">You rolled</span>
         <span
          class="duel-result-roll-value"
          v-text="duelResult.attackerRoll"/><br>
          <span
          class="duel-result-roll-label">Enemy rolled</span>
         <span
          class="duel-result-roll-value"
          v-text="duelResult.defenderRoll"/><br>
        <div
          class="duel-result-ok-button">
         <span
            @click="isDuelResult = !isDuelResult">OK</span>
        </div>
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

  </div>
</template>

<script>
import { mapGetters, mapMutations, mapState } from 'vuex';
import PvPCharacter from './PvPCharacter.vue';
import PvPFighter from './PvPFighter.vue';
import PvPDuel from './PvPDuel.vue';
import PvPDivider from './PvPDivider.vue';

export default {

  data(){
    return{
      isPerformDuel: false,
      isDuelResult: false,
      duelResult: null,
    };
  },

  computed:{
    ...mapState(['pvp']),
    ...mapGetters([
      'inPvPCharacters',
      'currentPvPCharacterId'
    ]),

  },

  methods:{
    ...mapMutations(['setCurrentPvPCharacter']),

    goTo(){
      this.$store.dispatch('fetchArenaPage', {page: '0'});
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
      this.clearAllTicker();
      this.duelResult = await this.$store.dispatch('performDuel',{characterID});
      this.isPerformDuel = true;
      this.isDuelResult = true;
      setTimeout(() => {
        this.isPerformDuel = false;
      },6000);
    },

    async withdrawFromArena(characterID){
      const inDuel = this.pvp.duelByAttacker.isPending;

      this.$store.dispatch('withdrawFromArena',{inDuel,characterID});
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

  },

  async created(){
    this.setCurrentPvPCharacter(this.currentPvPCharacterId);
    await this.$store.dispatch('getDuelByAttacker',{characterID: this.currentPvPCharacterId});
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
  filter: drop-shadow( 0px 0px 10px #fff);
}

.duel-result {
  position: relative;
  top: 50px;
  text-align: center;
}

.duel-result-ok-button {
  font-weight: bold;
  font-size: 20px;
  margin: 90px auto;
  height: 30px;
  width: 100px;
  box-shadow: -10px 10px 20px #000;
  color: #fff;
}

.duel-result-ok-button:hover {
  cursor: pointer;
}

.duel-result-text {
  font-size: 30px;
  font-weight: bold;
  font-family: initial;
  letter-spacing: 10px;
  color: #000;
}

.duel-result-roll-label {
  margin-right: 10px;
  font-size: 20px;
  font-weight: bold;
  color: #000;
}

.duel-result-roll-value {
  font-size: 15px;
  letter-spacing: 1px;
  font-weight: bold;
  color: #fff;
}

@keyframes burn {
  from {
    filter: drop-shadow( 0px 0px 0px #968332);
  }
  to {
    filter: drop-shadow( 0px 0px 50px #fff);
  }
}

</style>
