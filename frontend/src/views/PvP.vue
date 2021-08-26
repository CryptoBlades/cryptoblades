<template>
  <div class="pvp-main-screen">

      <b-row class="pvp-header">
        <b-col id="arsenal-preparation-header" cols="5">
          ARSENAL PREPARATION
        </b-col>
        <b-col id= "find-opponent-header" cols="2">
          FIND OPPONENT
        </b-col>
        <b-col id="arena-header" cols="5">
          ARENA
        </b-col>
      </b-row>

      <b-row class="pvp-divider">
        <b-col cols="5" class="character-header">
          <b-row class="character-header-container">
            <b-col cols="1">
              <Hint text="Placeholder text for character hint"/>
            </b-col>
            <b-col cols="3" class="pvp-divider-header-line">
            </b-col>
            <b-col cols="4" class="pvp-divider-header">
              CHARACTER
            </b-col>
            <b-col cols="3" class="pvp-divider-header-line">
            </b-col>
          </b-row>
        </b-col>
        <b-col cols="2">
        </b-col>
        <b-col cols="5" class="inventory-header">
          <b-row class="inventory-header-container">
            <b-col cols="3" class="pvp-divider-header-line">
            </b-col>
            <b-col cols="4" class="pvp-divider-header">
              INVENTORY
            </b-col>
            <b-col cols="3" class="pvp-divider-header-line">
            </b-col>
            <b-col cols="1">
              <Hint text="Placeholder text for inventory hint"/>
            </b-col>
          </b-row>
        </b-col>
      </b-row>

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
                    <div id="character-element-icon">
                    </div>
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
            <b-col cols="6" id="sword-tab-button-container">
              <button id="sword-tab-button">Sword</button>
            </b-col>
            <b-col cols="6" id="shield-tab-button-container">
              <button id="shield-tab-button">Shield</button>
            </b-col>
          </b-row>
          <b-row class="inventory-weapon-container">
              <b-col cols="2">
                <b-row>
                  <b-col>
                    <div id="inventory-weapon-content">
                    </div>
                  </b-col>
                </b-row>
              </b-col>
              <b-col cols="2">
                <b-row>
                  <b-col>
                    <div id="inventory-weapon-content">
                    </div>
                  </b-col>
                </b-row>
              </b-col>
              <b-col cols="2">
                <b-row>
                  <b-col>
                    <div id="inventory-weapon-content">
                    </div>
                  </b-col>
                </b-row>
              </b-col>
              <b-col cols="2">
                <b-row>
                  <b-col>
                    <div id="inventory-weapon-content">
                    </div>
                  </b-col>
                </b-row>
              </b-col>
              <b-col cols="2">
                <b-row>
                  <b-col>
                    <div id="inventory-weapon-content-dashed">
                    </div>
                  </b-col>
                </b-row>
              </b-col>
              <b-col cols="2">
                <b-row>
                  <b-col>
                    <div id="inventory-weapon-content-dashed">
                    </div>
                  </b-col>
                </b-row>
              </b-col>
          </b-row>
          <b-row class="inventory-weapon-container">
              <b-col cols="2">
                <b-row>
                  <b-col>
                    <div id="inventory-weapon-content-dashed">
                    </div>
                  </b-col>
                </b-row>
              </b-col>
              <b-col cols="2">
                <b-row>
                  <b-col>
                    <div id="inventory-weapon-content-dashed">
                    </div>
                  </b-col>
                </b-row>
              </b-col>
              <b-col cols="2">
                <b-row>
                  <b-col>
                    <div id="inventory-weapon-content-dashed">
                    </div>
                  </b-col>
                </b-row>
              </b-col>
              <b-col cols="2">
                <b-row>
                  <b-col>
                    <div id="inventory-weapon-content-dashed">
                    </div>
                  </b-col>
                </b-row>
              </b-col>
              <b-col cols="2">
                <b-row>
                  <b-col>
                    <div id="inventory-weapon-content-dashed">
                    </div>
                  </b-col>
                </b-row>
              </b-col>
              <b-col cols="2">
                <b-row>
                  <b-col>
                    <div id="inventory-weapon-content-dashed">
                    </div>
                  </b-col>
                </b-row>
              </b-col>
          </b-row>

          <b-popover id="weapon-stats" target="inventory-weapon-content" triggers="hover" placement="topleft">
            <template #title>Weapon Stats</template>
                      <div class="stat-text">INT 300</div>
                      <div class="stat-text">INT 300</div>
                      <div class="stat-text">INT 300</div>
          </b-popover>
        </b-col>
      </b-row>

  </div>
</template>

<script>

import character from '../assets/placeholder/chara-0.png';
import Hint from '../components/Hint.vue';

export  default {
  data (){
    return {
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
    }
  },
  components: {
    Hint,
  },

};

</script>

<style>

/* PvP Main Screen */
.pvp-main-screen {
  height: 100%;
  width: 90%;
  margin: auto;
}
/* PvP Main Screen */

/* PvP Header Styles */
.pvp-header {
  text-align: center;
  margin-bottom: 50px;
  margin-top: 50px;
}

#arsenal-preparation-header {
  font-weight: bold;
  border-bottom: 3px solid #968332;
  padding-bottom: 20px;
}

#find-opponent-header {
  font-weight: bold;
}

#arena-header {
  font-weight: bold;
  border-bottom: 3px solid #968332;
  padding-bottom: 20px;
}

#arsenal-preparation-header:hover {
  color: antiquewhite;
}

#find-opponent-header:hover {
  color: black;
}

#arena-header:hover {
  color: antiquewhite;
}
/* PvP Header Styles */

/* PvP Divider */
.pvp-divider {
  text-align: center;
  margin-bottom: 50px;
  margin-top: 50px;
}

.pvp-divider-header {
  border: 1px solid #968332;
}

.character-header-container {
  font-weight: bold;
  justify-content: center;
}

.inventory-header-container {
  font-weight: bold;
  justify-content: center;
}
/* PvP Divider */


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

#character-element-icon {
  content: url("https://seiyria.com/gameicons-font/svg/water-drop.svg");
  background: antiquewhite;
  border: 1px solid #968332;
  border-radius: 50%;
  height: 30px;
  width: 30px;
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

#sword-tab-button {
  border: 1px solid #968332;
  border-radius: 2%;
  background: #32343C;
  color: #968332;
  width: 100%;
  margin: auto;
}

#shield-tab-button {
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
