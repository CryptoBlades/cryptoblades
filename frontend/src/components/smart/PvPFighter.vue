<template>
  <div class="fighter-container">
      <div class="fighter-inner">
        <div class="fighter-front">
          <char-element
            class="fighter-element"
            v-if="this.show"
            :trait="getCharacterTrait"></char-element>
          <img class="fighter-image" :src="getFighterArt(characterId)"/>
          <div
              v-if="this.show"
              class="fighter-info">
              <div>
              <span class="fighter-name">{{getCharacterName(characterId).toUpperCase()}}</span>
              </div>
              <div>
              <span>Character ID</span>
              <span class="fighter-id">{{characterId}}</span>
              </div>
          </div>
        </div>
        <div class="fighter-back">
          <div
            v-if="this.show"
            class="fighter-header-name">
            <span>{{getCharacterName(characterId).toUpperCase()}}</span>
          </div>
        </div>
      </div>
  </div>
</template>

<script>
import { mapGetters, mapState } from 'vuex';
import { getCharacterArtById } from '../../character-arts-placeholder';
import characterSVG from '../../assets/character.svg';
import CharacterElement from '../smart/Element.vue';

export default {
  props: ['characterId', 'show', 'isAttacker'],

  computed: {
    ...mapState(['pvp']),
    ...mapGetters([
      'inPvPCharacters',
      'getCharacterName']),

    getCharacterTrait(){
      if(this.isAttacker){
        return this.pvp.duelByAttacker.attackerTrait;
      }
      else{
        return this.pvp.duelByAttacker.defenderTrait;
      }
    }
  },

  methods:{
    getCharacterArtById,

    getFighterArt(characterId){
      if (this.show){
        return getCharacterArtById(characterId);
      }
      return characterSVG;
    },
  },

  components: {
    'char-element': CharacterElement,
  }
};
</script>

<style>
.fighter-container {
  margin: auto;
  height: 450px;
  width: 300px;
  perspective: 1000px;
}

.fighter-inner {
  position: relative;
  width: 100%;
  height: 100%;
  text-align: center;
  transition: transform 0.4s;
  transform-style: preserve-3d;
  box-shadow: 0 4px 20px rgba(255, 255, 255, 0.2);
}

.fighter-container:hover .fighter-inner {
  transform: rotateY(180deg);
}

.fighter-front, .fighter-back {
  position: absolute;
  width: 100%;
  height: 100%;
  -webkit-backface-visibility: hidden;
  backface-visibility: hidden;
  border: 2px solid #968332;
  background-color: transparent;
}

.fighter-front {
  background-image: url('../../assets/cardCharacterFrame.png');
  background-repeat: no-repeat;
  background-size: cover;
  background-position: center;
}

.fighter-image {
  margin: 20px auto;
  height: 250px;
  width: 125px;
}

.fighter-element {
  margin-top: 20px;
}

.fighter-name {
  text-align: left;
  color: white;
  font-weight: bold;
  font-size: 16px;
}

.fighter-id {
  margin-left: 10px;
  text-align: left;
  color: white;
  font-weight: bold;
  font-size: 16px;
}

.fighter-header-name {
  margin: 20px auto;
  color: white;
  font-weight: bold;
  font-size: 20px;
}

.fighter-back {
  color: white;
  transform: rotateY(180deg);
}

</style>
