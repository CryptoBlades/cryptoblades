<template>
  <b-row class="pvp-content">
        <b-col id="arsenal-preparation-content">

            <pvp-divider>
            </pvp-divider>

            <b-row id="slider-buttons">
              <b-col
                  v-for="character in ownCharacters"
                  :key="character.id">
                <pvp-character
                  :character="character"
                  :currentCharacterId="currentCharacterId"
                  :inPvP="true"></pvp-character>
              </b-col>
            </b-row>
          <b-row id="slider-content">
              <b-col>
                <b-row class="equipped-weapon-container">
                  <b-col>
                    <div id="equipped-weapon-header">
                         SWORD
                         <Hint text="Placeholder for weapon hint text"/>
                    </div>
                  </b-col>
                </b-row>
                <b-row class="equipped-weapon-container">
                  <b-col>
                    <div
                        id="equipped-weapon"
                        @click="setCurrentTab(0); hideShieldInventory();">
                      <div
                        class="equipped-weapon-content">
                        <pvp-weapon
                          v-if="this.ownWeapons.length !== 0"
                          :weapon="currentWeapon"
                          :currentWeaponId="currentWeaponId"
                          :inPvP="false"
                          :isEquipContainer="true"></pvp-weapon>
                      </div>
                    </div>
                    <div class="equipped-weapon-content no-equip"
                        v-if="this.ownWeapons.length <=0">
                        No Weapon Detected
                      </div>
                  </b-col>
                </b-row>
                <b-row id="equipped-shield-container">
                  <b-col>
                    <div id="equipped-shield-header">
                         SHIELD
                         <Hint text="Placeholder for shield hint text"/>
                    </div>
                  </b-col>
                </b-row>
                <b-row id="equipped-shield-container">
                  <b-col>
                    <div
                        id="equipped-shield"
                        @click="setCurrentTab(1); hideWeaponInventory();">
                      <div
                        v-if="this.ownShields.length !== 0"
                        class="equipped-shield-content">
                        <pvp-shield
                          :shield="currentShield"
                          :currentShieldId="currentShield.id"
                          :inPvP="false"
                          :isEquipContainer="true"></pvp-shield>
                      </div>
                    </div>
                    <div class="equipped-shield-content no-equip"
                        v-if="this.ownShields.length <=0">
                        No Shield Detected
                    </div>
                  </b-col>
                </b-row>
              </b-col>
              <b-col>
                <b-carousel
                    :interval="sliding"
                    no-wrap
                    >
                  <b-carousel-slide
                        v-for="character in ownCharacters"
                        :key="character.id">
                    <template #img>
                      <img
                        id="character-image"
                        :src="getCharacterArt(currentCharacter)"/>
                    </template>
                  </b-carousel-slide>
                </b-carousel>
              </b-col>
              <b-col>
                <b-row id="character-name">
                  <b-col>
                    <div class="character-info-container">
                      <span v-text="getCharacterName(currentCharacterId)" />
                      <char-element
                      :trait="currentCharacter.trait"></char-element>
                    </div>
                    <div class="character-info-container">
                      <span id="character-level-label"> Level </span>
                      <span id="character-level-value" v-text="currentCharacter.level + 1" />
                    </div>
                    <div class="character-info-container">
                      <pvp-arena-details></pvp-arena-details>
                    </div>
                  </b-col>
                </b-row>
              </b-col>
          </b-row>
        </b-col>

          <b-popover :show.sync="showWeaponInventory" :custom-class="`${getPopoverClass(0)}`" target="equipped-weapon" triggers="click" placement="right">
              <pvp-inventory></pvp-inventory>
          </b-popover>

          <b-popover :show.sync="showShieldInventory" :custom-class="`${getPopoverClass(1)}`" target="equipped-shield" triggers="click" placement="right">
              <pvp-inventory></pvp-inventory>
          </b-popover>
  </b-row>
</template>

<script>
import { getCharacterArt } from '../../character-arts-placeholder';
import { getWeaponArt } from '../../weapon-arts-placeholder';
import Hint from '../Hint.vue';
import Element from '../smart/Element.vue';
import { mapGetters, mapMutations, mapState } from 'vuex';
import foundersShield from '../../assets/shield1.png';
import legendaryShield from '../../assets/shield2.png';
import PvPArenaDetails from '../smart/PvPArenaDetails.vue';
import PvPInventory from './PvPInventory.vue';
import PvPCharacter from './PvPCharacter.vue';
import PvPDivider from './PvPDivider.vue';
import PvPWeapon from './PvPWeapon.vue';
import PvPShield from './PvPShield.vue';


