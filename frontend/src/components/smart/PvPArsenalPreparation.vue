<template>
  <b-row class="pvp-content">
        <b-col id="arsenal-preparation-content" cols="5">
            <b-row id="slider-buttons">
              <b-col
                  v-for="character in getCharacterList()"
                  :key="character.id">
                  <div class="active-indicator">
                    <div class="character-buttons">
                    </div>
                  </div>
              </b-col>
            </b-row>
          <b-row id="slider-content">
              <b-col cols="4">
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
                    <div id="equipped-weapon-content">
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
              <b-col cols="4">
                <b-carousel
                    controls>
                  <b-carousel-slide
                        v-for="character in getCharacterList()"
                        :key="character.id">
                    <template #img>
                      <img
                        id="character-image"
                        :src="character.img">
                    </template>
                  </b-carousel-slide>
                </b-carousel>
              </b-col>
              <b-col cols="4">
                <b-row id="character-name">
                  <b-col>
                    <div class="character-info-container">
                      Ankitarla Kathassily
                    </div>
                    <div class="character-info-container">
                      <span id="character-level-label"> Level </span>
                      <span id="character-level-value"> 28 </span>
                    </div>
                  </b-col>
                  <b-col cols="1">
                    <char-element
                      :nftId="getCharacterElement"
                      :type="weapon_nft"></char-element>
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
              v-for="inventoryTabs in inventoryTabNames"
              :key="inventoryTabs.id">
              <button
                class="inventory-tab-button"
                v-text="inventoryTabs.value"></button>
            </b-col>
          </b-row>
          <b-row class="inventory-weapon-container"
            v-for="inventoryRows in numberOfRows"
            :key="inventoryRows">
              <b-col>
                <b-row>
                  <b-col>
                    <div id="inventory-weapon-content">
                    </div>
                  </b-col>
                </b-row>
              </b-col>
          </b-row>
          <b-row class="inventory-weapon-container">
              <b-col>
                <b-row>
                  <b-col>
                    <div id="inventory-weapon-content-dashed">
                    </div>
                  </b-col>
                </b-row>
              </b-col>
          </b-row>
        </b-col>
  </b-row>
</template>

<script>

import PvPConstants from '../../utils/constants/pvp-constants';
import character from '../../assets/placeholder/chara-0.png';
import Hint from '../Hint.vue';
import Element from '../smart/Element.vue';

export default {
  data(){
    return {
      character_nft: PvPConstants.CHARACTER_NFT,
      weapon_nft: PvPConstants.WEAPON_NFT,
      shield_nft: PvPConstants.SHIELD_NFT,
    };
  },
  methods:{
    getCharacterList(){
      const characters = [
        {id: '0', name: 'Tirasthu Lithuir', img: character},
        {id: '1', name: 'Voir Ghuru', img: character},
        {id: '2', name: 'Voir Ghuru', img: character},
        {id: '3', name: 'Voir Ghuru', img: character},
      ];

      return characters;
    },
  },

  computed: {
    numberOfRows() {
      const checkExcessRow = PvPConstants.NUMBER_OF_SWORDS%8;
      let rowCount = (PvPConstants.NUMBER_OF_SWORDS/8);
      if (checkExcessRow > 0){
        return rowCount = Math.floor(rowCount)+1;
      }
      else{
        return rowCount;
      }
    },
    numberOfWeapons(){
      return PvPConstants.NUMBER_OF_SWORDS;
    },
    inventoryTabNames(){
      return PvPConstants.INVENTORY_TAB_NAMES;
    },
    getCharacterElement(){
      return 0;
    }
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

.pvp-divider-header-line {
  border-top: 1px solid #968332;
  height: 1px;
  margin-top: 12px;
}

#slider-buttons {
  border-bottom: 2px solid #968332;
  margin-bottom: 50px;
  padding-bottom: 20px;
}

.character-buttons {
  background: antiquewhite;
  background-image: url("https://seiyria.com/gameicons-font/svg/character.svg");
  border: 2px solid #968332;
  border-radius: 10%;
  height: 80px;
  width: 80px;
  margin: 3px auto;
}

.active-indicator {
  border: 1px dashed #968332;
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
  background: antiquewhite;
  background-image: url("https://seiyria.com/gameicons-font/svg/broadsword.svg");
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

#inventory-weapon-content {
  background: antiquewhite;
  background-image: url("https://seiyria.com/gameicons-font/svg/broadsword.svg");
  border: 4px solid #968332;
  border-radius: 10%;
  height: 50px;
  width: 50px;
  margin: 10px auto;
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
