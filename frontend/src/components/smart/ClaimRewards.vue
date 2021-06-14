<template>
  <b-navbar-nav>
    <b-nav-item-dropdown right>
      <template #button-content>
        Rewards
      </template>

      <b-dropdown-item
        :disabled="!canClaimTokens"
        @click="onClaimTokens">SKILL {{ formattedSkillReward }}</b-dropdown-item>

      <b-dropdown-item
        :disabled="!canClaimXp"
        @click="onClaimXp">XP {{ formattedXpRewards }}</b-dropdown-item>
    </b-nav-item-dropdown>
  </b-navbar-nav>
</template>

<script lang="ts">
import Vue from 'vue';
import { Accessors } from 'vue/types/options';
import { mapActions, mapState } from 'vuex';
import BN from 'bignumber.js';
import Web3 from 'web3';

interface StoreMappedState {
  skillRewards: string;
  xpRewards: Record<string, string>;
  ownedCharacterIds: string[];
}

interface StoreMappedActions {
  claimTokenRewards(): Promise<void>;
  claimXpRewards(): Promise<void>;
}

export default Vue.extend({
  computed: {
    ...(mapState(['skillRewards', 'xpRewards', 'ownedCharacterIds']) as Accessors<StoreMappedState>),

    formattedSkillReward(): string {
      const skillRewards = Web3.utils.fromWei(this.skillRewards, 'ether');
      return `${new BN(skillRewards).toFixed(4)}`;
    },

    xpRewardsForOwnedCharacters(): string[] {
      return this.ownedCharacterIds.map(charaId => this.xpRewards[charaId] || '0');
    },

    formattedXpRewards(): string {
      return this.xpRewardsForOwnedCharacters.map(xp => `${xp}`).join(', ');
    },

    canClaimTokens(): boolean {
      if(new BN(this.skillRewards).lte(0)) {
        return false;
      }

      return true;
    },

    canClaimXp(): boolean {
      const allXpsAreZeroOrLess = this.xpRewardsForOwnedCharacters.every(xp => new BN(xp).lte(0));
      if(allXpsAreZeroOrLess) {
        return false;
      }

      return true;
    }
  },

  methods: {
    ...(mapActions(['addMoreSkill', 'claimTokenRewards', 'claimXpRewards']) as StoreMappedActions),

    onBuySkill() {
      window.open('https://exchange.pancakeswap.finance/#/swap?inputCurrency=0x154a9f9cbd3449ad22fdae23044319d6ef2a1fab',
        '_blank');
    },

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
  },

  watch: {
    skillRewards(balance: number, oldBalance: number) {
      console.log('REWARD SKILL CHANGE:', balance, oldBalance, balance - oldBalance);
    }
  }
});
</script>

<style scoped>

</style>
