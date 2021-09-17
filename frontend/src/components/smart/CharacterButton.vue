<template>
  <div>
      <div
        :class="`${setListClassForChar(character.id,currentCharacterId)}`"
        @click="updateCharacterDetails(character.id)">
        <div class="character-head-container">
            <span v-if="inPvP" :class="`${setCharacterPvPStatus(character.id)}`"></span>
                <img
                  class="character-buttons"
                  :src="getCharacterHeadArt(character)"/>
                    <span id="character-head-level-label"> Level </span>
                    <span id="character-head-level-value" v-text="character.level + 1" />
                    <char-element id="character-head-element" :trait="character.trait"></char-element>
          </div>
      </div>
      <span id="character-name"
            v-text="getCharacterName(character.id)"></span><br>
  </div>
</template>

<script>
import { mapState, mapGetters, mapMutations } from 'vuex';
import { getCharacterHeadArt } from '../../character-arts-placeholder';
import Element from '../smart/Element.vue';

export default {
  props: ['character','currentCharacterId','inPvP'],

  computed: {
    ...mapState(['pvp']),
    ...mapGetters(['getCharacterName'])
  },

  methods: {
    ...mapMutations([
      'setCurrentCharacter',
      'setCurrentPvPCharacter']),

    getCharacterHeadArt,

    setListClassForChar(characterId,currentCharacterId){
      if (characterId.toString() === currentCharacterId.toString()){
        return 'active-indicator';
      }
      else return 'inactive-indicator';
    },

    updateCharacterDetails(characterID){
      if(this.inPvP){
        this.setCurrentCharacter(characterID);
      }else{
        this.setCurrentPvPCharacter(characterID);
      }

      this.$store.dispatch('fetchEntryWager',{characterID});
      this.$store.dispatch('fetchWageredSkill',{characterID});
      this.$store.dispatch('fetchDuelCost',{characterID});
      this.$store.dispatch('fetchIsCharacterInArena',{characterID});
    },

    setCharacterPvPStatus(characterID){
      this.$store.dispatch('fetchParticipatingCharacters');

      if(this.pvp.participatingCharacters.includes(characterID.toString())){
        return 'character-in-pvp';
      }
      else return 'character-not-in-pvp';

    },

  },

  created(){
    if(this.inPvP){
      this.setCurrentCharacter(this.currentCharacterId);
    }else{
      this.setCurrentPvPCharacter(this.currentCharacterId);
    }
  },

  components:{
    'char-element': Element,
  }

};
</script>

<style>

/* PvP Status Styles */
.character-in-pvp {
    color: white;
    height: 20px;
    width: 80px;
    background-color: rgb(187, 33, 0);
    border-radius: 10%;
    transform: rotate(30deg);
    position: absolute;
    left: 38%;
    top: 20%;
    z-index: 100;
}

.character-in-pvp::before {
  content: "IN PVP";
}
/* PvP Status Styles */

.character-buttons {
  background: transparent;
  border: 2px solid #968332;
  border-radius: 10%;
  height: 80px;
  width: 80px;
  margin: 3px auto;
  overflow: hidden;
}

#character-head-level-label {
  text-align: left;
  font-size: 9px;
  color: #968332;
}

#character-head-level-value {
  text-align: left;
  font-size: 9px;
  color: white;
}

#character-head-element {
  position: absolute;
  top: 38%;
  left: 53%;
}

.active-indicator {
  border: 1px dashed #968332;
  border-radius: 10%;
  background:transparent;
  margin: 3px auto;
  height:auto;
  width: 90px;
}

.active-indicator:hover {
  cursor: pointer;
}


.inactive-indicator {
  border: 1px none transparent;
  border-radius: 10%;
  margin: 3px auto;
  height:auto;
  width: 90px;
}

.inactive-indicator:hover {
  cursor:pointer;
}

</style>
