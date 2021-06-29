<template>
  <b-navbar>
    <b-icon-exclamation-circle-fill class="rewards-claimable-icon" scale="1.2"
    variant="success" :hidden="!canClaimTokens && !canClaimXp" v-tooltip.bottom="'Rewards ready to claim!'"/>

    <b-nav-item disabled><strong>Rewards</strong></b-nav-item>

    <b-nav-item
      class="ml-3"
      :disabled="!canClaimTokens"
      @click="onClaimTokens"><!-- moved gtag-link below b-nav-item -->
      <span class="gtag-link-others" tagname="claim_skill">
        <strong>SKILL</strong> {{ formattedSkillReward }}
        <strong>Early Withdraw Tax</strong> 0%
        <strong>Time since last withdraw</strong> n/a
      </span>
    </b-nav-item>

    <b-nav-item
      class="ml-3"
      :disabled="!canClaimXp"
      @click="onClaimXp">
        <div class="gtag-link-others" v-html="`<strong>XP</strong> ${formattedXpRewards}`"></div>
    </b-nav-item>
  </b-navbar>
</template>

<script lang="ts">
import Vue from 'vue';
import { BootstrapVueIcons } from 'bootstrap-vue';
import { Accessors } from 'vue/types/options';
import { mapActions, mapGetters, mapState } from 'vuex';
import BN from 'bignumber.js';
import Web3 from 'web3';
import { getCharacterNameFromSeed } from '../../character-name';
import { RequiredXp } from '../../interfaces';


Vue.use(BootstrapVueIcons);

interface StoreMappedState {
  skillRewards: string;
  xpRewards: Record<string, string>;
  ownedCharacterIds: string[]
}

interface StoreMappedActions {
  claimTokenRewards(): Promise<void>;
  claimXpRewards(): Promise<void>;
}

export default Vue.extend({
  computed: {
    ...(mapState(['skillRewards', 'xpRewards', 'ownedCharacterIds']) as Accessors<StoreMappedState>),
    ...(mapGetters(['ownCharacters', 'currentCharacter'])),

    formattedSkillReward(): string {
      const skillRewards = Web3.utils.fromWei(this.skillRewards, 'ether');
      return `${new BN(skillRewards).toFixed(4)}`;
    },

    xpRewardsForOwnedCharacters(): string[] {
      return this.ownedCharacterIds.map(charaId => this.xpRewards[charaId] || '0');
    },

    formattedXpRewards(): string {
      return this.xpRewardsForOwnedCharacters.map((xp, i) => {
        if(!this.ownCharacters[i]) return `${xp}`;
        return  `${this.ownCharacters[i].id === this.currentCharacter.id ? '<b>' : ''}` +
                `${(this.ownCharacters[i].xp + this.xpRewards[this.ownCharacters[i].id]) as any > RequiredXp(this.ownCharacters[i].level) ? '<u>' : ''}` +
                `${getCharacterNameFromSeed(this.ownCharacters[i].id)} ${xp}` +
                `${(this.ownCharacters[i].xp + this.xpRewards[this.ownCharacters[i].id]) as any > RequiredXp(this.ownCharacters[i].level) ? '</u>' : ''}` +
                `${this.ownCharacters[i].id === this.currentCharacter.id ? '</b>' : ''}`;
      }).join(', ');
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
  }
});
</script>

<style scoped>

.navbar {
  background: rgb(20,20,20);
  background: linear-gradient(45deg, rgba(20,20,20,1) 0%, rgba(36,39,32,1) 100%);
}

.nav-item {
  margin-top: -24px;
}

.nav-item a {
  padding: 0;
}

.rewards-claimable-icon {
  margin-right: 5px;
}
</style>
