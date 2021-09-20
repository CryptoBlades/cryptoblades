<template>
  <div class="pvp-main-screen">
        <pvp-header>
        </pvp-header>

        <pvp-divider>
        </pvp-divider>

        <pvp-arsenal-preparation v-if="pvp.page === '0'">
        </pvp-arsenal-preparation>

        <pvp-arena v-if="pvp.page === '1'">
        </pvp-arena>
  </div>
</template>

<script>
import PvPHeader from '../components/smart/PvPHeader.vue';
import PvPDivider from '../components/smart/PvPDivider.vue';
import PvPArsenalPreparation from '../components/smart/PvPArsenalPreparation.vue';
import PvPArena from '../components/smart/PvPArena.vue';
import { mapState } from 'vuex';

export  default {
  data (){
    return {
    };
  },

  computed: {
    ...mapState(['pvp'])
  },

  components: {
    'pvp-header':PvPHeader,
    'pvp-divider':PvPDivider,
    'pvp-arsenal-preparation':PvPArsenalPreparation,
    'pvp-arena':PvPArena,
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
