<template>
  <div class="d-flex align-items-center flex-column">
    <div class="d-flex flex-column align-items-center w-50">
      <h3 class="mt-2"> Partnered Projects </h3>
      <img src="../assets/divider4.png" class="expander-divider">
    </div>
    <div class="d-flex flex-row w-100 align-items-baseline mt-3 pl-5">
      <h5>Payout Currency:</h5>
      <b-form-select class="w-25 ml-1" size="sm" v-model="payoutCurrency" @change="setPayoutCurrency()">
        <b-form-select-option :value="'SKILL'">SKILL</b-form-select-option>
        <b-form-select-option v-for="p in supportedProjects" :key="p.name" :value="p.tokenSymbol">{{p.tokenSymbol}} ({{p.name}})</b-form-select-option>
      </b-form-select>
    </div>
    <div class="d-flex flex-row w-100 pt-2 pr-5 pl-5 pb-2 flex-wrap">
      <partnered-project v-for="p in supportedProjects" :key="p.name" :name="p.name" :tokenSymbol="p.tokenSymbol"
        :tokenSupply="p.tokenSupply" :tokensClaimed="p.tokensClaimed" :logoFileName="getLogoFile(p.name)"/>
    </div>
  </div>
</template>

<script lang='ts'>
import PartneredProject from '@/components/PartneredProject.vue';
import Vue from 'vue';

interface SupportedProject {
  name: string;
  tokenSymbol: string;
  tokenSupply: string;
  tokensClaimed: string;
}
export default Vue.extend({
  components: { PartneredProject },

  data() {
    return {
      payoutCurrency: localStorage.getItem('payoutCurrency') || 'SKILL'
    };
  },

  computed: {
    // TODO: PULL FROM CHAIN
    supportedProjects(): SupportedProject[] {
      return [
        {name: 'Bounty', tokenSymbol: 'BT', tokenSupply: '33333', tokensClaimed: '13000'},
        {name: 'Trinket1', tokenSymbol: 'TR', tokenSupply: '10000', tokensClaimed: '7412'},
        {name: 'Sword0', tokenSymbol: 'SW0', tokenSupply: '1000', tokensClaimed: '312'},
        {name: 'Sword1', tokenSymbol: 'SW1', tokenSupply: '45000', tokensClaimed: '7211'},
        {name: 'Sword2', tokenSymbol: 'SW2', tokenSupply: '1230000', tokensClaimed: '743445'},
        {name: 'Sword3', tokenSymbol: 'SW3', tokenSupply: '9999', tokensClaimed: '1322'},
      ];
    }
  },

  methods: {
    getLogoFile(projectName: string): string {
      return `${projectName.toLowerCase()}.png`;
    },

    setPayoutCurrency() {
      localStorage.setItem('payoutCurrency', this.payoutCurrency);
    }
  }

});

</script>

<style scoped>

</style>
