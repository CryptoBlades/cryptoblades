<template>
  <div class="container">
    <h1 class="stake-type-title">{{ stakeTitle }}
      <b-icon-question-circle-fill v-if="deprecated"
        v-tooltip="$t('stake.StakeSelectorItem.deprecatedTooltip')" />
    </h1>

    <div class="stake-stats">
      <div class="stake-stats-item">
        <div class="stake-stats-item-title">{{ $t('stake.StakeSelectorItem.earn') }}</div>
        <div class="stake-stats-item-value">{{ rewardTokenName }}</div>
      </div>
      <div class="stake-stats-item">
        <div class="stake-stats-item-title">{{ isNftStaking ? $t('stake.StakeSelectorItem.yield') : $t('stake.StakeSelectorItem.apy') }}</div>
        <div class="stake-stats-item-value">
          {{ isNftStaking ? estimatedYield.toFixed(2) : estimatedYield.multipliedBy(100).toFixed(2) }}
          {{ isNftStaking ? '/NFT' : '%' }}
        </div>
      </div>
      <div class="stake-stats-item">
        <div class="stake-stats-item-title">{{ $t('stake.StakeSelectorItem.stakeLocked') }}</div>
        <div class="stake-stats-item-value">{{ minimumStakeTime !== 0 ? minimumStakeTimeFormatted: 'No Lock' }}</div>
      </div>
      <div class="stake-stats-item" v-if="rewardsDuration !== 0">
        <div class="stake-stats-item-title">{{ $t('stake.StakeSelectorItem.rewardsDuration') }}</div>
        <div class="stake-stats-item-value">{{ rewardsDurationFormatted }}</div>
      </div>
    </div>
    <div class="stats-row">
      <div class="stats-col">
        <div class="stake-stats-item-title">{{ $t('stake.StakeSelectorItem.totalStaked') }}</div>
        <div class="stake-stats-item-value">{{ totalStakedFormatted }} {{stakeTokenName}}</div>
      </div>
      <div class="stats-col">
        <div class="stake-stats-item-title">{{ $t('stake.StakeSelectorItem.staked') }}</div>
        <div class="stake-stats-item-value">{{ stakedBalanceFormatted }} {{stakeTokenName}}</div>
      </div>
      <div class="stats-col">
        <div class="stake-stats-item-title">{{ $t('stake.StakeSelectorItem.availableInWallet') }}</div>
        <div class="stake-stats-item-value">{{ walletBalanceFormatted }} {{stakeTokenName}}</div>
      </div>
    </div>
    <div class="claim-rewards-wrapper">
      <div class="claim-rewards">
        <div>
          <div class="stake-stats-item-title">{{ $t('stake.StakeSelectorItem.rewards') }}</div>
          <div class="stake-stats-item-value">{{currentRewardEarnedFormatted}} {{rewardTokenName}}</div>
        </div>
        <div class="claim-rewards-btns">
          <button class="stake-button claim-reward-btn"
            @click="onClaimReward"
            :disabled="rewardClaimState !== 'ok' || !showRewardClaimSection"
            data-toggle="tooltip" data-placement="right" :title="claimRewardButtonLabel"
            >{{ $t('stake.StakeSelectorItem.claim') }}
          </button>
        </div>
      </div>
      <div class="progressBarWrapper"
        :style="(progressBarWidth === 100 && {opacity:0})">
          <div
            class="progressBar"
            :style="{
              width: progressBarWidth + '%',
            }"
          ></div>
          <span>{{estimatedUnlockTimeLeftFormatted}}</span>
      </div>
    </div>
    <div class="stake-buttons">
      <button class="stake-button"
        @click="isDeposit = startedStaking = true"
        :class="{ btn_active: (isDeposit&&startedStaking) }"
        >
        {{ $t('stake.StakeSelectorItem.stake') }}
        </button>
      <button class="stake-button"
        @click="isDeposit = false; startedStaking = true"
        :class="{ btn_active: (!isDeposit&&startedStaking) }"
        >
        {{ $t('stake.StakeSelectorItem.unstake') }}
        </button>
    </div>
    <div class="divider"></div>
    <div class="inputSection" v-if="startedStaking">
      <!-- Input for stake amount -->
      <input
        v-if="!isNftStaking && currentState !== currentState.stakeLocked"
        class="token-amount-input text-center"
        inputmode="decimal"
        :title="$t('stake.tokenAmount')"
        autocomplete="off"
        autocorrect="off"
        type="text"
        pattern="^[0-9]*[.,]?[0-9]*$"
        placeholder="0.0"
        minlength="1"
        maxlength="39"
        spellcheck="false"
        value=""
        v-model="textAmount"
      />
      <div v-if="!isNftStaking && currentState !== currentState.stakeLocked" class="input-ratio-buttons">
        <button class="stake-button ratio-button" @click="inputByRatio(0.25)">25%</button>
        <button class="stake-button ratio-button" @click="inputByRatio(0.50)">50%</button>
        <button class="stake-button ratio-button" @click="inputByRatio(0.75)">75%</button>
        <button class="stake-button ratio-button" @click="inputByRatio(1)">{{ $t('stake.StakeSelectorItem.max') }}</button>
      </div>

      <!-- Input staking NFTs  && ownedLandIds && stakedIds -->
      <multiselect v-if="isNftStaking" class="multiselect" v-model="idsToStake"
        :options="(isDeposit ? ownedLandIds : stakedIds).filter(x => +x.tier === +tier || !tier) || []"
        :max="10" :multiple="true" :close-on-select="false" :clear-on-select="false" :placeholder="$t('stake.pickId')"
        :custom-label="idWithTier" track-by="id"
        tagPosition="bottom">
        <template slot="selection" :slot-scope="{ idsToStake }">
          <span class="multiselect__single" v-if="idsToStake && idsToStake.length">{{ idsToStake.length }} {{$t('stake.idsSelected')}}</span>
        </template>
        <template slot="noOptions">
          <span>{{(isDeposit ? $t('stake.StakeSelectorItem.noLandStaked') : $t('stake.StakeSelectorItem.noLandToStake'))}}</span>
        </template>
      </multiselect>
      <button class="stake-button stake-submit-button"
        @click="onSubmit"
        :disabled="currentState !== 'ok'"
        >{{ submitButtonLabel }}</button>
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import { formatDurationFromSeconds } from '../utils/date-time';
import { isStakeType, isNftStakeType, StakeType } from '../interfaces/State';
import { toBN } from '@/utils/common';
import { secondsToDDHHMMSS } from '../utils/date-time';
import {Multiselect} from 'vue-multiselect';
import {PropType} from 'vue/types/options';
import BN from 'bignumber.js';
import {mapActions, mapState} from 'vuex';
import i18n from '@/i18n';
import { TranslateResult } from 'vue-i18n';

