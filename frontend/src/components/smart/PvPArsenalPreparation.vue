<template>
  <b-row class="pvp-content">
        <b-col id="arsenal-preparation-content" cols="5">
            <b-row id="slider-buttons">
              <b-col
                  v-for="character in ownCharacters"
                  :key="character.id">
                  <div
                      :class="`${setListClassForChar(character.id,currentCharacterId)}`"
                      @click="setCurrentCharacter(character.id)">
                    <div>
                      <img
                        class="character-buttons"
                        :src="getCharacterArt(character)" />
                    </div>
                  </div>
              </b-col>
            </b-row>
          <b-row id="slider-content">
              <b-col>
                <b-row id="equipped-weapon-container">
                  <b-col>
                    <div id="equipped-weapon-header">
                         WEAPON
                         <Hint text="Placeholder for weapon hint text"/>
                    </div>
                  </b-col>
                </b-row>
                <b-row id="equipped-weapon-container">
                  <b-col>
                    <div>
                      <img
                        id="equipped-weapon-content"
                        :src="getWeaponArt(currentWeapon)"
                        />
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
                    <div id="equipped-shield-content">
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
                    </div>
                    <div class="character-info-container">
                      <span id="character-level-label"> Level </span>
                      <span id="character-level-value" v-text="currentCharacter.level + 1" />
                    </div>
                  </b-col>
                  <b-col cols="1">
                    <char-element
                      :trait="currentCharacter.trait"></char-element>
                  </b-col>
                </b-row>
              </b-col>
          </b-row>
        </b-col>
        <b-col id="find-opponent-divider">
        </b-col>
        <b-col id= "find-opponent-content" cols="2">
        </b-col>
        <b-col id="inventory-content" cols="5">

          <b-row class="inventory-pseudo-tabs">
            <b-col
              class="inventory-tab-button-container"
              v-for="inventoryTab in inventoryTabNames"
              :key="inventoryTab.id">
              <button
                class="inventory-tab-button"
                v-text="inventoryTab.name"
                @click="setCurrentTab(inventoryTab.id)"></button>
            </b-col>
          </b-row>
          <b-row class="inventory-weapon-container"
              v-if="getCurrentTab === 0">
              <b-col>
                <b-row>
                  <b-col
                    v-for="weapon in ownWeapons"
                    :key="weapon.id">
                    <div
                      :class="`${setListClassForWeapon(weapon.id,currentWeaponId)}`"
                      @click="setCurrentWeapon(weapon.id)">
                      <div>
                        <img
                          class="inventory-weapon-content"
                          :src="getWeaponArt(weapon)"/>
                      </div>
                    </div>
                  </b-col>
                </b-row>
              </b-col>
          </b-row>
          <b-row class="inventory-shield-container"
              v-if="getCurrentTab === 1">
              Shield NFTs
          </b-row>
        </b-col>
  </b-row>
</template>

<script>
import { getCharacterArt } from '../../character-arts-placeholder';
import { getWeaponArt } from '../../weapon-arts-placeholder';
import Hint from '../Hint.vue';
import Element from '../smart/Element.vue';
import { mapGetters, mapMutations, mapState } from 'vuex';

export default {
  data(){
    return {
      sliding: 0,
    };
  },

  computed: {
    ...mapState(['currentCharacterId','currentWeaponId']),
    ...mapGetters([
      'currentWeapon',
      'getInventoryState',
      'currentCharacter',
      'ownCharacters',
      'ownWeapons',
      'getCharacterName',
      'getWeaponName',
      'getCurrentTab'
    ]),

    inventoryTabNames(){
      return this.getInventoryState;
    },
  },

  methods:{
    ...mapMutations([
      'setCurrentCharacter',
      'setCurrentWeapon',
      'setCurrentTab'
    ]),

    getCharacterArt,

    getWeaponArt,

    setListClassForChar(characterId,currentCharacterId){
      if (characterId === currentCharacterId){
        return 'active-indicator';
      }

      else return 'inactive-indicator';
    },

    setListClassForWeapon(weaponId,currentWeaponId){
      if (weaponId === currentWeaponId){
        return 'selected-weapon';
      }

      else return 'unselected-weapon';
    },

    created(){
      this.setCurrentWeapon(this.ownWeapons[0].id);
    },


  },

  components: {
    Hint,
    'char-element': Element,
  },
};
</script>

<style>
/* PvP Content Styles */
.pvp-content {
  text-align:center;
  margin-bottom: 50px;
  margin-top: 10px;
}

#find-opponent-divider {
  border-left: 1px solid #968332;
  border-width: thin;
  height: 400px;
  width: 1px;
  position: absolute;
  left: 50%;
  margin-left: -3px;
}


/* PvP Character Styles */

#slider-buttons {
  border-bottom: 2px solid #968332;
  margin-bottom: 50px;
  padding-bottom: 20px;
}

.character-buttons {
  background: transparent;
  border: 2px solid #968332;
  border-radius: 10%;
  height: 80px;
  width: 80px;
  margin: 3px auto;
  overflow: hidden;
}

.active-indicator {
  border: 1px dashed #968332;
  border-radius: 10%;
  background:transparent;
  margin: 3px auto;
  height:90px;
  width: 90px;
}


.inactive-indicator {
  border: 1px none transparent;
  border-radius: 10%;
  margin: 3px auto;
  height:90px;
  width: 90px;
}

#character-image {
  height:300px;
  width: 160px;
}

#character-info-container {
  margin:auto;
}

#character-name {
  text-align: right;
  color: white;
  font-weight: bolder;
  font-size: 16px;
}

#character-level-label {
  text-align: right;
  font-size: 12px;
  color: #968332;
}

#character-level-value {
  text-align: right;
  font-size: 12px;
  color: white;
}

#equipped-weapon-container {
  margin-top: 10px;
  margin-bottom: 10px;
}

#equipped-weapon-header {
  text-align: left;
  font-weight: bold;
  width: 80px;
  margin:auto;
}

#equipped-weapon-content {
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

#equipped-shield-content {
  background: antiquewhite;
  background-image: url("https://seiyria.com/gameicons-font/svg/shield.svg");
  border: 4px solid #968332;
  border-radius: 10%;
  height: 80px;
  width: 80px;
  margin: 3px auto;
}

/* PvP Character Styles */

/* PvP Inventory Styles */

.inventory-pseudo-tabs {
  margin: 10px auto;
}

.inventory-tab-button {
  border: 1px solid #968332;
  border-radius: 2%;
  background: #32343C;
  color: #968332;
  width: 100%;
  margin: auto;
}

.inventory-weapon-container {
  margin-top: 50px;
}

.selected-weapon {
  background: transparent;
  border: 1px dashed #968332;
  border-radius: 10%;
  height: 60px;
  width: 60px;
  margin: 10px auto;
}

.unselected-weapon {
  background: transparent;
  border: 1px none transparent;
  border-radius: 10%;
  height: 60px;
  width: 60px;
  margin: 10px auto;
}

.inventory-weapon-content {
  background: transparent;
  border: 2px solid #968332;
  border-radius: 10%;
  height: 50px;
  width: 50px;
  margin: 3px auto;
}

#inventory-weapon-content-dashed {
  background: transparent;
  border: 1px dashed #968332;
  border-radius: 10%;
  height: 50px;
  width: 50px;
  margin: 10px auto;
}


/* PvP Inventory Styles */

/* PvP Content Styles */
</style>
