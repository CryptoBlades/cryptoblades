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
import Element from './Element.vue';

export default {
  props: ['character','currentCharacterId','inPvP'],

  computed: {
    ...mapState(['pvp']),
    ...mapGetters(['getCharacterName'])
  },

  methods: {
    ...mapMutations([
      'setCurrentCharacter',
      'setCurrentPvPCharacter',
      'setCurrentWeapon',
      'setCurrentShield',
      'updateIsWeaponInArena',
      'updateIsShieldInArena'
    ]),

    getCharacterHeadArt,

    setListClassForChar(characterId,currentCharacterId){
      if (characterId.toString() === currentCharacterId.toString()){
        return 'active-indicator';
      }
      else return 'inactive-indicator';
    },

    async updateCharacterDetails(characterID){
      if(this.inPvP){
        this.setCurrentCharacter(characterID);
        await this.$store.dispatch('updatePvPDetails', { characterID });
      }else{
        this.setCurrentPvPCharacter(characterID);
        await this.$store.dispatch('updatePvPDetails', { characterID });
      }

      this.setCurrentWeapon(null);
      this.updateIsWeaponInArena({isWeaponInArena: true});
      this.setCurrentShield(null);
      this.updateIsShieldInArena({isShieldInArena: false});

      await Promise.all([
        this.$store.dispatch('fetchIsCharacterInArena', { characterID }),
        this.$store.dispatch('fetchEntryWager',{ characterID }),
        this.$store.dispatch('fetchPvPTraitBonusAgainst',{
          characterTrait: this.pvp.attackerFighter.characterTrait,
          weaponTrait: this.getWeaponElementNum(this.pvp.attackerFighter.weapon.element),
          opponentTrait: this.pvp.defenderFighter.characterTrait
        })
      ]);


      this.clearAllTicker();
      this.ticker();
    },

    setCharacterPvPStatus(characterID){
      this.$store.dispatch('updatePvPDetails', { characterID });

      if(this.pvp.participatingCharacters.includes(characterID.toString())){
        return 'character-in-pvp';
      }
      else return 'character-not-in-pvp';

    },
    ticker(){
      window.setInterval(this.getDecisionTime, 1000);
    },

    getDecisionTime(){
      const decisionTimeInterval = (this.pvp.duelByAttacker.createdAt * 1000);

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
    getWeaponElementNum(weaponElement){
      if(weaponElement.toUpperCase() === 'FIRE'){
        return '0';
      }
      else if (weaponElement.toUpperCase() === 'EARTH'){
        return '1';
      }
      else if (weaponElement.toUpperCase() === 'LIGHTNING'){
        return '2';
      }
      else if (weaponElement.toUpperCase() === 'WATER'){
        return '3';
      }
    }
  },

  async created(){
    if(this.inPvP){
      this.setCurrentCharacter(this.currentCharacterId);
      await this.$store.dispatch('updatePvPDetails', { characterID: this.currentCharacterId });
    }else{
      this.setCurrentPvPCharacter(this.currentCharacterId);
      await this.$store.dispatch('updatePvPDetails', { characterID: this.currentCharacterId });
    }

    this.setCurrentWeapon(null);
    this.updateIsWeaponInArena({isWeaponInArena: true});
    this.setCurrentShield(null);
    this.updateIsShieldInArena({isShieldInArena: false});

    await Promise.all([
      this.$store.dispatch('fetchIsCharacterInArena', { characterID: this.currentCharacterId }),
      this.$store.dispatch('fetchEntryWager',{ characterID: this.currentCharacterId }),
      this.$store.dispatch('fetchPvPTraitBonusAgainst',{
        characterTrait: this.pvp.attackerFighter.characterTrait,
        weaponTrait: this.getWeaponElementNum(this.pvp.attackerFighter.weapon.element),
        opponentTrait: this.pvp.defenderFighter.characterTrait
      })
    ]);

    this.clearAllTicker();
    this.ticker();
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
    top: 20%;
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

#character-name {
  text-align: left;
  color: white;
  font-weight: bold;
  font-size: 16px;
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
  top: 55px;
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
