<template>
  <div class="pvp-main-screen">
        <pvp-header>
        </pvp-header>

        <pvp-arsenal-preparation v-if="pvp.page === '0'">
        </pvp-arsenal-preparation>

        <pvp-arena v-if="pvp.page === '1'">
        </pvp-arena>

  </div>
</template>

<script>
import { mapState } from 'vuex';
import PvPHeader from '../components/smart/PvPHeader.vue';
import PvPArsenalPreparation from '../components/smart/PvPArsenalPreparation.vue';
import PvPArena from '../components/smart/PvPArena.vue';



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
    'pvp-arsenal-preparation':PvPArsenalPreparation,
    'pvp-arena':PvPArena
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
