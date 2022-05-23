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

    <div class="d-flex justify-content-between align-items-center">
      <div class="deposit-withdraw p-2">
        <span id="claim-xp-popover" @click="canClaimXp ? onClaimXp : ''">CLAIM EXP</span>
        <b-popover target="claim-xp-popover" custom-class="claim-exp-popover" triggers="hover" placement="bottom">
          <img class="position-absolute mt-1" width="233" :src="require('@/assets/separator.png')" />
          <div class="d-flex justify-content-center position-relative">
            <div>
              <img width="40" :src="require('@/assets/fight-result-header.png')" />
            </div>
          </div>
          <div class="d-flex flex-column pb-1">
            <div class="d-flex justify-content-between">
              <div class="px-2 custom-header-font">Character Name</div>
              <div class="px-3"></div>
              <div class="px-2 custom-header-font">Unclaimed EXP</div>
            </div>
          </div>
          <div class="d-flex flex-column" v-for="charXp in formattedXpRewardsBar" :key="charXp.id">
            <div class="d-flex justify-content-between align-items-center">
              <div class="p-2 character-name">
                <element-trait class="mr-1" :width="15" :traitName="charXp.traitName"></element-trait>{{ charXp.name }}
              </div>
              <div class="px-3"></div>
              <div class="p-2">
                <b>{{ charXp.xp }}</b>
              </div>
            </div>
          </div>
          <img width="230" :src="require('@/assets/separator.png')" />
        </b-popover>
      </div>
      <div class="deposit-withdraw border-line-custom p-1">
        <span>|</span>
      </div>
      <div class="deposit-withdraw p-2">
        <span @click="showModal">DEPOSIT</span>
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
import { formatDurationFromSeconds } from '@/utils/date-time';
import { BModal } from 'bootstrap-vue';
import i18n from '@/i18n';
import {TranslateResult} from 'vue-i18n';
import { ICharacter } from '@/interfaces';
import { getCleanName } from '@/rename-censor';
import ElementTrait from '@/components/smart/ElementTrait.vue';

interface StoreMappedState {
  skillRewards: string;
  skillBalance: string;
  inGameOnlyFunds: string;
  waxBridgeWithdrawableBnb: string;
  waxBridgeTimeUntilLimitExpires: number;
  ownedCharacterIds: string[];
  xpRewards: Record<string, string>;
}

interface StoreMappedGetters {
  ownCharacters: ICharacter[];
  getExchangeTransakUrl: string;
  getExchangeUrl: string;
  availableBNB: string;
  currentCharacter: ICharacter | null;
  getCharacterName(id: number): string;
}

interface StoreMappedActions {
  addMoreSkill(skillToAdd: string): Promise<void>;
  withdrawBnbFromWaxBridge(): Promise<void>;
  claimXpRewards(): Promise<void>;
}

interface ICharacterClaimableExp{
  id: number;
  name: string;
  traitName: string;
  xp: any;
}


export default Vue.extend({
  computed: {
    ...(mapState(['skillRewards', 'skillBalance', 'inGameOnlyFunds', 'waxBridgeWithdrawableBnb',
      'waxBridgeTimeUntilLimitExpires', 'ownedCharacterIds', 'xpRewards']) as Accessors<StoreMappedState>),
    ...(mapGetters({
      availableBNB: 'waxBridgeAmountOfBnbThatCanBeWithdrawnDuringPeriod',
      getExchangeUrl: 'getExchangeUrl',
      getExchangeTransakUrl: 'getExchangeTransakUrl',
      ownCharacters: 'ownCharacters',
      getCharacterName: 'getCharacterName'
    }) as Accessors<StoreMappedGetters>),
    formattedXpRewardsBar(): ICharacterClaimableExp[] {
      const characterXp: ICharacterClaimableExp[] = [];
      this.xpRewardsForOwnedCharacters.map((xp, i) => {
        const character = this.ownCharacters[i];
        if (character) {
          characterXp.push({
            id: character.id,
            traitName: character.traitName,
            name: this.getCleanCharacterName(character.id),
            xp
          });
        }
      });
      return characterXp;
    },

    canClaimXp(): boolean {
      const areAllXpsZeroOrLess = this.xpRewardsForOwnedCharacters.every(xp => toBN(xp).lte(0));
      return !areAllXpsZeroOrLess;
    },
    xpRewardsForOwnedCharacters(): string[] {
      return this.ownedCharacterIds.map(charaId => this.xpRewards[charaId] || '0');
    },
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
    ...(mapActions(['addMoreSkill', 'withdrawBnbFromWaxBridge', 'claimXpRewards']) as StoreMappedActions),
    getCleanCharacterName(id: number): string {
      return getCleanName(this.getCharacterName(id));
    },
    async onClaimXp() {
      if(this.canClaimXp) {
        await this.claimXpRewards();
      }
    },
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
    BModal,
    ElementTrait
  }
});
</script>

<style scoped>
.custom-header-font{
  font-family: 'Roboto', sans-serif;
  font-size: 12px;
}
.claim-exp-popover{
  font-family: 'Trajan' !important;
  background: rgba(33,35,30, .7);
}
.unclaimed-text{
  color: #ffc107;
  font-size: 13px;
}
.character-name{
  font-family: 'Trajan';
}
::v-deep.claim-exp-popover .popover-body {
  color: #fff !important;
}
.border-line-custom{
  font-size: 13px;
}
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
