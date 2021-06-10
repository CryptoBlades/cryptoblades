<template>
  <div class="skill-balance-display">
    <span class="bold spacedReward">Rewards </span>
    <span class="balance spacedReward">{{ formattedSkillReward }}</span>
    <small-button class="claim-button"
      :text="`SKILL`"
      v-tooltip="'Claim SKILL<br>Early withdraw tax: 0%<br>Time since last withdraw: n/a'"
      :disabled="!canClaimTokens"
      @click="onClaimTokens"
    />
    <span class="spacedReward">and</span>
    <span class="balance spacedReward">{{ formattedXpRewards }}</span>
    <small-button class="claim-button"
      :text="`XP`"
      v-tooltip="'Claim XP'"
      :disabled="!canClaimXp"
      @click="onClaimXp"
    />
    <big-button class="buy-button"
      :mainText="`+`"
      v-tooltip="'Buy SKILL'"
      @click="onBuySkill"
    />
    <div class="balance-container"><span class="bold">Balance</span>: <span class="balance">{{ formattedSkillBalance }}</span></div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import { Accessors } from 'vue/types/options';
import { mapActions, mapState } from 'vuex';
import BN from 'bignumber.js';
import Web3 from 'web3';
import BigButton from '../BigButton.vue';
import SmallButton from '../SmallButton.vue';

interface StoreMappedState {
  skillBalance: string;
  skillRewards: string;
  xpRewards: Record<string, string>;
  ownedCharacterIds: string[];
}

interface StoreMappedActions {
  addMoreSkill(skillToAdd: string): Promise<void>;
  claimTokenRewards(): Promise<void>;
  claimXpRewards(): Promise<void>;
}

export default Vue.extend({
  computed: {
    ...(mapState(['skillBalance', 'skillRewards', 'xpRewards', 'ownedCharacterIds']) as Accessors<StoreMappedState>),

    formattedSkillBalance(): string {
      const skillBalance = Web3.utils.fromWei(this.skillBalance, 'ether');
      return `${new BN(skillBalance).toFixed(4)} SKILL`;
    },

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

    async onAddMoreSkill(): Promise<void> {
      const valueSkillToAdd = prompt('How much SKILL do you want?', '5');
      if(!valueSkillToAdd) return;

      const skillToAdd = Web3.utils.toWei(
        valueSkillToAdd,
        'ether'
      );

      try {
        await this.addMoreSkill(skillToAdd);
        alert(`Successfully added ${valueSkillToAdd} SKILL to your balance!`);
      } catch (e) {
        console.error(e);
        alert('Could not add SKILL; insufficient funds or transaction denied.');
      }
    },

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
    skillBalance(balance: number, oldBalance: number) {
      console.log('BALANCE CHANGE:', balance, oldBalance, balance - oldBalance);
    },
    skillRewards(balance: number, oldBalance: number) {
      console.log('REWARD SKILL CHANGE:', balance, oldBalance, balance - oldBalance);
    }
  },

  components: {
    BigButton,
    SmallButton
  }
});
</script>

<style scoped>
.skill-balance-display {
  display: flex;
  align-items: center;
  font-size: 1.1rem;
}

.add-more-skill:hover {
  color: white;
  background: rgba(255, 255, 255, 0.25);
}

.balance-container {
  margin-right: 5px;
}

.balance {
  color: #b3b0a7;
}

.buy-button {
  width: 2rem;
  height: 3rem;
  margin-right: 1rem;
}

.claim-button {
  height: 2rem;
  margin-right: 1rem;
}

.spacedReward {
  margin-right: 1rem;
}

</style>
