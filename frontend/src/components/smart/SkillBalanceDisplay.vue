<template>
  <div class="skill-balance-display">
    <b-button size="sm" class="my-2 my-sm-0 mr-3" variant="primary" v-tooltip="'Buy SKILL'" @click="onBuySkill">
      <i class="fa fa-plus gtag-link-others" tagname="buy_skill"></i>
    </b-button>

    <div class="balance-container">
      <strong class="mr-2">Balance</strong>
      <span class="balance">{{ formattedSkillBalance }}</span>
    </div>

    <div class="bnb-withdraw-container mx-3" v-if="hasBnbAvailableToWithdraw">
      <b-icon-diamond-half scale="1.2"
                           :class="canWithdrawBnb ? 'pointer' : null"
                           :variant="canWithdrawBnb ? 'success' : 'warning'"
                           @click="onWithdrawBNB"
                           v-tooltip.bottom="bnbClaimTooltip" />
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import { Accessors } from 'vue/types/options';
import { mapActions, mapState, mapGetters } from 'vuex';
import BN from 'bignumber.js';
import Web3 from 'web3';
import { IState } from '@/interfaces';
import { formatDurationFromSeconds } from '@/utils/date-time';

type StoreMappedState = Pick<IState, 'skillBalance' | 'waxBridgeWithdrawableBnb' | 'waxBridgeTimeUntilLimitExpires'>;

interface StoreMappedGetters {
  getExchangeUrl: string;
  availableBNB: string;
}

interface StoreMappedActions {
  addMoreSkill(skillToAdd: string): Promise<void>;
  withdrawBnbFromWaxBridge(): Promise<void>;
}

export default Vue.extend({
  computed: {
    ...(mapState(['skillBalance', 'waxBridgeWithdrawableBnb', 'waxBridgeTimeUntilLimitExpires']) as Accessors<StoreMappedState>),
    ...(mapGetters({
      availableBNB: 'waxBridgeAmountOfBnbThatCanBeWithdrawnDuringPeriod',
      getExchangeUrl: 'getExchangeUrl'
    }) as Accessors<StoreMappedGetters>),

    formattedSkillBalance(): string {
      const skillBalance = Web3.utils.fromWei(this.skillBalance, 'ether');
      return `${new BN(skillBalance).toFixed(4)} SKILL`;
    },

    hasBnbAvailableToWithdraw(): boolean {
      return new BN(this.waxBridgeWithdrawableBnb).gt(0);
    },

    canWithdrawBnb(): boolean {
      return new BN(this.availableBNB).gt(0);
    },

    formattedBnbThatCanBeWithdrawn(): string {
      return this.formatBnb(this.availableBNB);
    },

    formattedTotalAvailableBnb(): string {
      return this.formatBnb(this.waxBridgeWithdrawableBnb);
    },

    durationUntilLimitPeriodOver(): string {
      return formatDurationFromSeconds(this.waxBridgeTimeUntilLimitExpires);
    },

    bnbClaimTooltip(): string {
      if(!this.canWithdrawBnb) {
        return `
          You have reached your limit for withdrawing BNB from the portal for this period,
          please wait about ${this.durationUntilLimitPeriodOver}
          (${this.formattedTotalAvailableBnb} left)
        `;
      }

      return `${this.formattedBnbThatCanBeWithdrawn} of ${this.formattedTotalAvailableBnb} withdrawable from the portal`;
    },
  },

  methods: {
    ...(mapActions(['addMoreSkill', 'withdrawBnbFromWaxBridge']) as StoreMappedActions),

    formatBnb(bnb: string): string {
      const amount = Web3.utils.fromWei(bnb, 'ether');
      return `${new BN(amount).toFixed(4)} BNB`;
    },

    onBuySkill() {
      window.open(this.getExchangeUrl, '_blank');
    },

    async onWithdrawBNB() {
      if(!this.canWithdrawBnb) return;

      await this.withdrawBnbFromWaxBridge();
    }
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
