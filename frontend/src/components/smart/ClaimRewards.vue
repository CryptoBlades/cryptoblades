<template>
  <div class="body main-font">
    <b-navbar-nav>
      <b-icon-exclamation-circle-fill class="rewards-claimable-icon" scale="1.2"
      variant="success" :hidden="!canClaimTokens && !canClaimXp" v-tooltip.bottom="'Rewards ready to claim!'" />

      <b-nav-item-dropdown right>
        <template #button-content>
          Rewards
        </template>

        <b-dropdown-item
          :disabled="!canClaimTokens"
          @click="onClaimTokens()" class="gtag-link-others" tagname="claim_skill">
            SKILL
            <div class="pl-3">{{ formattedSkillReward }}</div>
            <div class="pl-3">
              Early withdraw tax: {{ formattedRewardsClaimTax }}
              <b-icon-question-circle class="centered-icon" scale="0.8" v-tooltip.bottom="'Tax is being reduced by 1% per day'"/>
            </div>
            <div class="pl-3">Time since last withdraw: n/a</div>
        </b-dropdown-item>

        <b-dropdown-item
          :disabled="!canClaimXp"
          @click="onClaimXp" class="gtag-link-others" tagname="claim_xp">
            XP <div class="pl-3" v-for="(reward, index) in formattedXpRewards" :key="index">{{ reward }}</div>
          </b-dropdown-item>
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
import Vue from 'vue';
import { Accessors } from 'vue/types/options';
import { mapActions, mapGetters, mapState } from 'vuex';
import BigNumber from 'bignumber.js';
import { getCharacterNameFromSeed } from '../../character-name';
import { ICharacter } from '@/interfaces';
import { toBN, fromWeiEther } from '../../utils/common';

interface StoreMappedState {
  skillRewards: string;
  xpRewards: Record<string, string>;
  ownedCharacterIds: string[];
  directStakeBonusPercent: number;
}

interface StoreMappedGetters {
  ownCharacters: ICharacter[];
  maxRewardsClaimTaxAsFactorBN: BigNumber;
  rewardsClaimTaxAsFactorBN: BigNumber;
}

interface StoreMappedActions {
  claimTokenRewards(): Promise<void>;
  claimXpRewards(): Promise<void>;
}

enum ClaimStage {
  WaxBridge = 0,
  Stake = 1,
  Claim = 2
}

export default Vue.extend({
  data() {
    return {
      ClaimStage
    };
  },

  computed: {
    ...(mapState(['skillRewards', 'xpRewards', 'ownedCharacterIds', 'directStakeBonusPercent']) as Accessors<StoreMappedState>),
    ...(mapGetters([
      'ownCharacters', 'maxRewardsClaimTaxAsFactorBN', 'rewardsClaimTaxAsFactorBN'
    ]) as Accessors<StoreMappedGetters>),

    formattedSkillReward(): string {
      const skillRewards = fromWeiEther(this.skillRewards);
      return `${toBN(skillRewards).toFixed(4)}`;
    },

    xpRewardsForOwnedCharacters(): string[] {
      return this.ownedCharacterIds.map(charaId => this.xpRewards[charaId] || '0');
    },

    formattedXpRewards(): string[] {
      return this.xpRewardsForOwnedCharacters.map((xp, i) => {
        if(!this.ownCharacters[i]) return xp;

        return `${getCharacterNameFromSeed(this.ownCharacters[i].id)} ${xp}`;
      });
    },

    canClaimTokens(): boolean {
      if(toBN(this.skillRewards).lte(0)) {
        return false;
      }

      return true;
    },

    formattedTaxAmount(): string {
      const skillRewards = fromWeiEther(toBN(parseFloat(this.skillRewards)* parseFloat(String(this.rewardsClaimTaxAsFactorBN))).toString());
      return `${toBN(skillRewards).toFixed(4)}`;
    },

    formattedBonusLost(): string {
      const skillLost = fromWeiEther(toBN(parseFloat(this.skillRewards)*this.directStakeBonusPercent/100).toString());
      return `${toBN(skillLost).toFixed(4)}`;
    },

    formattedRewardsClaimTax(): string {
      const frac =
        this.skillRewards === '0'
          ? this.maxRewardsClaimTaxAsFactorBN
          : this.rewardsClaimTaxAsFactorBN;

      return `${frac.multipliedBy(100).decimalPlaces(0, BigNumber.ROUND_HALF_UP)}%`;
    },

    canClaimXp(): boolean {
      const allXpsAreZeroOrLess = this.xpRewardsForOwnedCharacters.every(xp => toBN(xp).lte(0));
      if(allXpsAreZeroOrLess) {
        return false;
      }

      return true;
    }
  },

  methods: {
    ...(mapActions(['addMoreSkill', 'claimTokenRewards', 'claimXpRewards']) as StoreMappedActions),

    async onClaimTokens() {
      if(this.canClaimTokens) {
        await this.claimTokenRewards();
      }
    },

    async onClaimXp() {
      if(this.canClaimXp) {
        await this.claimXpRewards();
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

<style scoped>

.rewards-claimable-icon {
  margin-right: 5px;
  align-self: center;
}

</style>