interface StoreMappedActions {
  fetchStakeDetails(payload: {stakeType: StakeType}): Promise<void>;
  stake(payload: {
    amount: string; stakeType: StakeType}): void;
  stakeNfts(payload: {
    ids: string[]; stakeType: StakeType}): void;
  unstake(payload: {
    amount: string; stakeType: StakeType}): void;
  unstakeNfts(payload: {
    ids: string[]; stakeType: StakeType}): void;
  unstakeKing(payload: {
    amount: string;}): Promise<void>;
  claimKingReward(): Promise<void>;
  stakeUnclaimedRewards(payload: {
    stakeType: StakeType;}): Promise<void>;
  claimReward(payload: {
    stakeType: StakeType;}): Promise<void>;
  getOwnedLandIdsWithTier(): Promise<string[]>;
  getStakedIds(payload: {
    stakeType: StakeType;
  }): Promise<string[]>;
}
// interface Data {
//   stakeUnlockTimeLeftCurrentEstimate: number;
//   stakeRewardDistributionTimeLeftCurrentEstimate: number;
// }

enum currentState {
  connectWallet = '',
  stakeLocked = 'ok',
  contractFull = '',
  amountIsTooBig = '',
  waiting = '',
  inputIsZero = '',
  insufficientBalance = '',
  notEnoughFundsInExitPool = '',
  notEnoughFundsInExitPoolForFee = '',
  ok = 'ok',
}

enum claimState {
  loading = 'loading',
  rewardLocked = 'rewardLocked',
  ok = 'ok',
}

interface StakeData {
  contractBalance: string;
  currentRewardEarned: string;
  ownBalance: string;
  remainingCapacityForDeposit: string;
  remainingCapacityForWithdraw: string;
  rewardDistributionTimeLeft: number;
  rewardMinimumStakeTime: number;
  stakedBalance: string;
  unlockTimeLeft: number;
}

