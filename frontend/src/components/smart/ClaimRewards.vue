<template>
  <b-navbar-nav>
    <b-icon-exclamation-circle-fill class="rewards-claimable-icon" scale="1.2"
    variant="success" :hidden="!canClaimTokens && !canClaimXp" v-tooltip.bottom="'Rewards ready to claim!'"/>

    <b-nav-item-dropdown right>
      <template #button-content>
        Rewards
      </template>

      <b-dropdown-item
        :disabled="!canClaimTokens"
        @click="onClaimTokens">
          SKILL
          <div class="pl-3">{{ formattedSkillReward }}</div>
          <div class="pl-3">Early withdraw tax: 0%</div>
          <div class="pl-3">Time since last withdraw: n/a</div>
      </b-dropdown-item>

      <b-dropdown-item
        :disabled="!canClaimXp"
        @click="onClaimXp">
          XP <div class="pl-3" v-for="(reward, index) in formattedXpRewards" :key="index">{{ reward }}</div>
        </b-dropdown-item>
    </b-nav-item-dropdown>
  </b-navbar-nav>
</template>

<script lang="ts">
import Vue from 'vue';
import { BootstrapVueIcons } from 'bootstrap-vue';
import { Accessors } from 'vue/types/options';
import { mapActions, mapGetters, mapState } from 'vuex';
import BN from 'bignumber.js';
import Web3 from 'web3';
import { getCharacterNameFromSeed } from '../../character-name';

Vue.use(BootstrapVueIcons);

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
    ...(mapGetters(['ownCharacters'])),

    formattedSkillReward(): string {
      const skillRewards = Web3.utils.fromWei(this.skillRewards, 'ether');
      return `${new BN(skillRewards).toFixed(4)}`;
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

.rewards-claimable-icon {
  margin-right: 5px;
}

</style>
