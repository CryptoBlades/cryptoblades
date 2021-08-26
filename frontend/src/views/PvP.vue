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
        <b-col cols="5" class="pvp-divider-header">
          CHARACTER
        </b-col>
        <b-col cols="2">
        </b-col>
        <b-col cols="5" class="pvp-divider-header">
          INVENTORY
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
              <b-col cols="6">

              </b-col>
              <b-col cols="6">
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
          </b-row>
        </b-col>
        <b-col id="find-opponent-divider">
        </b-col>
        <b-col id= "find-opponent-content" cols="2">
        </b-col>
        <b-col id="arena-content" cols="5">
          INVENTORY CONTENT
        </b-col>
      </b-row>

  </div>
</template>

<script>

import character from '../assets/placeholder/chara-0.png';

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

};

</script>

<style>

/* PvP Main Screen */
.pvp-main-screen {
  height: 100%;
  width: 80%;
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
  border-bottom: 1px solid #968332;
  padding-bottom: 20px;
}

#find-opponent-header {
  font-weight: bold;
}

#arena-header {
  font-weight: bold;
  border-bottom: 1px solid #968332;
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
/* PvP Divider */


/* PvP Content Styles */
.pvp-content {
  text-align:center;
  margin-bottom: 50px;
  margin-top: 50px;
}

#find-opponent-divider {
  border-left: 1px solid #968332;
  height: 400px;
  width: 1px;
  position: absolute;
  left: 50%;
  margin-left: -3px;
}


/* PvP Arsenal Preparation Styles */

#slider-buttons {
  border-bottom: 2px solid #968332;
  margin-bottom: 50px;
  padding-bottom: 20px;
}

.character-buttons {
  background: antiquewhite;
  background-image: url("https://seiyria.com/gameicons-font/svg/character.svg");
  border: 1px solid #968332;
  height: 50px;
  width: 50px;
  margin:auto;
  margin-top: 3px;
}

.active-indicator {
  border: 1px dashed #968332;
  height: 60px;
  width: 60px;
}

#character-image {
  height:300px;
  width: 160px;
}

/* PvP Arsenal Preparation Styles */


/* PvP Content Styles */

</style>
