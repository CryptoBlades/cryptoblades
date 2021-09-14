<template>
  <div class="pvp-main-screen">
        <pvp-header>
        </pvp-header>

        <pvp-arena-details>
        </pvp-arena-details>

        <pvp-divider>
        </pvp-divider>

        <pvp-arsenal-preparation>
        </pvp-arsenal-preparation>
  </div>
</template>

<script>
import PvPHeader from '../components/smart/PvPHeader.vue';
import PvPDivider from '../components/smart/PvPDivider.vue';
import PvPArsenalPreparation from '../components/smart/PvPArsenalPreparation.vue';
import PvPArenaDetails from '../components/smart/PvPArenaDetails.vue';

export  default {
  data (){
    return {
    };
  },

  components: {
    'pvp-header':PvPHeader,
    'pvp-divider':PvPDivider,
    'pvp-arsenal-preparation':PvPArsenalPreparation,
    'pvp-arena-details':PvPArenaDetails,
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

</style>