export default Vue.extend({
  components: {
    Multiselect,
  },
  props: {
    stakeTitle: {
      type: String,
      required: true,
      default: '',
    },
    stakeType: {
      type: String as PropType<StakeType>,
    },
    stakeTokenName: {
      type: String,
    },
    rewardTokenName: {
      type: String,
    },
    minimumStakeTime: {
      type: Number,
    },
    estimatedYield: {
      type: BN,
    },
    rewardsDuration: {
      type: Number,
    },
    deprecated: {
      type: Boolean,
    },
    rewardDistributionTimeLeft: {
      type: Number,
    },
    currentRewardEarned: {
      type: String,
    },
    totalStaked: {
      type: String,
    },
    walletBalance: {
      type: String,
    },
  },
  data() {
    return {
      textAmount: '' as string,
      idsToStake: [] as string[],
      isOpen: false as boolean,
      isDeposit: true as boolean,
      loading: false as boolean,
      startedStaking: false as boolean,
      errorWhenUpdating: false as boolean,
      rewardClaimLoading: false as boolean,
      stakeUnlockTimeLeftCurrentEstimate: 0 as number,
      stakeRewardDistributionTimeLeftCurrentEstimate: 0 as number,
      ownedLandIds: [] as string[],
      stakedIds: [] as string[],
      secondsInterval: null as ReturnType<typeof setInterval> | null,
      stakeRewardProgressInterval: null as ReturnType<typeof setInterval> | null,
    };
  },
  computed: {
    // ...(mapState(['defaultAccount','staking','skillRewards'])),
    ...mapState(['staking', 'defaultAccount']),
    progressBarWidth(): number{
      if(this.minimumStakeTime === 0) return 100;
      return 100 * ((this.minimumStakeTime - this.stakeUnlockTimeLeftCurrentEstimate) / this.minimumStakeTime);
    },
    tier(): number {
      return this.stakeType.startsWith('cbkLand') && + this.stakeType.slice(-1) || 0;
    },
    isNftStaking(): boolean {
      return isNftStakeType(this.stakeType);
    },
    rewardsDurationFormatted(): string {
      return formatDurationFromSeconds(this.rewardsDuration);
    },
    currentRewardEarnedFormatted(): BN {
      return toBN(this.currentRewardEarned).dividedBy(1e18);
    },
    totalStakedFormatted(): string {
      return this.isNftStaking ? this.totalStaked: toBN(this.totalStaked).dividedBy(1e18).toFixed(0);
    },
    walletBalanceFormatted(): string {
      return toBN(this.walletBalance).dividedBy(1e18).toFixed(3);
    },
    stakedBalanceFormatted(): string {
      // !!!
      return this.isNftStaking ? this.stakedBalance.toFixed(3) : this.stakedBalance.dividedBy(1e18).toFixed(3);
    },
    stakeData(): StakeData {
      return this.staking[this.stakeType];
    },

    rewardDistributionTimeLeftInternal(): number { return this.stakeData.rewardDistributionTimeLeft; },
    unlockTimeLeftInternal(): number { return this.stakeData.unlockTimeLeft; },

    stakingTokenName(): string {
      switch(this.stakeType) {
      case 'skill':
      case 'skill2':
      case 'skill90':
      case 'skill180':
        return 'SKILL';
      case 'king':
      case 'king90':
      case 'king180':
        return 'KING';
      case 'lp':
      case 'lp2':
        return 'SKILL-WBNB';
      case 'cbkLandT1':
      case 'cbkLandT2':
      case 'cbkLandT3':
        return 'CBKL';
      default:
        return 'unknown';
      }
    },

    minimumStakeTimeFormatted(): string {
      return formatDurationFromSeconds(this.stakeData.rewardMinimumStakeTime);
    },

    estimatedUnlockTimeLeftFormatted(): string {
      return secondsToDDHHMMSS(this.stakeUnlockTimeLeftCurrentEstimate);
    },

    showRewardClaimSection(): boolean {
      if (this.rewardClaimState === 'loading') {
        return true;
      }

      return toBN(this.currentRewardEarned).gt(0);
    },

    stakedBalance(): BN{
      return toBN(this.stakeData.stakedBalance);
    },

    remainingCapacityForDeposit(): BN {
      if (!this.stakeData.remainingCapacityForDeposit) {
        return toBN(0);
        // TODO Check!
      }

      return toBN(this.stakeData.remainingCapacityForDeposit);
    },

    remainingCapacityForWithdraw(): BN {
      return toBN(this.stakeData.remainingCapacityForWithdraw);
    },

    contractBalance(): BN {
      return toBN(this.stakeData.contractBalance);
    },

    currentState(): string {
      if (!this.defaultAccount || this.errorWhenUpdating) {
        return currentState.connectWallet;
      }

      if (!this.isDeposit && this.unlockTimeLeftInternal > 0) {
        return currentState.stakeLocked;
      }

      if (
        this.remainingCapacityForDeposit &&
        this.remainingCapacityForDeposit.eq(0) &&
        this.isDeposit
      ) {
        return currentState.contractFull;
      }

      if (
        this.remainingCapacityForDeposit &&
        this.bigNumberAmount.gt(this.remainingCapacityForDeposit) &&
        this.isDeposit
      ) {
        return currentState.amountIsTooBig;
      }

      if (this.textAmount[this.textAmount.length - 1] === '.') {
        return 'waiting';
      }

      if (isStakeType(this.stakeType) && +this.textAmount <= 0) {
        return 'inputIsZero';
      }

      if (isNftStakeType(this.stakeType) && this.idsToStake.length === 0) {
        return 'inputIsZero';
      }

      const hasSufficientBalance = this.isDeposit
        ? toBN(this.walletBalance).gte(this.bigNumberAmount)
        : this.stakedBalance.gte(this.bigNumberAmount);

      if (!hasSufficientBalance) {
        return 'insufficientBalance';
      }

      if (this.bigNumberAmount.gt(this.contractBalance) && !this.isDeposit) {
        return 'notEnoughFundsInExitPool';
      }

      if (
        this.bigNumberAmount.gt(this.remainingCapacityForWithdraw) &&
        !this.isDeposit
      ) {
        return 'notEnoughFundsInExitPool';
      }

      return 'ok';
    },

    submitButtonLabel(): TranslateResult {
      switch (this.currentState) {
      case 'ok':
        return this.isDeposit ? i18n.t('stake.stakeButtonLabel') : i18n.t('stake.unstakeButtonLabel');
      case currentState.contractFull:
        return i18n.t('stake.contractIsFullButtonLabel');
      case currentState.amountIsTooBig:
        return i18n.t('stake.amountIsTooBigButtonLabel');
      case currentState.waiting:
        return i18n.t('stake.waitingButtonLabel');
      case currentState.inputIsZero:
        return i18n.t('stake.enterAnAmountButtonLabel');
      case currentState.insufficientBalance:
        return i18n.t('stake.insufficientBalanceButtonLabel');
      case currentState.notEnoughFundsInExitPool:
        return i18n.t('stake.notEnoughFundsInExitPoolButtonLabel');
      case currentState.stakeLocked:
        return i18n.t('stake.sorryStake', {estimatedUnlockTimeLeftFormatted : this.estimatedUnlockTimeLeftFormatted});
      default:
        return i18n.t('stake.connectToWalletButtonLabel');
      }
    },

    rewardClaimState(): string {
      if (this.rewardClaimLoading) {
        return claimState.loading;
      }

      if (this.unlockTimeLeftInternal > 0) {
        return claimState.rewardLocked;
      }
      return claimState.ok;
    },

    claimRewardButtonLabel(): TranslateResult {
      switch (this.rewardClaimState) {
      case claimState.loading:
        return i18n.t('stake.loading');
      case claimState.rewardLocked:
        return i18n.t('stake.sorryReward', {estimatedUnlockTimeLeftFormatted : this.estimatedUnlockTimeLeftFormatted});
      default:
        return i18n.t('stake.claimReward');
      }
    },

    bigNumberAmount: {
      get(): BN {
        if (!this.textAmount) return toBN(0);
        return toBN(this.textAmount).multipliedBy(1e18);
      },
      set(newBnAmount: BN): void {
        this.textAmount = newBnAmount.dividedBy(1e18).toString();
      },
    },
  },
  async mounted(){
    this.stakeUnlockTimeLeftCurrentEstimate = this.unlockTimeLeftInternal;
    this.stakeRewardDistributionTimeLeftCurrentEstimate = this.rewardDistributionTimeLeftInternal;

    this.stakeRewardProgressInterval = setInterval(async () => {
      await this.fetchStakeDetails({ stakeType: this.stakeType });
    }, 10 * 1000);

    this.secondsInterval = setInterval(() => {
      this.updateEstimates();
    }, 1000);
    // console.log(typeof(this.secondsInterval));
  },
  beforeDestroy() {
    if(this.stakeRewardProgressInterval) clearInterval(this.stakeRewardProgressInterval);
    if(this.secondsInterval) clearInterval(this.secondsInterval);
  },
  methods:{
    ...(mapActions([
      'fetchStakeDetails',
      'stake',
      'stakeNfts',
      'unstake',
      'unstakeNfts',
      'unstakeKing',
      'claimKingReward',
      'stakeUnclaimedRewards',
      'claimReward',
      'getOwnedLandIdsWithTier',
      'getStakedIds',
    ]) as StoreMappedActions),
    inputByRatio(ratio: number): any {
      if(this.isDeposit){
        this.textAmount = toBN(this.walletBalance).dividedBy(1/ratio*1e18).toFixed(18);
      }
      else{
        this.textAmount = this.stakedBalance.dividedBy(1/ratio*1e18).toFixed(18);
      }
    },
    idWithTier({ id, tier }: {id: number, tier: number}): string {
      return `${id} (${i18n.t('stake.tier')} ${tier})`;
    },

    updateEstimates(): void {
      if (this.stakeUnlockTimeLeftCurrentEstimate > 0) {
        this.stakeUnlockTimeLeftCurrentEstimate--;
      }

      if (this.stakeRewardDistributionTimeLeftCurrentEstimate > 0) {
        this.stakeRewardDistributionTimeLeftCurrentEstimate--;
      }
    },

    async onSubmit(): Promise<void> {
      if (this.loading || this.currentState !== 'ok') return;
      const amount = this.bigNumberAmount.toString();

      try {
        this.loading = true;

        if (this.isDeposit) {
          if(this.isNftStaking) {
            await this.stakeNfts({ ids: this.idsToStake.map(x => x.id), stakeType: this.stakeType });
          }
          else {
            await this.stake({ amount, stakeType: this.stakeType });
          }
        } else {
          //unstake
          if(this.stakeType === 'king') {
            await this.unstakeKing({ amount });
          }
          else {
            if(this.isNftStaking) {
              await this.unstakeNfts({ ids: this.idsToStake.map(x => x.id), stakeType: this.stakeType });
            }
            else {
              await this.unstake({ amount, stakeType: this.stakeType });
            }
          }
        }
        if(isNftStakeType(this.stakeType)) {
          await this.updateOwnedLands();
          this.idsToStake = [];
        }
      } catch (e) {
        console.error(e);
      } finally {
        this.loading = false;
      }
    },
    async onClaimReward(): Promise<void> {
      if (this.rewardClaimState !== 'ok') return;

      try {
        this.rewardClaimLoading = true;

        if(this.stakeType === 'king') {
          await this.claimKingReward();
        }
        else {
          await this.claimReward({ stakeType: this.stakeType });
        }
      } catch (e) {
        console.error(e);
      } finally {
        this.rewardClaimLoading = false;
      }
    },
    async fetchData(): Promise<void> {
      try {
        this.errorWhenUpdating = false;
        this.loading = true;

        await this.fetchStakeDetails({ stakeType: this.stakeType });
      } catch (err) {
        this.errorWhenUpdating = true;
        console.log(err);
      } finally {
        this.loading = false;
      }
    },

    async updateOwnedLands(): Promise<void> {
      this.ownedLandIds = await this.getOwnedLandIdsWithTier();
      this.stakedIds = await this.getStakedIds({ stakeType: this.stakeType });
    }
  },
});
</script>

