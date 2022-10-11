<template>
<div class="bg">
  <div class="d-flex align-items-center flex-column content">
    <div class="d-flex flex-column align-items-center w-50">
      <div class="d-flex mt-2">
        <h3 class="mt-2"> {{$t('Treasury.partneredProjects')}} </h3>
        <b-icon-question-circle class="h3 mt-2 ml-3 pointer" @click="openFormulaDetails"/>
      </div>
      <div class="divider"></div>
    </div>
    <div class="d-flex align-items-baseline mt-3 justify-content-center">
      <h5 class="mr-1">{{$t('Treasury.payoutCurrency')}}</h5>
      <b-form-select class="w-25 ml-1" size="sm" :value="payoutCurrencyId" @change="updatePayoutCurrencyId($event)">
        <b-form-select-option v-for="p in this.getPartnerProjects" :key="p.id" :value="p.id">{{p.tokenSymbol}} ({{p.name}})</b-form-select-option>
      </b-form-select>
    </div>
    <div class="d-flex flex-column align-items-center mt-3">
      <h2 v-if="genesisPartnerProjects.length > 0">Genesis Treasuries</h2>
      <div class="d-flex pt-2 pb-2 flex-wrap justify-content-center projects-container">
        <PartneredProject v-for="partnerProject in genesisPartnerProjects" :key="partnerProject.id" :partnerProject="partnerProject" />
      </div>
    </div>
    <div class="d-flex flex-column align-items-center mt-3">
      <h2 v-if="nonGenesisPartnerProjects.length > 0">Non-Genesis Treasuries</h2>
      <div class="d-flex pt-2 pb-2 flex-wrap justify-content-center projects-container">
        <PartneredProject v-for="partnerProject in nonGenesisPartnerProjects" :key="partnerProject.id" :partnerProject="partnerProject" />
      </div>
    </div>
    <b-modal ok-only class="centered-modal" ref="formula-details-modal" :title="$t('Treasury.formulaDetailsTitle')">
      <span class="white-space">{{$t('Treasury.payoutFormulaExplanation')}}</span>
    </b-modal>
  </div>
</div>
</template>

<script lang='ts'>
import PartneredProject from '@/components/common/PartneredProject.vue';
import Vue from 'vue';
import {Accessors} from 'vue/types/options';
import {mapActions, mapGetters, mapMutations, mapState} from 'vuex';

export interface SupportedProject {
  id: number;
  name: string;
  tokenSymbol: string;
  tokenAddress: string;
  tokenSupply: number;
  tokensClaimed: number;
  tokenPrice: number;
  isActive: boolean;
  isValor: boolean;
  logo: string;
  details: string;
  website: string;
  note: string;
}

interface StoreMappedTreasuryGetters {
  getPartnerProjects: SupportedProject[];
}

interface StoreMappedState {
  currentNetworkId: number;
}

interface StoreMappedTreasuryState {
  payoutCurrencyId: string;
}

interface StoreMappedTreasuryActions {
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
    ...(mapGetters('treasury', ['getPartnerProjects']) as Accessors<StoreMappedTreasuryGetters>),
    ...(mapState(['currentNetworkId']) as Accessors<StoreMappedState>),
    ...(mapState('treasury',['payoutCurrencyId'])as Accessors<StoreMappedTreasuryState>),

    genesisPartnerProjects(): SupportedProject[] {
      return this.getPartnerProjects.filter(p => !p.isValor);
    },

    nonGenesisPartnerProjects(): SupportedProject[] {
      return this.getPartnerProjects.filter(p => p.isValor);
    }
  },

  methods: {
    ...(mapActions('treasury',['fetchPartnerProjects']) as StoreMappedTreasuryActions),
    ...mapMutations('treasury', ['updatePayoutCurrencyId']),

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

.divider{
  background: radial-gradient(circle, rgba(255, 255, 255, 0.873) 0%, rgba(71, 72, 73, 0.377)50%);
  width: 100%;
  height: 1px;
}

.bg {
  height: 100%;
  width: 100%;
  background: url('../assets/blacksmith/cb-reforge-bg.jpg') rgba(0, 9, 26, 0.5);
  background-repeat: no-repeat;
  background-size: cover;
  background-blend-mode: multiply;

}
.content > * {
  width: clamp(200px, 100%, 1440px);
}

@media (max-width: 576px) {
  .projects-container {
    justify-content: center;
  }
}
</style>
