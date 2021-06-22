<template>
  <div class="skill-balance-display">
    <b-button size="sm" class="my-2 my-sm-0 mr-3" variant="primary" v-tooltip="'Buy SKILL'" @click="onBuySkill">
      <i class="fa fa-plus"></i>
    </b-button>

    <div class="balance-container">
      <strong class="mr-2">Balance</strong>
      <span class="balance">{{ formattedSkillBalance }}</span></div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import { Accessors } from 'vue/types/options';
import { mapActions, mapState, mapGetters } from 'vuex';
import BN from 'bignumber.js';
import Web3 from 'web3';

interface StoreMappedState {
  skillBalance: string;
}

interface StoreMappedActions {
  addMoreSkill(skillToAdd: string): Promise<void>;
}

export default Vue.extend({
  computed: {
    ...(mapState(['skillBalance', 'skillRewards', 'xpRewards', 'ownedCharacterIds']) as Accessors<StoreMappedState>),
    ...mapGetters([
      'getExchangeUrl'
    ]),

    formattedSkillBalance(): string {
      const skillBalance = Web3.utils.fromWei(this.skillBalance, 'ether');
      return `${new BN(skillBalance).toFixed(4)} SKILL`;
    }
  },

  methods: {
    ...(mapActions(['addMoreSkill']) as StoreMappedActions),

    onBuySkill() {
      window.open(this.getExchangeUrl, '_blank');
    },

  },

  watch: {
    skillBalance(balance: number, oldBalance: number) {
      console.log('BALANCE CHANGE:', balance, oldBalance, balance - oldBalance);
    }
  },

  components: {
  }
});
</script>

<style scoped>
.skill-balance-display {
  display: flex;
  align-items: center;
  font-size: 1.1rem;
}

.balance-container {
  margin-right: 5px;
  color: #b3b0a7;
}

</style>
