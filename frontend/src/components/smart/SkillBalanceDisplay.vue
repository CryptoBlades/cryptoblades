<template>
  <div class="skill-balance-display">
    <div class="balance-icon-container">
      <div size="sm" class="my-2 my-sm-0 mr-3 skill-tooltip" variant="primary" v-tooltip="$t('skillBalanceDisplay.buySkillTooltip')" @click="showModal">
        <b-modal size="xl" class="centered-modal " ref="transak-buy" :title="$t('skillBalanceDisplay.buySkillTitle')" ok-only>
          <div class="buy-skill-modal">
            <h4 class="text-center  mt-1 mb-4"> {{ $t('skillBalanceDisplay.buyWithCrypto') }} </h4>
            <iframe
              class="iframe"
              :src="getExchangeUrl"
            />
            <h4 v-if="getExchangeTransakUrl" class="text-center mt-4 mb-4"> {{ $t('skillBalanceDisplay.buyWithFiat') }} </h4>
            <iframe
              class="iframe"
              :src="getExchangeTransakUrl"
              v-if="getExchangeTransakUrl"
            />
          </div>
        </b-modal>
        <img src="../../assets/navbar-icons/skill-token.png" class="add-button gtag-link-others" :style="isMobile() ? 'width:35px':''"  tagname="buy_skill">
      </div>

      <div class="balance-container">
        <p>$SKILL </p>
        <b v-tooltip="{ content: totalSkillTooltipHtml , trigger: (isMobile() ? 'click' : 'hover') }"
           @mouseover="hover = !isMobile() || true"
           @mouseleave="hover = !isMobile()"
        >{{ formattedTotalSkillBalance }} <b-icon-gift-fill scale="1" v-if="hasInGameSkill" variant="success"/></b>
      </div>
    </div>

    <div class="deposit-withdraw">
      <span @click="showModal">Deposit</span>
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
import { BModal } from 'bootstrap-vue';
import i18n from '@/i18n';
import {TranslateResult} from 'vue-i18n';

type StoreMappedState = Pick<IState, 'skillRewards' | 'skillBalance' | 'inGameOnlyFunds' | 'waxBridgeWithdrawableBnb' | 'waxBridgeTimeUntilLimitExpires'>;

interface StoreMappedGetters {
  getExchangeTransakUrl: string;
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
      getExchangeUrl: 'getExchangeUrl',
      getExchangeTransakUrl: 'getExchangeTransakUrl'
    }) as Accessors<StoreMappedGetters>),

    formattedTotalSkillBalance(): string {
      const skillBalance = fromWeiEther(Bignumber.sum(toBN(this.skillBalance), toBN(this.inGameOnlyFunds), toBN(this.skillRewards)));

      return `${toBN(skillBalance).toFixed(4)}`;
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

    bnbClaimTooltip(): TranslateResult {
      if(!this.canWithdrawBnb) {
        return i18n.t('skillBalanceDisplay.reachedPortalLimit', {
          durationUntilLimitPeriodOver : this.durationUntilLimitPeriodOver,
          formattedTotalAvailableBnb : this.formattedTotalAvailableBnb,
        });
      }

      return i18n.t('skillBalanceDisplay.withdrawablePortal', {
        formattedBnbThatCanBeWithdrawn : this.formattedBnbThatCanBeWithdrawn,
        formattedTotalAvailableBnb : this.formattedTotalAvailableBnb,
      });
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
        html += i18n.t('skillBalanceDisplay.withdrawable') + toBN(skillRewards).toFixed(4) + ' SKILL';
      }

      if(parseFloat(inGameOnlyFundsBalance) !== 0){
        html += i18n.t('skillBalanceDisplay.igo') + toBN(inGameOnlyFundsBalance).toFixed(4) + ' SKILL';
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
    async onWithdrawBNB() {
      if(!this.canWithdrawBnb) return;

      await this.withdrawBnbFromWaxBridge();
    },
    showModal() {
      (this.$refs['transak-buy'] as BModal).show();
    }
  },

  components: {
    BModal
  }
});
</script>

<style scoped>
.skill-balance-display {
  align-items: center;
  border-left: 1px solid #424A59;
  border-right: 1px solid #424A59;
  padding: 0.5rem;
  flex-direction: column;
  height: 100%;
  justify-content: space-between;
}

.skill-tooltip > img{
  top: 0;
  left: 0;
}

.transaction-btn{
  flex: 100%;
  text-align: center;
}

.balance-icon-container {
  display: flex;
  align-items: center;
}

.balance-container {
  color: #b3b0a7;
  line-height: 0.2;
  text-align: right;
}

.deposit-withdraw > span{
  line-height: 10px;
}

.deposit-withdraw > span:nth-child(2) {
  color : gray;
}

.deposit-withdraw > span {
  color: #EDCD90;
  cursor: pointer;
}
.balance-text {
  color : #BFA765;
}
.add-button {
  height: 2rem;
  position: relative;
  top: -15px;
  right: -15px;
}

.add-button:hover {
  cursor: pointer;
}
.iframe{
  min-height: 850px;
  width: 100%;
}

</style>
