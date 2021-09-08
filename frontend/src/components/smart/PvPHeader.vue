<template>
      <b-row class="pvp-header">
        <b-col id="arsenal-preparation-header" cols="5">
          <span v-text="arsenalPreparationHeaderText"/>
        </b-col>
        <b-col id= "find-opponent-header" cols="2">
          <span v-text="findOpponentHeaderText"/>
        </b-col>
        <b-col id="arena-header" cols="5">
          <span v-text="arenaHeaderText"/>
        </b-col>
      </b-row>
</template>

<script>
import PvPConstants from '../../utils/constants/pvp-constants';

export default {
  data() {
    return {
      arsenalPreparationHeaderText: PvPConstants.ARSENAL_PREPARATION_HEADER_TEXT,
      findOpponentHeaderText: PvPConstants.FIND_OPPONENT_HEADER_TEXT,
      arenaHeaderText: PvPConstants.ARENA_HEADER_TEXT,
    };
  },

  methods: {
    getArenaState(){
      this.$store.dispatch('fetchArenaType');
      this.$store.dispatch('fetchEntryWager',{characterID: 0});
      this.$store.dispatch('fetchArenaTier',{characterID: 0});
      this.$store.dispatch('fetchWageredSkill',{characterID: 0});
      this.$store.dispatch('fetchParticipatingCharacters');
      this.$store.dispatch('fetchDuelCost',{characterID: 0});
      this.$store.dispatch('fetchIsAttackerWithinDecisionTime',{characterID: 0});
      this.$store.dispatch('fetchIsCharacterAttackable',{characterID: 0});
      this.$store.dispatch('fetchIsCharacterInArena',{characterID: 0});
      this.$store.dispatch('fetchIsWeaponInArena',{weaponID: 0});
      this.$store.dispatch('fetchIsShieldInArena',{shieldID: 0});
      this.$store.dispatch('enterArena',{characterID: 0});
    },
  },

  mounted(){
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
