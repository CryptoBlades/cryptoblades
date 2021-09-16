<template>
  <div>
    <button @click="goTo">----Arsenal Preparation</button>
    {{this.pvp}}
    <button @click="findOpponent('0')">Find Opponent</button>

    <button @click="reRollOpponent('0')">Reroll Opponent</button>

    <button @click="performDuel('0')">Perform Duel</button>

    <button @click="withdrawFromArena('0')"> Withdraw From Arena</button>
  </div>
</template>

<script>
import { mapState } from 'vuex';
export default {

  computed:{
    ...mapState(['pvp']),
  },

  methods:{

    goTo(){
      this.$store.dispatch('fetchArenaPage', {page: '0'});
    },

    async findOpponent(characterID){
      this.$store.dispatch('getOpponent', {characterID});
      const defenderID = await this.$store.dispatch('getDefenderID', {characterID});

      console.log(defenderID);
    },

    async reRollOpponent(characterID){
      this.$store.dispatch('reRollOpponent',{characterID});
      const defenderID = await this.$store.dispatch('getDefenderID', {characterID});

      console.log(defenderID);
    },

    async performDuel(characterID){
      this.$store.dispatch('performDuel',{characterID});
    },

    async withdrawFromArena(characterID){
      this.$store.dispatch('withdrawFromArena',{characterID});
      this.$store.dispatch('fetchParticipatingCharacters');
    }

  },

};
</script>
