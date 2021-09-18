<template>
  <div>
    <button @click="goTo">----Arsenal Preparation</button>
    {{this.pvp}}
    <button @click="findOpponent(currentPvPCharacterId)">Find Opponent</button>

    <button @click="reRollOpponent(currentPvPCharacterId)">Reroll Opponent</button>

    <button @click="performDuel(currentPvPCharacterId)">Perform Duel</button>

    <button @click="withdrawFromArena(currentPvPCharacterId)"> Withdraw From Arena</button>

    <b-row id="arena-character-buttons">
      <b-col
        v-for="character in inPvPCharacters"
        :key="character.id">
      <character-button
              :character="character"
              :currentCharacterId="currentPvPCharacterId"
              :inPvP="false"></character-button>
      </b-col>
      </b-row>
  </div>
</template>

<script>
import { mapGetters, mapMutations, mapState } from 'vuex';
import CharacterButton from '../smart/CharacterButton.vue';

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
      this.$store.dispatch('getOpponent', {characterID});
    },

    async reRollOpponent(characterID){
      this.$store.dispatch('reRollOpponent',{characterID});
    },

    async performDuel(characterID){
      console.log(await this.$store.dispatch('performDuel',{characterID}));
    },

    async withdrawFromArena(characterID){
      this.$store.dispatch('withdrawFromArena',{characterID});
    }

  },

  created(){
    this.setCurrentPvPCharacter(this.pvp.participatingCharacters[0]);
  },

  components:{
    'character-button': CharacterButton,
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
</style>
