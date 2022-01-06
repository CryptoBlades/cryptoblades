<template>
  <div class="body main-font">
    <b-navbar v-if="isBar">
      <b-icon-exclamation-circle-fill class="rewards-claimable-icon" scale="1.2"
      variant="success" :hidden="!canClaimTokens && !canClaimXp" v-tooltip.bottom="$t('ClaimRewardsBar.readyToClaim')"/>

      <b-nav-item class="bar" disabled><strong>{{$t('ClaimRewardsBar.rewards')}}</strong></b-nav-item>

      <b-nav-item
        class="ml-3 bar"
        @click="claimSkill(ClaimStage.Summary)"><!-- moved gtag-link below b-nav-item -->
        <span class="gtag-link-others" tagname="claim_skill" v-tooltip.bottom="$t('ClaimRewardsBar.clickDetails')">
          <strong>SKILL</strong> {{ formattedSkillReward }}
        </span>
      </b-nav-item>

      <b-nav-item
        class="ml-3 bar"
        :disabled="!canClaimXp"
        @click="onClaimXp">
          <div class="gtag-link-others" v-html="`<strong>XP</strong> ${formattedXpRewardsBar}`"></div>
      </b-nav-item>
    </b-navbar>

    <b-navbar-nav v-if="!isBar">
      <b-icon-exclamation-circle-fill class="rewards-claimable-icon" scale="1.2"
      variant="success" :hidden="!canClaimTokens && !canClaimXp" v-tooltip.bottom="'Rewards ready to claim!'" />

      <b-nav-item-dropdown right>
        <template #button-content>
          {{$t('ClaimRewardsBar.rewards')}}
        </template>

        <b-dropdown-item
          @click="claimSkill(ClaimStage.Summary)" class="rewards-info gtag-link-others" tagname="claim_skill"
           v-tooltip.bottom="$t('ClaimRewardsBar.clickDetails')">
            SKILL
            <div class="pl-3">{{ formattedSkillReward }}</div>
        </b-dropdown-item>

        <b-dropdown-item
          :disabled="!canClaimXp"
          @click="onClaimXp" class="gtag-link-others" tagname="claim_xp">
            XP <div class="pl-3" v-for="(reward, index) in formattedXpRewards" :key="index">{{ reward }}</div>
        </b-dropdown-item>
      </b-nav-item-dropdown>
    </b-navbar-nav>

    <b-modal class="centered-modal" ref="need-gas-modal" title="Need Withdraw?"
      @ok="claimSkill(ClaimStage.Stake)" ok-title="Next" @cancel="$router.push({ name: 'portal' })" cancel-title="Go to WAX Portal" >
        Need Withdraw? Try our WAX Portal, which will pay you .5% under market rate to sell your WAX for BNB!
        <div class="text-center">
          <hr class="hr-divider">
          {{$t('needGasModal.holdReminder')}}<br>
          <span v-html="$t('needGasModal.holdReminderText')"></span>
          <div class="row">
            <div class="col-5">{{$t('needGasModal.yourTax')}}</div>
            <div class="col-2"><span class="text-danger font-weight-bold">{{formattedRewardsClaimTax}}</span></div>
            <div class="col-5 text-left">{{$t('needGasModal.reduces1')}}<br>
              {{$t('needGasModal.reduces2')}}</div>
          </div>
        </div>
    </b-modal>
    <b-modal class="centered-modal" ref="stake-suggestion-modal" :title="$t('stakeModal.title')"
      @ok="$router.push({ name: 'select-stake-type' })"
      :ok-title="$t('stakeModal.okTitle')"
      :cancel-title="$t('stakeModal.cancelTitle')"
      >
        {{$t('stakeModal.stakeText')}}
      <a href="#" @click="claimSkill(ClaimStage.Claim)">
      <br>
      <span v-if="(this.rewardsClaimTaxAsFactorBN > 0)">{{$t('stakeModal.bonusWarning1')}}</span>
      <span v-else>{{$t('stakeModal.bonusWarning2', {formattedTaxAmount : this.formattedTaxAmount})}}</span>      </a>
    </b-modal>
    <b-modal class="centered-modal" ref="claim-confirmation-modal"
    :title="$t('stakeModal.confirmModal.title')"
    :ok-title="$t('stakeModal.confirmModal.okTitle')"
    :cancel-title="$t('stakeModal.confirmModal.cancelTitle')"
    @ok="onClaimTokens()">
      <span v-if="(this.rewardsClaimTaxAsFactorBN > 0)">
        {{$t('stakeModal.confirmModal.claimWarning2', {
          formattedRewardsClaimTax,
          formattedTaxAmount : this.formattedTaxAmount,
          formattedBonusLost
          } )}}
      </span>
      <span v-else>
        {{$t('stakeModal.confirmModal.claimWarning1', {formattedBonusLost})}}
      </span>
      <b>{{$t('stakeModal.confirmModal.cantBeUndone')}}</b>
    </b-modal>
    <b-modal class="centered-modal" ref="claim-summary-modal" :title="$t('ClaimRewardsBar.claimRewards')"
      :ok-title="$t('ClaimRewardsBar.claim')" @ok="onClaimTokens()"
      :ok-disabled="(selectedPartneredProject && !canClaimSelectedProject)
        || (!selectedPartneredProject && !canClaimTokens)
        || !isSkillAmountValid">
      <div class="d-flex flex-column align-items-center">
        <div class="d-flex flex-row w-100 align-items-baseline">
          <h5>{{$t('ClaimRewardsBar.payoutCurrency')}}:</h5>
          <b-form-select class="w-50 ml-1" size="sm" :value="payoutCurrencyId" @change="updatePayoutCurrencyId($event)">
            <b-form-select-option v-if="currentNetworkId !== 56" :value="'-1'">SKILL</b-form-select-option>
            <b-form-select-option v-for="p in supportedProjects" :key="p.id" :value="p.id">{{p.tokenSymbol}} ({{p.name}})</b-form-select-option>
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
        <partnered-project v-if="selectedPartneredProject"
          :id="selectedPartneredProject.id" :name="selectedPartneredProject.name"
          :tokenSymbol="selectedPartneredProject.tokenSymbol" :tokenSupply="selectedPartneredProject.tokenSupply"
          :tokenPrice="selectedPartneredProject.tokenPrice" :logoFileName="getLogoFile(selectedPartneredProject.name)"
          :tokenAddress="selectedPartneredProject.tokenAddress"/>
        <div class="mt-3" v-if="selectedPartneredProject && !canClaimSelectedProject">
          <h5>{{$t('ClaimRewardsBar.partnerTokenClaimed')}}</h5>
        </div>
        <div class="mt-3" v-if="!selectedPartneredProject">
          <h5>{{withdrawalInfoText}}</h5>
          <h6>{{$t('ClaimRewardsBar.earlyWithdrawTax')}}: {{ formattedRewardsClaimTax }} {{$t('ClaimRewardsBar.taxReduce')}} {{getTaxTimerNextTick}}</h6>
        </div>
      </div>
    </b-modal>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import { Accessors } from 'vue/types/options';
