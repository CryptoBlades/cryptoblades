<template>
  <div class="body main-font">
    <b-navbar-nav>
      <b-nav-item-dropdown right>
        <template #button-content>
          <i class="fa fa-bars"></i>
        </template>

        <b-dropdown-group>

        <b-dropdown-header>Links</b-dropdown-header>

        <b-dropdown-item @click="onClaimTokens()"><i class="fa fa-coins mr-2"></i>Claim Skill </b-dropdown-item>

        <b-dropdown-item @click.native="$router.push('leaderboard')" class="gtag-link-others" tagname="leaderboard_screen">
        <i class="fa fa-trophy mr-2"></i>Leaderboard
        </b-dropdown-item>

        <b-dropdown-item @click.native="$router.push('portal')"><i class="fa fa-dungeon mr-2"></i>Portal</b-dropdown-item>

        <b-dropdown-item href="https://cryptoblades.gitbook.io/wiki/" target="_blank"><i class="fa fa-book mr-2"></i>Wiki <b-icon scale="0.8" icon="question-circle"/></b-dropdown-item>

        </b-dropdown-group>
        <hr class="border-light">

        <b-dropdown-group class="mb-2">

       <b-dropdown-item  @click.native="$router.push('options')">
        <i class="fa fa-cog mr-2"></i>Options
        </b-dropdown-item>
        </b-dropdown-group>
      </b-nav-item-dropdown>
    </b-navbar-nav>

    <b-modal class="centered-modal" ref="need-gas-modal" title="Need Withdraw?"
      @ok="claimSkill(ClaimStage.Stake)" ok-title="Next" @cancel="$router.push({ name: 'portal' })" cancel-title="Go to WAX Portal" >
        Need Withdraw? Try our WAX Portal, which will pay you .5% under market rate to sell your WAX for BNB!
        <div class="text-center">
          <hr class="hr-divider">
          Hold Reminder:<br>
          A percentage of your earning goes back to the community,<br>
          <u>if you withdraw early</u>
          <div class="row">
            <div class="col-5">Your early withdraw tax</div>
            <div class="col-2"><span class="text-danger font-weight-bold">{{formattedRewardsClaimTax}}</span></div>
            <div class="col-5 text-left">Reduces 1% per day<br>
              Reset to 15% after withdraw</div>
          </div>
        </div>
    </b-modal>
    <b-modal class="centered-modal" ref="stake-suggestion-modal" title="Stake Skill"
      @ok="$router.push({ name: 'select-stake-type' })" ok-only ok-title="Go to Stake" >
        You can avoid paying the 15% tax by staking unclaimed skill rewards for 7 days. If you stake your SKILL now, we'll give you a
        50% bonus in-game only SKILL that you can use right away!
      <a href="#" @click="claimSkill(ClaimStage.Claim)"> <br>No thanks, I'd rather {{ (this.rewardsClaimTaxAsFactorBN > 0)?"pay " +
        this.formattedTaxAmount + " in taxes and " : ""  }}forfeit my bonus </a>
    </b-modal>
    <b-modal class="centered-modal" ref="claim-confirmation-modal" title="Claim Skill" ok-title="I am sure"
      @ok="onClaimTokens()"> You are about to {{ (this.rewardsClaimTaxAsFactorBN > 0)?"pay " + formattedRewardsClaimTax +
      " tax for early withdrawal, costing you " + this.formattedTaxAmount + " SKILL. You will also " : "" }}
      miss out on {{formattedBonusLost}} bonus SKILL. Are you sure
      you wish to continue? <b>This action cannot be undone.</b>
    </b-modal>
  </div>
</template>

<script lang="ts">
import Events from '../events';
import { mapActions, mapGetters, mapState } from 'vuex';
import BigNumber from 'bignumber.js';
import { Accessors } from 'vue/types/options';
import Vue from 'vue';
import { toBN, fromWeiEther } from '../utils/common';

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
  hideWalletWarning: boolean;
}

interface StoreMappedGetters {
  rewardsClaimTaxAsFactorBN: BigNumber;
  maxRewardsClaimTaxAsFactorBN: BigNumber;
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
    this.hideWalletWarning = localStorage.getItem('hideWalletWarning') === 'true';
  },

  data() {
    return {
      showGraphics: false,
      hideRewards: false,
      hideWalletWarning: false,
      ClaimStage
    } as Data;
  },

  computed: {
    ...(mapState(['skillRewards', 'directStakeBonusPercent']) as Accessors<StoreMappedState>),
    ...(mapGetters(['rewardsClaimTaxAsFactorBN', 'maxRewardsClaimTaxAsFactorBN']) as Accessors<StoreMappedGetters>),

    formattedSkillReward(): string {
      const skillRewards = fromWeiEther(this.skillRewards);
      return `${toBN(skillRewards).toFixed(4)}`;
    },
    formattedTaxAmount(): string {
      const skillRewards = fromWeiEther(parseFloat(String(parseFloat(this.skillRewards)*parseFloat(String(this.rewardsClaimTaxAsFactorBN)))) + '');
      return `${toBN(skillRewards).toFixed(4)}`;
    },
    formattedRewardsClaimTax(): string {
      const frac =
        this.skillRewards === '0'
          ? this.maxRewardsClaimTaxAsFactorBN
          : this.rewardsClaimTaxAsFactorBN;

      return `${frac.multipliedBy(100).decimalPlaces(0, BigNumber.ROUND_HALF_UP)}%`;
    },
    formattedBonusLost(): string {
      const skillLost = fromWeiEther(parseFloat(String(parseFloat(this.skillRewards)*this.directStakeBonusPercent/100)).toString());
      return `${toBN(skillLost).toFixed(4)}`;
    },
    canClaimTokens(): boolean {
      if(toBN(this.skillRewards).lte(0)) {
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
    },

    toggleHideWalletWarning() {
      this.hideWalletWarning = !this.hideWalletWarning;
      if (this.hideWalletWarning) localStorage.setItem('hideWalletWarning', 'true');
      else localStorage.setItem('hideWalletWarning', 'false');

      Events.$emit('setting:hideWalletWarning', { value: this.hideWalletWarning });
    },
  }
});
</script>

<style scoped></style>