<style scoped>
.container {
  background: rgb(22, 22, 22); /* change to: background: #000E1D; */
  padding: 45px 40px;
  display: flex;
  flex-direction: column;
  align-items: center;
  height:100%;
}
.stake-stats{
  display:flex;
  justify-content:space-between;
  width: 100%;
  margin: 20px 0;
  flex-wrap: wrap;
}
.stake-stats-item{
  border: 1px solid #404857;
  border-radius: 5px;
  display:flex;
  flex-direction: column;
  padding: 5px 10px;
  width: calc(25% - 10px );
}

.stake-stats-item-title{
  font: normal normal normal 16px/21px Roboto;
  color: #EDCD90;
  margin-bottom:5px;
}
.stake-stats-item-value{
  font: normal normal medium 16px/21px Roboto;
  color:#fff;
}
.stats-row{
  width:100%;
  display: flex;
  justify-content: space-between;
  margin-bottom:25px;
}
.stats-col{
  /* flex:1; */
  display:flex;
  flex-direction: column;
}
.claim-rewards-wrapper{
  border: 1px solid #404857;
  border-radius: 5px;
  width:100%;
}
.progressBarWrapper{
  width:100%;
  position: relative;
  height:15px;
  background: #404857;
}
.progressBar{
  height: 15px;
  background: hsl(43, 29%, 48%);
  border-radius: 5px;
  position: absolute;
  z-index: 1;
  animation: progressBar 3s ease-in-out;
  animation-fill-mode:both;
}
.progressBarWrapper > span{
  font: 12px Roboto;
  position: absolute;
  color:#fff;
  z-index: 2;
  left: 50%;
  transform: translateX(-50%);
}
@keyframes progressBar {
  0% {
    background: hsl(43, 0%, 48%);
    width: 0;
  }
}
.claim-rewards{
  margin-top: 15px;
  padding: 15px;
  display:flex;
  justify-content: space-between;
  align-items: center;
}
.claim-rewards-btns{
  margin-right:15px;
}
.claim-rewards-btns button{
  width:clamp(75px,calc(50% - 5px),100%);
  padding: 5px 10px;
}

