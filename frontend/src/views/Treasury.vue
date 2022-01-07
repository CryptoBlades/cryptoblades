<template>
  <div class="d-flex align-items-center flex-column">
    <div class="d-flex flex-column align-items-center w-50">
      <div class="d-flex">
        <h3 class="mt-2"> {{$t('Treasury.partneredProjects')}} </h3>
        <b-icon-question-circle class="h3 mt-2 ml-3 pointer" @click="openFormulaDetails"/>
      </div>
      <img src="../assets/divider4.png" class="expander-divider" alt="">
    </div>
    <div class="d-flex w-100 align-items-baseline mt-3">
      <h5>{{$t('Treasury.payoutCurrency')}}:</h5>
      <b-form-select class="w-25 ml-1" size="sm" :value="payoutCurrencyId" @change="updatePayoutCurrencyId($event)">
        <b-form-select-option v-if="currentNetworkId !== 56" :value="-1">SKILL</b-form-select-option>
        <b-form-select-option v-for="p in supportedProjects" :key="p.id" :value="p.id">{{p.tokenSymbol}} ({{p.name}})</b-form-select-option>
      </b-form-select>
    </div>
    <div class="d-flex w-100 pt-2 pb-2 flex-wrap projects-container">
      <partnered-project v-for="p in supportedProjects" :key="p.id" :id="p.id" :name="p.name" :tokenSymbol="p.tokenSymbol"
        :tokenSupply="p.tokenSupply" :tokenPrice="p.tokenPrice" :logoFileName="getLogoFile(p.name)"
        :tokenAddress="p.tokenAddress"/>
    </div>
    <b-modal ok-only class="centered-modal" ref="formula-details-modal" :title="$t('Treasury.formulaDetailsTitle')">
      <span class="white-space">{{$t('Treasury.payoutFormulaExplanation')}}</span>
    </b-modal>
  </div>
</template>

<script lang='ts'>
import PartneredProject from '@/components/PartneredProject.vue';
import Vue from 'vue';
import {Accessors} from 'vue/types/options';
import {mapActions, mapGetters, mapMutations, mapState} from 'vuex';

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
  currentNetworkId: number;
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
    ...(mapState(['payoutCurrencyId', 'currentNetworkId']) as Accessors<StoreMappedState>),

    supportedProjects(): SupportedProject[] {
      return this.getPartnerProjects.map(p => {
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
    }
  },

  methods: {
    ...(mapActions(['fetchPartnerProjects']) as StoreMappedActions),
    ...mapMutations(['updatePayoutCurrencyId']),

    getLogoFile(projectName: string): string {
      return `${projectName.toLowerCase()}.png`;
    },

    openFormulaDetails(): void {
      (this.$refs['formula-details-modal'] as any).show();
    }
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
.white-space {
  white-space: break-spaces;
}

@media (max-width: 576px) {
  .projects-container {
    justify-content: center;
  }
}
</style>