import { mapActions, mapGetters, mapMutations, mapState } from 'vuex';
import BigNumber from 'bignumber.js';
import { RequiredXp } from '../../interfaces';
import { ICharacter } from '@/interfaces';
import { toBN, fromWeiEther } from '../../utils/common';
import { secondsToDDHHMMSS } from '../../utils/date-time';
import { getCleanName } from '../../rename-censor';
import { SupportedProject } from '@/views/Treasury.vue';
import PartneredProject from '../PartneredProject.vue';
import i18n from '@/i18n';

interface StoreMappedState {
  skillRewards: string;
  xpRewards: Record<string, string>;
  ownedCharacterIds: string[];
  directStakeBonusPercent: number;
  payoutCurrencyId: string;
  defaultSlippage: string;
  currentNetworkId: number;
}

interface StoreMappedGetters {
  ownCharacters: ICharacter[];
  currentCharacter: ICharacter | null;
  maxRewardsClaimTaxAsFactorBN: BigNumber;
  rewardsClaimTaxAsFactorBN: BigNumber;
  getCharacterName(id: number): string;
  getPartnerProjects: SupportedProject[];
}

enum ClaimStage {
  WaxBridge = 0,
  Stake = 1,
  Claim = 2,
  Summary = 3
}

interface StoreMappedActions {
  claimTokenRewards(): Promise<void>;
  claimPartnerToken(
    {id, skillAmount, currentMultiplier, slippage}:
    {id: number, skillAmount: string, currentMultiplier: string, slippage: string}): Promise<void>;
  claimXpRewards(): Promise<void>;
  fetchRemainingTokenClaimAmountPreTax(): Promise<string>;
  fetchPartnerProjects(): Promise<void>;
  getPartnerProjectMultiplier(id: number): Promise<string>;
}

