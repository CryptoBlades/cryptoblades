<template>
  <div class="skill-balance-display d-flex flex-column flex-wrap p-2 custom-skill-balance-mobile">
    <div class="d-flex justify-content-end align-items-center pr-2 pb-0">
      <div size="sm" class="my-2 my-sm-0 mr-1 skill-tooltip" variant="primary" v-tooltip="$t('skillBalanceDisplay.buySkillTooltip')" @click="showModal">
        <b-modal size="xl" class="centered-modal " ref="transak-buy" :title="$t('skillBalanceDisplay.buySkillTitle')" ok-only>
          <div class="buy-skill-modal">
            <h4 class="text-center mt-1 mb-4"> {{ $t('skillBalanceDisplay.buyWithCrypto') }} </h4>
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
        <img src="../../assets/add-skill-icon.svg" class="add-button gtag-link-others" :style="isMobile() ? 'width: 20px':''"  tagname="buy_skill">
      </div>
      <div class="d-flex justify-content-between align-items-center balance-container mt-1">
        <div>
          <span v-tooltip="{ content: totalSkillTooltipHtml , trigger: (isMobile() ? 'click' : 'hover') }"
            @mouseover="hover = !isMobile() || true"
            @mouseleave="hover = !isMobile()"
          >{{ formattedTotalSkillBalance }} <b-icon-gift-fill scale="1" v-if="hasInGameSkill" variant="success"/></span>
          <span> SKILL</span>
        </div>
        <div class="mx-2 mb-1">
          <span class="border-line-custom"> | </span>
        </div>
        <div>
          <span>{{getUnclaimed()}}</span>
          <span> UNCLAIMED SKILL</span>
        </div>
      </div>
    </div>
    <div class="d-flex justify-content-end align-items-center">
      <div class="deposit-withdraw px-2">
        <span id="claim-xp-popover" @click="onClaimXp" :class="canClaimXp ? 'claimable' : ''">CLAIM EXP</span>
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
      <div class="deposit-withdraw border-line-custom px-2">
        <span>|</span>
      </div>
      <div class="deposit-withdraw px-2">
        <span @click="claimSkill(ClaimStage.Summary)">WITHDRAW</span>
      </div>
      <div class="deposit-withdraw border-line-custom px-2">
        <span>|</span>
      </div>
      <div class="deposit-withdraw px-2">
        <span @click="showModal">DEPOSIT</span>
      </div>
      <div class="deposit-withdraw border-line-custom px-2" v-if="hasBnbAvailableToWithdraw">
        <span>|</span>
      </div>
      <div>
        <div class="mx-3" v-if="hasBnbAvailableToWithdraw">
          <b-icon-diamond-half scale="1.2"
                            :class="canWithdrawBnb ? 'pointer' : null"
                            :variant="canWithdrawBnb ? 'success' : 'warning'"
                            @click="onWithdrawBNB"
                            v-tooltip.bottom="bnbClaimTooltip" />
        </div>
      </div>
    </div>
    <b-modal class="centered-modal" ref="claim-summary-modal" :title="$t('ClaimRewardsBar.claimRewards')"
      :ok-title="$t('ClaimRewardsBar.claim')" @ok="onClaimTokens()"
      :ok-disabled="(selectedPartneredProject && !canClaimSelectedProject)
        || (!selectedPartneredProject && !canClaimTokens)
        || !isSkillAmountValid">
      <div class="d-flex flex-column align-items-center">
        <div class="d-flex flex-row align-items-center w-100 align-items-baseline">
          <span>{{$t('ClaimRewardsBar.payoutCurrency')}}:</span>
          <b-form-select class="ml-1" size="sm" :value="payoutCurrencyId" @change="updatePayoutCurrencyId($event)">
            <b-form-select-option v-for="p in getPartnerProjects" :key="p.id" :value="p.id">{{p.tokenSymbol}} ({{p.name}})</b-form-select-option>
          </b-form-select>
        </div>
        <div v-if="selectedPartneredProject" class="d-flex mt-2">
          <div class="d-flex justify-content-center align-items-center">
            <h6 class="claim-input-text">{{$t('ClaimRewardsBar.skillAmount')}}:</h6>
            <b-form-input v-bind:class="!isSkillAmountValid ? 'invalid-amount' : ''"
              type="number" min="0" step="0.0001" :max="skillRewardNumber" v-model="skillAmount" class="claim-input" />
            <a class="" @click="setMaxSkillAmount">(Max)</a>
          </div>
          <div class="d-flex justify-content-center align-items-center">
            <h6 class="claim-input-text">{{$t('ClaimRewardsBar.slippage')}} (%):</h6>
            <b-form-input type="number" max="100" step="0.5" v-model="slippage" class="claim-input" />
          </div>
        </div>
        <PartneredProject v-if="selectedPartneredProject" :partnerProject="selectedPartneredProject" :key="selectedPartneredProject.id"/>
        <div class="mt-3" v-if="selectedPartneredProject && !canClaimSelectedProject">
          <h5>{{$t('ClaimRewardsBar.partnerTokenClaimed')}}</h5>
        </div>
        <div v-if="selectedPartneredProject && canClaimSelectedProject" class="mt-3">
          <h6 v-if="formattedMultiplier < 0.5" class="very-low-multiplier">{{$t('ClaimRewardsBar.lowMultiplier', {currentMultiplier})}}</h6>
          <h6 >{{
              $t('ClaimRewardsBar.realWithdrawValueClaimable', {
                actualAmount: (skillAmount / nonFormattedRatio * formattedMultiplier).toFixed(4),
                tokenSymbol: selectedPartneredProject.tokenSymbol,
                skillAmount: (+skillAmount).toFixed(4)
              })
            }}</h6>
        </div>
        <div class="mt-3" v-if="isNoProjectAvailable">
          <h5>{{$t('ClaimRewardsBar.noProjects')}}</h5>
        </div>
      </div>
    </b-modal>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import Bignumber from 'bignumber.js';
