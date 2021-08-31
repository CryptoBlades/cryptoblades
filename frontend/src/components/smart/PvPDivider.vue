<template>
      <b-row class="pvp-divider">
        <b-col cols="5" class="character-header">
          <b-row class="character-header-container">
            <b-col cols="1">
              <Hint v-bind:text="characterHeaderTextHint"/>
            </b-col>
            <b-col cols="3" class="pvp-divider-header-line">
            </b-col>
            <b-col cols="4" class="pvp-divider-header">
              <span v-text="characterHeaderText"/>
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
              <span v-text="inventoryHeaderText"/>
            </b-col>
            <b-col cols="3" class="pvp-divider-header-line">
            </b-col>
            <b-col cols="1">
              <Hint v-bind:text="inventoryHeaderTextHint"/>
            </b-col>
          </b-row>
        </b-col>
      </b-row>
</template>

<script>

import PvPConstants from '../../utils/constants/pvp-constants';
import Hint from '../../components/Hint.vue';

export default {
  data(){
    return {
      characterHeaderText: PvPConstants.CHARACTER_HEADER_TEXT,
      inventoryHeaderText: PvPConstants.INVENTORY_HEADER_TEXT,
      characterHeaderTextHint: PvPConstants.CHARACTER_HEADER_TEXT_HINT,
      inventoryHeaderTextHint: PvPConstants.INVENTORY_HEADER_TEXT_HINT,
    };
  },

  components: {
    Hint
  },
};
</script>

<style>
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
</style>
