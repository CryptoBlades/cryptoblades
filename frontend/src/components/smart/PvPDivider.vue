<template>
      <b-row class="pvp-divider">
        <b-col class="character-header">
          <b-row class="character-header-container">
            <b-col cols="3" class="pvp-divider-header-line">
            </b-col>
            <b-col cols="4" class="pvp-divider-header">
              <span v-text="characterHeaderText"/>
            </b-col>
            <b-col cols="3" class="pvp-divider-header-line">
            </b-col>
          </b-row>
        </b-col>
      </b-row>
</template>

<script>

import PvPConstants from '../../utils/constants/pvp-constants';

export default {
  data(){
    return {
      characterHeaderText: PvPConstants.CHARACTER_HEADER_TEXT,
      characterHeaderTextHint: PvPConstants.CHARACTER_HEADER_TEXT_HINT,
    };
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

.pvp-divider-header-line {
  border-top: 1px solid #968332;
  height: 1px;
  margin-top: 12px;
}

.character-header-container {
  font-weight: bold;
  justify-content: center;
}
/* PvP Divider */
</style>