export default Vue.extend({
  components: { PartneredProject },

  props: {
    isBar: {
      type: Boolean,
      default: true
    }
  },

  data() {
    return {
      ClaimStage,
      remainingTokenClaimAmountPreTax: '0',
      skillAmount: 0,
      slippage: 0
    };
  },

  computed: {
    ...(mapState(['skillRewards', 'xpRewards', 'ownedCharacterIds', 'directStakeBonusPercent',
      'payoutCurrencyId', 'defaultSlippage', 'currentNetworkId']) as Accessors<StoreMappedState>),
    ...(mapGetters([
      'ownCharacters', 'currentCharacter', 'maxRewardsClaimTaxAsFactorBN', 'rewardsClaimTaxAsFactorBN', 'getCharacterName', 'getPartnerProjects'
    ]) as Accessors<StoreMappedGetters>),

    formattedSkillReward(): string {
      const skillRewards = fromWeiEther(this.skillRewards);
      return `${toBN(skillRewards).toFixed(4)}`;
    },

    formattedTaxAmount(): string {
      const skillRewards = fromWeiEther((parseFloat(this.skillRewards)* parseFloat(String(this.rewardsClaimTaxAsFactorBN))).toString());
      return `${toBN(skillRewards).toFixed(4)}`;
    },

    formattedBonusLost(): string {
      const skillLost = fromWeiEther((parseFloat(this.skillRewards)*this.directStakeBonusPercent/100).toString());
      return `${toBN(skillLost).toFixed(4)}`;
    },

    formattedRemainingClaimableSkill(): string {
      const skillClaimable = fromWeiEther(this.remainingTokenClaimAmountPreTax);
      return `${toBN(skillClaimable).toFixed(4)}`;
    },

    formattedRewardsClaimTax(): string {
      const frac =
        this.skillRewards === '0'
          ? this.maxRewardsClaimTaxAsFactorBN
          : this.rewardsClaimTaxAsFactorBN;

      return `${frac.multipliedBy(100).decimalPlaces(0, BigNumber.ROUND_HALF_UP)}%`;
    },

    getTaxTimerNextTick(): string {
      let frac: BigNumber;

      // if has no skill rewards do not display timer next tick.
      // or if tax is zero also do not display timer next tick.
      if (this.skillRewards === '0' || this.rewardsClaimTaxAsFactorBN.toString() === '0') {
        return '';
      } else {
        frac = this.rewardsClaimTaxAsFactorBN;
      }

      // get 2 decimal values
      const decVal = toBN(frac.multipliedBy(100).decimalPlaces(2).toString().split('.')[1]);
      // convert to seconds
      const toSec = decVal.dividedBy(100).multipliedBy(24).multipliedBy(60).multipliedBy(60);
      // return message
      return ` Next -1% reduction happens in ${secondsToDDHHMMSS(toSec.toNumber())}.`;
    },

    skillRewardNumber(): number {
      return +toBN(fromWeiEther(this.skillRewards)).toFixed(17);
    },

    withdrawalInfoText(): string {
      if(this.skillRewardNumber >= 1) {
        return `${i18n.t('ClaimRewardsBar.withdrawalInfoText1')} ${this.formattedRemainingClaimableSkill}`;
      }
      return `${i18n.t('ClaimRewardsBar.withdrawalInfoText2')} ${this.formattedRemainingClaimableSkill}`;
    },

    xpRewardsForOwnedCharacters(): string[] {
      return this.ownedCharacterIds.map(charaId => this.xpRewards[charaId] || '0');
    },

    formattedXpRewardsBar(): string {
      return this.xpRewardsForOwnedCharacters.map((xp, i) => {
        const currentCharacter = this.currentCharacter || { id: null };
        if(!this.ownCharacters[i]) return `${xp}`;
        return  `${this.ownCharacters[i].id === currentCharacter.id ? '<b>' : ''}` +
                `${(this.ownCharacters[i].xp + this.xpRewards[this.ownCharacters[i].id]) as any > RequiredXp(this.ownCharacters[i].level) ? '<u>' : ''}` +
                `${(this.getCleanCharacterName(this.ownCharacters[i].id))} ${xp}` +
                `${(this.ownCharacters[i].xp + this.xpRewards[this.ownCharacters[i].id]) as any > RequiredXp(this.ownCharacters[i].level) ? '</u>' : ''}` +
                `${this.ownCharacters[i].id === currentCharacter.id ? '</b>' : ''}`;
      }).join(', ');
    },

    formattedXpRewards(): string[] {
      return this.xpRewardsForOwnedCharacters.map((xp, i) => {
        if(!this.ownCharacters[i]) return xp;

        return `${this.getCleanCharacterName(this.ownCharacters[i].id)} ${xp}`;
      });
    },

    canClaimTokens(): boolean {
      if(toBN(this.skillRewards).lte(0) || toBN(this.remainingTokenClaimAmountPreTax).lte(0)) {
        return false;
      }

      return true;
    },

    canClaimXp(): boolean {
      const allXpsAreZeroOrLess = this.xpRewardsForOwnedCharacters.every(xp => toBN(xp).lte(0));
      if(allXpsAreZeroOrLess) {
        return false;
      }

      return true;
    },

    supportedProjects(): SupportedProject[] {
      const supportedProjects = this.getPartnerProjects.map(p => {
        return {
          id: p.id,
          name: p.name,
          tokenSymbol: p.tokenSymbol,
          tokenAddress: p.tokenAddress,
          tokenSupply: p.tokenSupply,
          tokensClaimed: p.tokensClaimed,
          tokenPrice: p.tokenPrice,
          isActive: p.isActive
        };
      });

      return supportedProjects;
    },

    selectedPartneredProject(): SupportedProject | undefined {
      return this.supportedProjects.find(x => x.id === this.payoutCurrencyId);
    },

    canClaimSelectedProject(): boolean {
      if(this.selectedPartneredProject) {
        return toBN(+this.selectedPartneredProject.tokensClaimed).div(toBN(10).pow(18)).toNumber()
          < toBN(+this.selectedPartneredProject.tokenSupply).toNumber();
      }
      return false;
    },

    isSkillAmountValid(): boolean {
      return this.skillAmount <= this.skillRewardNumber && this.skillAmount > 0;
    }
  },

  methods: {
    ...(mapActions(['addMoreSkill', 'claimTokenRewards', 'claimPartnerToken', 'claimXpRewards', 'fetchRemainingTokenClaimAmountPreTax',
      'fetchPartnerProjects', 'getPartnerProjectMultiplier']) as StoreMappedActions),
    ...mapMutations(['updatePayoutCurrencyId']),

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

    async onClaimXp() {
      if(this.canClaimXp) {
        await this.claimXpRewards();
      }
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

    async getRemainingTokenClaimAmountPreTax() {
      this.remainingTokenClaimAmountPreTax = await this.fetchRemainingTokenClaimAmountPreTax();
    },

    getCleanCharacterName(id: number): string {
      return getCleanName(this.getCharacterName(id));
    },

    getLogoFile(projectName: string): string {
      return `${projectName.toLowerCase()}.png`;
    },

    setMaxSkillAmount(): void {
      this.skillAmount = this.skillRewardNumber;
    }
  },

  async mounted() {
    setInterval(async () => await this.getRemainingTokenClaimAmountPreTax(), 3000);
  }
});
</script>

<style scoped>

.navbar {
  background: rgb(20,20,20);
  background: linear-gradient(45deg, rgba(20,20,20,1) 0%, rgba(36,39,32,1) 100%);
}

.nav-item.bar {
  margin-top: -24px;
}

.nav-item a {
  padding: 0;
}

.rewards-claimable-icon {
  margin-right: 5px;
  align-self: center;
}

.claim-input {
  max-height: 60%;
  max-width: 40%;
  margin-left: 5px;
}

.claim-input-text {
  margin-bottom: -1px;
}

.invalid-amount {
  border: 2px solid red;
}
</style>