.btn-restake{
  border: none;
  background: none;
  color: #9D98A1;
  font: normal 16px/21px Roboto;
  text-align: center;
}
.stake-button{
  text-align: center;
  background: #9E8A57; /* change to: #1168D0; */
  border-radius: 5px;
  border:none;
  color: #FFFFFF;
  font: normal 16px/21px Roboto;
  width:100%;
  padding:5px 23px;
}
.stake-buttons{
  width:100%;
  margin: 0 auto;
  display:flex;
  justify-content: space-between;
  margin-top:25px;
}
.stake-buttons .stake-button{
  width:calc(50% - 7px);
  min-height: 43px;
}

.stake-button:disabled{
  background: #404857;
  color: #9D98A1;
  cursor: default;
  }

.btn_active{
  background: hsl(43, 15%, 18%);
  color: #fff;
}

.divider{
  width:100%;
  height:1px;
  background: #404857; /* maybe change to: #1168D0; */
  margin: 20px 0;
}

.token-amount-input {
  font-variant: tabular-nums;
  font-feature-settings: "tnum";
  padding: 10px 11px 5px 11px;
  color: #fff;
  background-color: transparent;
  outline-width: 0;
  font: normal 34px Roboto;
  line-height: 40px;
  text-align: right;
  text-overflow: ellipsis;
  border-radius: 5px;
  border: 1px solid #404857;
  touch-action: manipulation;
  margin-bottom: 20px;
  width: 100%;
}

.stake-submit-button{
  min-height: 43px;
}

.input-ratio-buttons{
  display:flex;
  justify-content: space-between;
  align-items: center;
  width:100%;
  margin-bottom:20px;
}
.ratio-button{
  width:calc(25% - 25px);
  font-size:12px;
  padding:2px 5px;
}

.multiselect{
  overflow: visible;
  margin-bottom:50px;
}

.stake-type-title {
  font: bold 20px/25px Trajan;
  align-self: flex-start;
  color: #EDCD90;
}

.inputSection{
  width: 70%;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  height:100%;
}

/* Mobile */
@media only screen and (max-width: 768px)  {
  .stake-stats-item{
    margin-bottom: 10px;
    width: calc(50% - 10px );
  }
  .container {
    padding: 20px 15px;
  }
  .claim-rewards-btns{
    justify-content: center;
  }
  .stats-col{
    align-items: center;
    justify-content: center;
  }
  .inputSection{
    width: 100%;
  }
}
</style>
