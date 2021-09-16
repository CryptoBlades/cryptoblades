<template>
      <b-row class="pvp-header">
        <b-col class="page-header">
          <span
                v-text="arsenalPreparationHeaderText"
                v-if="this.pvp.page === '0'"/>
          <span
                v-text="arenaHeaderText"
                v-if="this.pvp.page === '1'"/>
        </b-col>
      </b-row>
</template>

<script>
import { mapState } from 'vuex';
import PvPConstants from '../../utils/constants/pvp-constants';

export default {
  data() {
    return {
      arsenalPreparationHeaderText: PvPConstants.ARSENAL_PREPARATION_HEADER_TEXT,
      arenaHeaderText: PvPConstants.ARENA_HEADER_TEXT,
    };
  },

  computed: {
    ...mapState(['pvp']),
  }


};
</script>

<style>
/* PvP Header Styles */
.pvp-header {
  text-align: center;
  margin-bottom: 50px;
  margin-top: 50px;
}

.page-header {
  font-weight: bold;
  border-bottom: 3px solid #968332;
  padding-bottom: 20px;
  font-size: 50px;
  text-shadow: 0 0 10px black, 0 0 20px #fff;
}

.page-header:hover {
  cursor: none;
}
/* PvP Header Styles */

</style>
