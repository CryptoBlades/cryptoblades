<template>
  <div class="skill-balance-display">
    <div size="sm" class="my-2 my-sm-0 mr-3 skill-tooltip" variant="primary" v-tooltip="$t('skillBalanceDisplay.buySkillTooltip')" @click="showModal">
      <b-modal size="xl" class="centered-modal " ref="transak-buy" :title="$t('skillBalanceDisplay.buySkillTitle')" ok-only>
        <div class="buy-skill-modal">
          <div class="buy-skill-modal-child">
          <img src="../../assets/apeswapbanana.png" class="img-apeswap"  tagname="buy_skill">
                <b-button variant="primary" class="gtag-link-others" @click="onBuySkill">{{$t('skillBalanceDisplay.buyWithCrypto')}}</b-button>
          </div>
          <div class="buy-skill-modal-child">
                <img src="../../assets/logoTransak.png" class="img-transak"  tagname="buy_skill_test">
                <b-button variant="primary" class="gtag-link-others" @click="onBuyTransak">{{$t('skillBalanceDisplay.buyWithFiat')}}</b-button>
          </div>
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
    <div class="transaction-btn">
        <div class="deposit-withdraw">
        <!-- new withdraw/claim on new ui -->
         <!-- <span @click="showModal">Deposit</span> | <span @click="claimSkill(ClaimStage.Summary)"> Withdraw </span> -->
         <span @click="showModal">Deposit</span>
        </div>
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

    onBuySkill() {
      window.open(this.getExchangeUrl, '_blank');
    },
    onBuyTransak() {
      window.open(this.getExchangeTransakUrl, '_blank');
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
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.1rem;
  border-left: 1px solid #424A59;
  height: 105px;
  border-right: 1px solid #424A59;
  padding-left : 15px;
  padding-right: 15px;
  flex-wrap: wrap;
}

.skill-tooltip > img{
  top: 0px;
  left: 0px;
}

.transaction-btn{
  flex: 100%;
  text-align: center;
}

.balance-container {
  margin-right: 5px;
  color: #b3b0a7;
  line-height: 0.2;
  text-align: right;
}
.deposit-withdraw {
  flex: 100%;
  margin-top: -25px;
  color: rgba(255, 255, 255, 0.364);

  /* margin-top: 25px;
  position: relative;
  right: 35px; */
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
  width: 45px;
  height: 100%;
  position: relative;
  top: -15px;
  right: -15px;
}
.skill-tooltip {
  width: 70px;
}
.add-button:hover {
  cursor: pointer;
}
.buy-skill-modal {
  display: flex;
  justify-content: space-between;
}
.buy-skill-modal-child{
  width: 50%;
  height: 300px;
  align-items: center;
  justify-content: space-between;
  margin: 10%;
  display: flex;
  flex-direction: column;
}
.img-apeswap, .img-transak {
  width:100%;
  max-width: 250px;
  height: auto;
  margin-bottom: 30px;
}

</style>
