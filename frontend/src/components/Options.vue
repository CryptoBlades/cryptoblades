<template>
  <div class="body main-font">
    <b-navbar-nav>
      <b-nav-item-dropdown right>
        <template #button-content>
          <i class="fa fa-cog"></i>
        </template>

        <b-dropdown-item @click="toggleGraphics()">3D Graphics: {{ showGraphics ? 'On' : 'Off' }}</b-dropdown-item>

        <b-dropdown-item @click="toggleRewards()">Reward Bar: {{ hideRewards ? 'Off' : 'On' }}</b-dropdown-item>

        <b-dropdown-item @click="toggleAdvanced()">Advanced UI: {{ hideAdvanced ? 'Off' : 'On' }}</b-dropdown-item>

        <b-dropdown-item @click="claimSkill(ClaimStage.WaxBridge)">Claim Skill </b-dropdown-item>

      </b-nav-item-dropdown>
    </b-navbar-nav>

    <b-modal class="centered-modal" ref="need-gas-modal" title="Need Gas?"
      @ok="claimSkill(ClaimStage.Stake)" ok-title="Next" @cancel="$router.push({ name: 'portal' })" cancel-title="Go to WAX Bridge" >
        Need Gas? Try our WAX Bridge, which will pay you .5% under market rate to sell your WAX for BNB!
    </b-modal>
    <b-modal class="centered-modal" ref="stake-suggestion-modal" title="Stake Skill"
      @ok="$router.push({ name: 'select-stake-type' })" ok-only ok-title="Go to Stake" >
        If you stake your SKILL now, we will give you a 10% bonus in SKILL that you can use in-game right away!
      <a href="#" @click="claimSkill(ClaimStage.Claim)"> <br>No thanks, I'd rather {{ (this.rewardsClaimTaxAsFactorBN > 0)?"pay " +
        this.formattedTaxAmount + " in taxes and " : ""  }}forfeit my bonus </a>
    </b-modal>
    <b-modal class="centered-modal" ref="claim-confirmation-modal" title="Claim Skill" ok-title="I am sure"
      @ok="onClaimTokens()"> You are about to {{ (this.rewardsClaimTaxAsFactorBN > 0)?"pay " + formattedRewardsClaimTax +
      " tax for early withdrawal, costing you " + this.formattedTaxAmount + " SKILL. You will also " : "" }}
      forfeit all bonus SKILL earnings for 3 days, costing {{formattedBonusLost}} bonus SKILL. Are you sure
      you wish to continue? <b>This action cannot be undone.</b>
    </b-modal>
  </div>
</template>

<script lang="ts">
import Events from '../events';
import { mapActions, mapGetters, mapState } from 'vuex';
import BN from 'bignumber.js';
import Web3 from 'web3';
import { Accessors } from 'vue/types/options';
import Vue from 'vue';

interface StoreMappedState {
  skillRewards: string;
  directStakeBonusPercent: number;
}

interface StoreMappedActions {
  claimTokenRewards(): Promise<void>;
}
interface Data {
  showGraphics: boolean;
  hideRewards: boolean;
  hideAdvanced: boolean;
}

interface StoreMappedGetters {
  rewardsClaimTaxAsFactorBN: BN;
  maxRewardsClaimTaxAsFactorBN: BN;
}

enum ClaimStage {
  WaxBridge = 0,
  Stake = 1,
  Claim = 2
}

export default Vue.extend({
  created() {
    this.showGraphics = localStorage.getItem('useGraphics') === 'true';
    this.hideRewards = localStorage.getItem('hideRewards') === 'true';
    this.hideAdvanced = localStorage.getItem('hideAdvanced') === 'true';
  },

  data() {
    return {
      showGraphics: false,
      hideRewards: false,
      hideAdvanced: false,
      ClaimStage
    } as Data;
  },

  computed: {
    ...(mapState(['skillRewards', 'directStakeBonusPercent']) as Accessors<StoreMappedState>),
    ...(mapGetters(['rewardsClaimTaxAsFactorBN', 'maxRewardsClaimTaxAsFactorBN']) as Accessors<StoreMappedGetters>),

    formattedSkillReward(): string {
      const skillRewards = Web3.utils.fromWei(this.skillRewards, 'ether');
      return `${new BN(skillRewards).toFixed(4)}`;
    },
    formattedTaxAmount(): string {
      const skillRewards = Web3.utils.fromWei((parseFloat(this.skillRewards)* parseFloat(String(this.rewardsClaimTaxAsFactorBN))).toString(), 'ether');
      return `${new BN(skillRewards).toFixed(4)}`;
    },
    formattedRewardsClaimTax(): string {
      const frac =
        this.skillRewards === '0'
          ? this.maxRewardsClaimTaxAsFactorBN
          : this.rewardsClaimTaxAsFactorBN;

      return `${frac.multipliedBy(100).decimalPlaces(0, BN.ROUND_HALF_UP)}%`;
    },
    formattedBonusLost(): string {
      const skillLost = Web3.utils.fromWei((parseFloat(this.skillRewards)*this.directStakeBonusPercent/100).toString(), 'ether');
      return `${new BN(skillLost).toFixed(4)}`;
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
      this.showGraphics = !this.showGraphics;
      if (this.showGraphics) localStorage.setItem('useGraphics', 'true');
      else localStorage.setItem('useGraphics', 'false');

      Events.$emit('setting:useGraphics', { value: this.showGraphics });
    },

    toggleRewards() {
      this.hideRewards = !this.hideRewards;
      if (this.hideRewards) localStorage.setItem('hideRewards', 'true');
      else localStorage.setItem('hideRewards', 'false');

      Events.$emit('setting:hideRewards', { value: this.hideRewards });
    },

    toggleAdvanced() {
      this.hideAdvanced = !this.hideAdvanced;
      if (this.hideAdvanced) localStorage.setItem('hideAdvanced', 'true');
      else localStorage.setItem('hideAdvanced', 'false');

      Events.$emit('setting:hideAdvanced', { value: this.hideAdvanced });
    },
    async onClaimTokens() {
      if(this.canClaimTokens) {
        await this.claimTokenRewards();
      }
    },
    async claimSkill(stage: ClaimStage) {
      if(stage === ClaimStage.WaxBridge) {
        (this.$refs['need-gas-modal'] as any).show();
      }
      if(stage === ClaimStage.Stake) {
        (this.$refs['stake-suggestion-modal'] as any).show();
      }
      if(stage === ClaimStage.Claim) {
        (this.$refs['stake-suggestion-modal'] as any).hide();
        (this.$refs['claim-confirmation-modal'] as any).show();
      }
    }
  }
});
</script>

<style scoped></style>
