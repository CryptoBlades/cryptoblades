<template>
  <div class="d-flex align-items-center flex-column">
    <div class="d-flex flex-column align-items-center w-50">
      <h3 class="mt-2"> Partnered Projects </h3>
      <img src="../assets/divider4.png" class="expander-divider">
    </div>
    <div class="d-flex w-100 align-items-baseline mt-3 pl-5">
      <h5>Payout Currency:</h5>
      <b-form-select class="w-25 ml-1" size="sm" :value="payoutCurrencyId" @change="updatePayoutCurrencyId($event)">
        <b-form-select-option :value="-1">SKILL</b-form-select-option>
        <b-form-select-option v-for="p in supportedProjects" :key="p.id" :value="p.id">{{p.tokenSymbol}} ({{p.name}})</b-form-select-option>
      </b-form-select>
    </div>
    <div class="d-flex w-100 pt-2 pr-5 pl-5 pb-2 flex-wrap">
      <partnered-project v-for="p in supportedProjects" :key="p.id" :id="p.id" :name="p.name" :tokenSymbol="p.tokenSymbol"
        :tokenSupply="p.tokenSupply" :tokenPrice="p.tokenPrice" :logoFileName="getLogoFile(p.name)"
        :tokenAddress="p.tokenAddress"/>
    </div>
  </div>
</template>

<script lang='ts'>
import PartneredProject from '@/components/PartneredProject.vue';
import Vue from 'vue';
import { Accessors } from 'vue/types/options';
import { mapGetters, mapActions, mapMutations, mapState } from 'vuex';

export interface SupportedProject {
  id: string;
  name: string;
  tokenSymbol: string;
  tokenAddress: string;
  tokenSupply: string;
  tokensClaimed: string;
  tokenPrice: string;
  isActive: boolean;
}

interface StoreMappedGetters {
  getPartnerProjects: SupportedProject[];
}

interface StoreMappedState {
  payoutCurrencyId: string;
}

interface StoreMappedActions {
  fetchPartnerProjects(): Promise<void>;
}

interface Data {
  updateInterval: ReturnType<typeof setInterval> | null;
}

export default Vue.extend({
  components: { PartneredProject },

  data() {
    return {
      updateInterval: null
    } as Data;
  },

  computed: {
    ...(mapGetters(['getPartnerProjects']) as Accessors<StoreMappedGetters>),
    ...(mapState(['payoutCurrencyId']) as Accessors<StoreMappedState>),

    supportedProjects(): SupportedProject[] {
      const supportedProjects = this.getPartnerProjects.map(p => {
        return {
          id: p.id,
          name: p.name,
          tokenSymbol: p.tokenSymbol,
          tokenAddress: p.tokenAddress,
          tokenSupply: p.tokenSupply,
          tokensClaimed: p.tokensClaimed,
          tokenPrice: p.tokenPrice,
          isActive: p.isActive
        };
      });

      return supportedProjects;
    }
  },

  methods: {
    ...(mapActions(['fetchPartnerProjects']) as StoreMappedActions),
    ...mapMutations(['updatePayoutCurrencyId']),

    getLogoFile(projectName: string): string {
      return `${projectName.toLowerCase()}.png`;
    },
  },

  async mounted() {
    await this.fetchPartnerProjects();
    this.updateInterval = setInterval(async () => {
      await this.fetchPartnerProjects();
    }, 3000);
  },

  beforeDestroy() {
    if(this.updateInterval) {
      clearInterval(this.updateInterval);
    }
  }

});

</script>

<style scoped>

</style>
