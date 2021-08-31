<template>
  <div class="pvp-main-screen">
        <pvp-header>
        </pvp-header>

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

export  default {
  data (){
    return {
    };
  },

  components: {
    'pvp-header':PvPHeader,
    'pvp-divider':PvPDivider,
    'pvp-arsenal-preparation':PvPArsenalPreparation,
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
