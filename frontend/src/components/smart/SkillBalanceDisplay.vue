<template>
  <div class="skill-balance-display">
    <div size="sm" class="my-2 my-sm-0 mr-3" variant="primary" v-tooltip="'Buy SKILL'" @click="onBuySkill">
      <!-- <i class="fa fa-plus gtag-link-others" tagname="buy_skill"></i> -->
      <img src="../../assets/addButton.png" class="add-button gtag-link-others"  tagname="buy_skill">
    </div>

    <div class="balance-container">
      <strong class="mr-2 balance-text">Total Balance</strong>
      <span class="balance"
        v-tooltip="{ content: totalSkillTooltipHtml , trigger: (isMobile() ? 'click' : 'hover') }"
        @mouseover="hover = !isMobile() || true"
        @mouseleave="hover = !isMobile()"
      >{{ formattedTotalSkillBalance }} <b-icon-gift-fill scale="1" v-if="hasInGameSkill" variant="success"/>
      </span>
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
import Bignumber from 'bignumber.js';
import { Accessors } from 'vue/types/options';
import { mapActions, mapState, mapGetters } from 'vuex';
import { toBN, fromWeiEther } from '../../utils/common';
import { IState } from '@/interfaces';
import { formatDurationFromSeconds } from '@/utils/date-time';

type StoreMappedState = Pick<IState, 'skillRewards' | 'skillBalance' | 'inGameOnlyFunds' | 'waxBridgeWithdrawableBnb' | 'waxBridgeTimeUntilLimitExpires'>;

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
    ...(mapState(['skillRewards', 'skillBalance', 'inGameOnlyFunds', 'waxBridgeWithdrawableBnb',
      'waxBridgeTimeUntilLimitExpires']) as Accessors<StoreMappedState>),
    ...(mapGetters({
      availableBNB: 'waxBridgeAmountOfBnbThatCanBeWithdrawnDuringPeriod',
      getExchangeUrl: 'getExchangeUrl'
    }) as Accessors<StoreMappedGetters>),

    formattedTotalSkillBalance(): string {
      const skillBalance = fromWeiEther(Bignumber.sum(toBN(this.skillBalance), toBN(this.inGameOnlyFunds), toBN(this.skillRewards)));

      return `${toBN(skillBalance).toFixed(4)} SKILL`;
    },

    formattedSkillBalance(): string {
      const skillBalance = fromWeiEther(this.skillBalance);
      return `${toBN(skillBalance).toFixed(4)} SKILL`;
    },

    hasBnbAvailableToWithdraw(): boolean {
      return toBN(this.waxBridgeWithdrawableBnb).gt(0);
    },

    canWithdrawBnb(): boolean {
      return toBN(this.availableBNB).gt(0);
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
    formattedInGameOnlyFunds(): string {
      const skillBalance = fromWeiEther(this.inGameOnlyFunds);
      return `${toBN(skillBalance).toFixed(4)} SKILL`;
    },
    totalSkillTooltipHtml() {
      const inGameOnlyFundsBalance = fromWeiEther(this.inGameOnlyFunds);
      const skillRewards = fromWeiEther(this.skillRewards);
      const skillBalance = fromWeiEther(this.skillBalance);

      let html =  toBN(skillBalance).toFixed(4) + ' SKILL';

      if(parseFloat(skillRewards) !== 0){
        html += '<br>+ WITHDRAWABLE ' + toBN(skillRewards).toFixed(4) + ' SKILL';
      }

      if(parseFloat(inGameOnlyFundsBalance) !== 0){
        html += '<br>+ IN GAME ONLY ' + toBN(inGameOnlyFundsBalance).toFixed(4) + ' SKILL';
      }

      return html;
    },
    hasInGameSkill(): boolean {
      const inGameOnlyFundsBalance = fromWeiEther(this.inGameOnlyFunds);
      return parseFloat(inGameOnlyFundsBalance) !== 0;
    },
  },

  methods: {
    ...(mapActions(['addMoreSkill', 'withdrawBnbFromWaxBridge']) as StoreMappedActions),

    formatBnb(bnb: string): string {
      const amount = fromWeiEther(bnb);
      return `${toBN(amount).toFixed(4)} BNB`;
    },

    onBuySkill() {
      window.open(this.getExchangeUrl, '_blank');
    },

    async onWithdrawBNB() {
      if(!this.canWithdrawBnb) return;

      await this.withdrawBnbFromWaxBridge();
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

.balance-text {
  color : #BFA765;
}
.add-button {
  width : 30px;
  height: 100%;
}
.add-button:hover {
  cursor: pointer;
}
</style>
