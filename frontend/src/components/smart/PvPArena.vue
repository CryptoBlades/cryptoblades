<template>
  <div>

    <button @click="goTo">----Arsenal Preparation</button>

    <b-row id="arena-character-buttons">
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
      <div class="timer-container">
        <span id="timer" v-text="this.pvp.decisionTime"/>
      </div>
    </b-row>

    <b-row>
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

    <b-row class="arena-footer">
    </b-row>


  </div>
</template>

<script>
import { mapGetters, mapMutations, mapState } from 'vuex';
import PvPCharacter from './PvPCharacter.vue';
import PvPFighter from './PvPFighter.vue';

export default {

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
      console.log(await this.$store.dispatch('performDuel',{characterID}));
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
    this.setCurrentPvPCharacter(this.pvp.participatingCharacters[0]);
    await this.$store.dispatch('getDuelByAttacker',{characterID: this.currentPvPCharacterId});
    this.clearAllTicker();
    this.ticker();
  },

  components:{
    'pvp-character': PvPCharacter,
    'pvp-fighter': PvPFighter
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

@keyframes burn {
  from {
    filter: drop-shadow( 0px 0px 0px #968332);
  }
  to {
    filter: drop-shadow( 0px 0px 50px #fff);
  }
}

</style>
