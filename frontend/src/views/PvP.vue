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

      <b-row class="pvp-content">
        <b-col id="arsenal-preparation-content" cols="5">
          ARSENAL PREPARATION CONTENT
        </b-col>
        <b-col id="find-opponent-divider">
        </b-col>
        <b-col id= "find-opponent-content" cols="2">
        </b-col>
        <b-col id="arena-content" cols="5">
          ARENA CONTENT
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
        {id: '1', name: 'Voir Ghuru', img: character}
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
}

#arsenal-preparation-header {
  font-weight: bold;
  border-bottom: 2px solid #968332;
  padding-bottom: 20px;
}

#find-opponent-header {
  font-weight: bold;
}

#arena-header {
  font-weight: bold;
  border-bottom: 2px solid #968332;
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

/* PvP Content Styles */
.pvp-content {
  text-align: center;
}

#find-opponent-divider {
  border-left: 1px solid #968332;
  height: 250px;
  width: 1px;
  position: absolute;
  left: 50%;
  margin-left: -3px;
}

/* PvP Content Styles */

</style>