import { Accessors } from 'vue/types/options';
import { mapActions, mapState, mapGetters, mapMutations } from 'vuex';
import { toBN, fromWeiEther } from '../../utils/common';
import { formatDurationFromSeconds } from '@/utils/date-time';
import { BModal } from 'bootstrap-vue';
import i18n from '@/i18n';
import {TranslateResult} from 'vue-i18n';
import { ICharacter } from '@/interfaces';
import { getCleanName } from '@/rename-censor';
import ElementTrait from '@/components/smart/ElementTrait.vue';
import { SupportedProject } from '@/views/Treasury.vue';

interface StoreMappedState {
  skillRewards: string;
  skillBalance: string;
  inGameOnlyFunds: string;
  waxBridgeWithdrawableBnb: string;
  waxBridgeTimeUntilLimitExpires: number;
  ownedCharacterIds: string[];
  xpRewards: Record<string, string>;
  payoutCurrencyId: string;
  partnerProjectMultipliers: Record<number, string>;
  partnerProjectRatios: Record<number, string>;
  defaultSlippage: string;
}

interface StoreMappedGetters {
  ownCharacters: ICharacter[];
  getExchangeTransakUrl: string;
  getExchangeUrl: string;
  availableBNB: string;
  currentCharacter: ICharacter | null;
  getCharacterName(id: number): string;
  getPartnerProjects: SupportedProject[];
}

interface StoreMappedActions {
  addMoreSkill(skillToAdd: string): Promise<void>;
  withdrawBnbFromWaxBridge(): Promise<void>;
  claimXpRewards(): Promise<void>;
  fetchPartnerProjects(): Promise<void>;
  fetchRemainingTokenClaimAmountPreTax(): Promise<string>;
  getPartnerProjectMultiplier(id: number): Promise<string>;
  claimPartnerToken(
    {id, skillAmount, currentMultiplier, slippage}:
    {id: number, skillAmount: string, currentMultiplier: string, slippage: string}): Promise<void>;
  claimTokenRewards(): Promise<void>;
}

interface ICharacterClaimableExp{
  id: number;
  name: string;
  traitName: string;
  xp: any;
}

interface StoreMappedMutations{
  updatePayoutCurrencyId(id: string | number): Promise<void>;
}
enum ClaimStage {
  WaxBridge = 0,
  Stake = 1,
  Claim = 2,
  Summary = 3
}

