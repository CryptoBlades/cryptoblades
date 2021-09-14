<template>
      <b-row class="pvp-header">
        <b-col id="arsenal-preparation-header" cols="5">
          <span v-text="arsenalPreparationHeaderText"/>
        </b-col>
        <b-col id= "find-opponent-header" cols="2">
          <span
          v-text="findOpponentHeaderText"
          @click="enterArena"/>
        </b-col>
        <b-col id="arena-header" cols="5">
          <span v-text="arenaHeaderText"/>
        </b-col>
      </b-row>
</template>

<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import PvPConstants from '../../utils/constants/pvp-constants';

export default {
  data() {
    return {
      arsenalPreparationHeaderText: PvPConstants.ARSENAL_PREPARATION_HEADER_TEXT,
      findOpponentHeaderText: PvPConstants.FIND_OPPONENT_HEADER_TEXT,
      arenaHeaderText: PvPConstants.ARENA_HEADER_TEXT,
    };
  },

  computed:{
    ...mapState(['currentCharacterId','currentWeaponId']),
    ...mapGetters([
      'currentWeapon',
      'currentCharacter',
      'currentShield'
    ]),
  },

  methods: {

    ...mapActions(['enterArena']),

    enterArena(){
      this.$store.dispatch('enterArena',
        {characterID: this.currentCharacterId,
          weaponID: this.currentWeaponId,
          shieldID: 0,
          useShield: false});
    }
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
