<template>
      <b-row class="pvp-header">
        <b-col id="arsenal-preparation-header" cols="5">
          <span v-text="arsenalPreparationHeaderText"/>
        </b-col>
        <b-col id= "find-opponent-header" cols="2">
          <span v-text="findOpponentHeaderText" @click="findOpponent"/>
        </b-col>
        <b-col id="arena-header" cols="5">
          <span v-text="arenaHeaderText"/>
        </b-col>
      </b-row>
</template>

<script>
import PvPConstants from '../../utils/constants/pvp-constants';
import {mapActions} from 'vuex';

export default {
  data() {
    return {
      arsenalPreparationHeaderText: PvPConstants.ARSENAL_PREPARATION_HEADER_TEXT,
      findOpponentHeaderText: PvPConstants.FIND_OPPONENT_HEADER_TEXT,
      arenaHeaderText: PvPConstants.ARENA_HEADER_TEXT,
    };
  },

  methods: {
    ...mapActions(['enterArena']),

    async findOpponent(){
      await this.enterArena(1,1);
    },
  },



};
</script>

<style>
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

</style>