export default Vue.extend({
  data(){
    return{
      ClaimStage,
      remainingTokenClaimAmountPreTax: '0',
      skillAmount: 0,
      slippage: 0,
    };
  },
  computed: {
    ...(mapState(['skillRewards', 'skillBalance', 'inGameOnlyFunds', 'waxBridgeWithdrawableBnb',
      'waxBridgeTimeUntilLimitExpires', 'ownedCharacterIds', 'xpRewards', 'payoutCurrencyId',
      'partnerProjectMultipliers', 'partnerProjectRatios','defaultSlippage']) as Accessors<StoreMappedState>),
    ...(mapGetters({
      availableBNB: 'waxBridgeAmountOfBnbThatCanBeWithdrawnDuringPeriod',
      getExchangeUrl: 'getExchangeUrl',
      getExchangeTransakUrl: 'getExchangeTransakUrl',
      ownCharacters: 'ownCharacters',
      getCharacterName: 'getCharacterName',
      getPartnerProjects: 'getPartnerProjects',
    }) as Accessors<StoreMappedGetters>),
    isNoProjectAvailable(): boolean {
      this.choosePayoutCurrencyIfNotChosenBefore();
      return this.payoutCurrencyId === '-1';
    },
    nonFormattedRatio(): number {
      return this.selectedPartneredProject &&
        +toBN(1).dividedBy(toBN(this.partnerProjectRatios[+this.selectedPartneredProject.id]).dividedBy(toBN(2).exponentiatedBy(64))) || 1;
    },
    formattedMultiplier(): number {
      return this.selectedPartneredProject && +toBN(this.partnerProjectMultipliers[+this.selectedPartneredProject.id]).div(toBN(10).pow(18)).toFixed(4) || 1;
    },
    skillRewardNumber(): number {
      return +toBN(fromWeiEther(this.skillRewards.substr(0, this.skillRewards.length - 3) + '000'));
    },
    isSkillAmountValid(): boolean {
      return this.skillAmount <= this.skillRewardNumber && this.skillAmount > 0;
    },
    canClaimTokens(): boolean {
      const areSkillRewardsZeroOrLess = toBN(this.skillRewards).lte(0);
      const isRemainingTokenClaimAmountPreTaxZeroOrLess = toBN(this.remainingTokenClaimAmountPreTax).lte(0);
      return !(areSkillRewardsZeroOrLess || isRemainingTokenClaimAmountPreTaxZeroOrLess);
    },
    canClaimSelectedProject(): boolean {
      if(this.selectedPartneredProject) {
        return toBN(+this.selectedPartneredProject.tokensClaimed).div(toBN(10).pow(18)).toNumber()
          < toBN(+this.selectedPartneredProject.tokenSupply).toNumber();
      }
      return false;
    },
    selectedPartneredProject(): SupportedProject | undefined {
      console.log(this.getPartnerProjects);
      return this.getPartnerProjects.find(partnerProject => partnerProject.id.toString() === this.payoutCurrencyId.toString());
    },
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
    ...(mapActions(['addMoreSkill', 'withdrawBnbFromWaxBridge',
      'claimXpRewards', 'fetchPartnerProjects', 'fetchRemainingTokenClaimAmountPreTax',
      'getPartnerProjectMultiplier', 'claimPartnerToken', 'claimTokenRewards']) as StoreMappedActions),
    ...(mapMutations(['updatePayoutCurrencyId']) as StoreMappedMutations),
    async onClaimTokens() {
      if(this.payoutCurrencyId !== '-1') {
        const currentMultiplier = await this.getPartnerProjectMultiplier(+this.payoutCurrencyId);
        if(currentMultiplier === '0') {
          (this as any).$dialog.notify.error(i18n.t('ClaimRewardsBar.multiplierAtZero'));
          return;
        }
        await this.claimPartnerToken(
          {
            id: +this.payoutCurrencyId,
            skillAmount: toBN(this.skillAmount).multipliedBy(toBN(10).pow(18)).toString(),
            currentMultiplier: toBN(currentMultiplier).toString(),
            slippage: toBN(this.slippage).multipliedBy(toBN(10).pow(16)).toString()
          }
        );
      }
      else if(this.canClaimTokens) {
        await this.claimTokenRewards();
      }
    },
    async getRemainingTokenClaimAmountPreTax() {
      this.remainingTokenClaimAmountPreTax = await this.fetchRemainingTokenClaimAmountPreTax();
    },
    getUnclaimed(): number | string{
      const skillRewards = fromWeiEther(this.skillRewards);
      if(parseFloat(skillRewards) === 0) return 0;
      return toBN(skillRewards).toFixed(4);
    },
    async claimSkill(stage: ClaimStage) {
      if(stage === ClaimStage.WaxBridge) {
        (this.$refs['need-gas-modal'] as any).show();
      }
      if(stage === ClaimStage.Stake) {
        (this.$refs['stake-suggestion-modal'] as any).show();
      }
      if(stage === ClaimStage.Claim) {
        (this.$refs['stake-suggestion-modal'] as any).hide();
        (this.$refs['claim-confirmation-modal'] as any).show();
      }
      if(stage === ClaimStage.Summary) {
        await this.fetchPartnerProjects();
        this.skillAmount = this.skillRewardNumber;
        this.slippage = +toBN(this.defaultSlippage).dividedBy(toBN(10).pow(16));
        (this.$refs['claim-summary-modal'] as any).show();
      }
      await this.getRemainingTokenClaimAmountPreTax();
    },
    choosePayoutCurrencyIfNotChosenBefore() {
      const supportedProjects = this.getPartnerProjects;
      if(this.payoutCurrencyId === '-1' && supportedProjects.length !== 0) {
        this.updatePayoutCurrencyId(supportedProjects[0].id);
      }
    },
    setMaxSkillAmount(): void {
      this.skillAmount = this.skillRewardNumber;
    },
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
@media (max-width: 576px) {
  .custom-skill-balance-mobile{
    font-size: 13px !important;
    border-left: 1px solid #424A59;
  }
  .none-mobile {
    display: none !important;
  }
}
.claimable {
  text-align: center;
  animation: claimable 1s ease-in-out infinite alternate;
}

@keyframes claimable {
  from {
    text-shadow: 0 0 10px #fff, 0 0 20px #fff, 0 0 30px #e4b322, 0 0 40px #e4b322, 0 0 50px #e4b322, 0 0 60px #e4b322, 0 0 70px #e4b322;
  }
  to {
    text-shadow: 0 0 20px #fff, 0 0 30px #ffc107, 0 0 40px #ffc107, 0 0 50px #ffc107, 0 0 60px #ffc107, 0 0 70px #ffc107, 0 0 80px #ffc107;
  }
}
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
  border-right: 1px solid #424A59;
}

.skill-tooltip > img{
  top: 0;
  left: 0;
}

.transaction-btn{
  flex: 100%;
  text-align: center;
}

.balance-container {
  color: #b3b0a7;
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
