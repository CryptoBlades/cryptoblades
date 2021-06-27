<template>
  <div class="body main-font">
    <b-navbar-nav>
      <b-nav-item-dropdown right>
        <template #button-content>
          <i class="fa fa-cog"></i>
        </template>

        <b-dropdown-item
          @click="toggleGraphics()">3D Graphics: {{ hideGraphics ? 'Off' : 'On' }}</b-dropdown-item>

        <b-dropdown-item
          @click="toggleRewards()">Reward Bar: {{ hideRewards ? 'Off' : 'On' }}</b-dropdown-item>

        <b-dropdown-item
          @click="toggleAdvanced()">Advanced UI: {{ hideAdvanced ? 'Off' : 'On' }}</b-dropdown-item>

        <b-dropdown-item
          @click="claimSkill(0)">Claim Skill </b-dropdown-item>

      </b-nav-item-dropdown>
    </b-navbar-nav>

    <b-modal class="centered-modal" ref="need-gas-modal" title="Need Gas?"
      @ok="claimSkill(1)" ok-title="Next" cancel-title="Go to WAX Bridge" >
        Need Gas? Try our WAX Bridge, which will pay you .5% under market rate to sell your WAX for BNB!
    </b-modal>
    <b-modal class="centered-modal" ref="stake-suggestion-modal" title="Stake Skill"
      @ok="goToStake()" ok-only ok-title="Go to Stake" >
        If you stake your SKILL now, we will give you a 10% bonus in SKILL that you can use in-game right away!
      <a href="#" @click="claimSkill(2)"> <br>No thanks, I'd rather {{ (this.currentWithdrawTax > 0)?"pay " +
        this.formattedTaxAmount + " in taxes and " : ""  }}forfeit my bonus </a>
    </b-modal>
    <b-modal class="centered-modal" ref="claim-confirmation-modal" title="Claim Skill" ok-title="I am sure"
      @ok="onClaimTokens()"> You are about to {{ (this.currentWithdrawTax > 0)?"pay " + this.currentWithdrawTax +
      " tax for early withdrawal, costing you " + this.formattedTaxAmount + " SKILL. You will also " : "" }}
      forfeit all bonus SKILL earnings for 3 days. Are you sure you wish to continue?
      <b>This action cannot be undone.</b>
    </b-modal>

  </div>
</template>

<script lang="ts">

import Events from '../events';
import { mapActions, mapState } from 'vuex';
import createRouter from '@/router';
import BN from 'bignumber.js';
import Web3 from 'web3';
import { Accessors } from 'vue/types/options';
import { BootstrapVueIcons } from 'bootstrap-vue';
import Vue from 'vue';

Vue.use(BootstrapVueIcons);

interface StoreMappedState {
  skillRewards: string;
}

interface StoreMappedActions {
  claimTokenRewards(): Promise<void>;
}

interface Data {
  hideGraphics: boolean;
  hideRewards: boolean;
  hideAdvanced: boolean;
  currentWithdrawTax: number;
}


export default Vue.extend({

  created() {
    this.hideGraphics = !!localStorage.getItem('graphics');
    this.hideRewards = !!localStorage.getItem('rewards');
    this.hideAdvanced = !!localStorage.getItem('advanced');
    this.currentWithdrawTax = 0.14;
  },

  data() {
    return {
      hideGraphics: false,
      hideRewards: false,
      hideAdvanced: false
    } as Data;
  },

  computed: {
    ...(mapState(['skillRewards']) as Accessors<StoreMappedState>),

    formattedSkillReward(): string {
      const skillRewards = Web3.utils.fromWei(this.skillRewards, 'ether');
      return `${new BN(skillRewards).toFixed(4)}`;
    },

    formattedTaxAmount(): string {
      const skillRewards = Web3.utils.fromWei((parseFloat(this.skillRewards)*this.currentWithdrawTax).toString(), 'ether');
      return `${new BN(skillRewards).toFixed(4)}`;
    },

    canClaimTokens(): boolean {
      if(new BN(this.skillRewards).lte(0)) {
        return false;
      }

      return true;
    },
  },

  methods: {
    ...(mapActions(['claimTokenRewards']) as StoreMappedActions),
    toggleGraphics() {
      this.hideGraphics = !this.hideGraphics;
      if(this.hideGraphics) localStorage.setItem('graphics', 'off');
      else                  localStorage.removeItem('graphics');

      Events.$emit('setting:graphics', { value: this.hideGraphics });
    },

    toggleRewards() {
      this.hideRewards = !this.hideRewards;
      if(this.hideRewards) localStorage.setItem('rewards', 'off');
      else                 localStorage.removeItem('rewards');

      Events.$emit('setting:rewards', { value: this.hideRewards });
    },

    toggleAdvanced() {
      this.hideAdvanced = !this.hideAdvanced;
      if(this.hideAdvanced) localStorage.setItem('advanced', 'off');
      else                  localStorage.removeItem('advanced');

      Events.$emit('setting:advanced', { value: this.hideAdvanced });
    },

    async goToStake() {
      const router = createRouter();
      router.push('/stake');
    },

    async onClaimTokens() {
      if(this.canClaimTokens) {
        await this.claimTokenRewards();
      }
    },

    async claimSkill(stage: number) {
      if(stage === 0) {
        (this.$refs['need-gas-modal'] as any).show();
      }
      if(stage === 1) {
        (this.$refs['stake-suggestion-modal'] as any).show();
      }
      if(stage === 2) {
        (this.$refs['stake-suggestion-modal'] as any).hide();
        (this.$refs['claim-confirmation-modal'] as any).show();
      }
    }
  }
});
</script>

<style scoped>
</style>