export default {
  data(){
    return {
      sliding: 0,
      showWeaponInventory: false,
      showShieldInventory: false,
    };
  },

  computed: {
    ...mapState(['currentCharacterId','currentWeaponId']),
    ...mapGetters([
      'currentWeapon',
      'currentCharacter',
      'currentShield',
      'ownCharacters',
      'ownWeapons',
      'ownShields',
      'getCharacterName',
      'getWeaponName',
      'getCurrentTab'
    ]),

  },

  methods:{
    ...mapMutations([
      'setCurrentCharacter',
      'setCurrentTab',
      'setCurrentShield',
      'setCurrentWeapon'
    ]),

    getCharacterArt,

    getWeaponArt,

    hideWeaponInventory(){
      this.showWeaponInventory = false;
    },

    hideShieldInventory(){
      this.showShieldInventory = false;
    },

    getShieldArt(shieldId) {
      if(shieldId <= 10000){
        return foundersShield;
      }
      else if (shieldId > 10000 || shieldId <= 25000){
        return legendaryShield;
      }
      else{
        return '';
      }
    },

    getPopoverClass(nftType){
      if (this.ownWeapons.length > 1 && nftType === 0) {
        return 'equipped-container-multiple';
      }
      else if (this.ownWeapons.length === 1) {
        return 'equipped-container';
      }

      if (this.ownShields.length > 1 && nftType === 1) {
        return 'equipped-container-multiple';
      }
      else if (this.ownShields.length === 1) {
        return 'equipped-container';
      }
    },

  },

  created(){
    if(this.ownShields.length > 0){
      this.setCurrentShield(this.ownShields[0].id);
    }
    this.setCurrentWeapon(this.ownWeapons[0].id);
    this.setCurrentCharacter(this.ownCharacters[0].id);
    this.$store.dispatch('fetchParticipatingCharacters');
    this.$store.dispatch('fetchParticipatingWeapons');
    this.$store.dispatch('fetchParticipatingShields');
    this.$store.dispatch('fetchIsCharacterInArena',{character: this.ownCharacters[0].id});
    this.$store.dispatch('fetchEntryWager',{characterID: this.ownCharacters[0].id});
    this.$store.dispatch('fetchWageredSkill',{characterID: this.ownCharacters[0].id});
    this.$store.dispatch('fetchDuelCost',{characterID: this.ownCharacters[0].id});
  },

  components: {
    Hint,
    'char-element': Element,
    'pvp-arena-details': PvPArenaDetails,
    'pvp-inventory': PvPInventory,
    'pvp-character': PvPCharacter,
    'pvp-divider': PvPDivider,
    'pvp-weapon': PvPWeapon,
    'pvp-shield': PvPShield
  },
};
</script>

<style>

.equipped-container {
  height: auto;
  background-color: transparent;
  box-shadow: 0 0 10px #fff
}

.equipped-container-multiple {
  height: 300px;
  background-color: transparent;
  overflow-y: scroll;
  overflow-x: hidden;
  box-shadow: 0 0 10px #fff
}

#equipped-weapon {
  cursor: pointer;
}

#equipped-shield {
  cursor: pointer;
}

.no-equip {
  cursor: not-allowed;
}

/* PvP Popover Styles */
.popover-body {
  background-color: black;
}
/* PvP Popover Styles */

/* PvP Content Styles */
.pvp-content {
  text-align:center;
  margin-bottom: 50px;
  margin-top: 10px;
}


/* PvP Character Styles */

#slider-buttons {
  border-bottom: 2px solid #968332;
  margin-bottom: 50px;
  padding-bottom: 40px;
}

#character-image {
  height:300px;
  width: 160px;
}

#character-info-container {
  margin:auto;
}

#character-name {
  text-align: left;
  color: white;
  font-weight: bold;
  font-size: 16px;
}

#character-level-label {
  font-size: 12px;
  color: #968332;
}

#character-level-value {
  font-size: 12px;
  color: white;
}

.equipped-weapon-container {
  margin-top: 10px;
  margin-bottom: 10px;
}

#equipped-weapon-header {
  text-align: left;
  font-weight: bold;
  width: 80px;
  margin:auto;
}

.equipped-weapon-content {
  background: transparent;
  border: 4px solid #968332;
  border-radius: 10%;
  height: 80px;
  width: 80px;
  margin: 3px auto;
}

#equipped-shield-container {
  margin-top: 10px;
  margin-bottom: 10px;
}

#equipped-shield-header {
  text-align: left;
  font-weight: bold;
  width: 80px;
  margin:auto;
}

.equipped-shield-content {
  border: 4px solid #968332;
  border-radius: 10%;
  height: 80px;
  width: 80px;
  margin: 3px auto;
}

/* PvP Character Styles */


/* PvP Content Styles */
</style>
