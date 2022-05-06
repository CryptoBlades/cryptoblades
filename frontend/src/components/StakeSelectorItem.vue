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
          <button class="stake-button"
            @click="onClaimReward"
            :disabled="rewardClaimState !== RewardClaimState.OK"
            data-toggle="tooltip" data-placement="right" :title="claimRewardButtonLabel"
            >
            <span v-if="isLoadingClaim"><i class="fa fa-spinner fa-spin"></i></span>
            <span v-else>{{ $t('stake.StakeSelectorItem.claim') }}</span>
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
        v-if="!isNftStaking && currentState !== CurrentState.STAKE_LOCKED"
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
      <div v-if="!isNftStaking && currentState !== CurrentState.STAKE_LOCKED" class="input-ratio-buttons">
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
        :disabled="currentState !== CurrentState.OK">
        <span v-if="isLoadingStake"><i class="fa fa-spinner fa-spin"></i></span>
        <span v-else>{{ submitButtonLabel }}</span>
        </button>
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import { formatDurationFromSeconds } from '../utils/date-time';
import { isStakeType, isNftStakeType, StakeType, NftStakeType } from '../interfaces/State';
import { toBN } from '@/utils/common';
import { secondsToDDHHMMSS } from '../utils/date-time';
import {Multiselect} from 'vue-multiselect';
import {PropType} from 'vue/types/options';
import BN from 'bignumber.js';
import {mapActions, mapState} from 'vuex';
import i18n from '@/i18n';
import { TranslateResult } from 'vue-i18n';

interface StoreMappedStakingActions {
  fetchStakeDetails(payload: {stakeType: StakeType | NftStakeType}): Promise<void>;
  stake(payload: {amount: string; stakeType: StakeType | NftStakeType}): void;
  stakeNfts(payload: {ids: string[]; stakeType: StakeType | NftStakeType}): void;
  unstake(payload: {amount: string; stakeType: StakeType | NftStakeType}): void;
  unstakeNfts(payload: {ids: string[]; stakeType: StakeType | NftStakeType}): void;
  unstakeKing(payload: {amount: string;}): Promise<void>;
  claimKingReward(): Promise<void>;
  stakeUnclaimedRewards(payload: {stakeType: StakeType}): Promise<void>;
  claimReward(payload: {stakeType: StakeType | NftStakeType}): Promise<void>;
  getStakedIds(payload: {stakeType: StakeType | NftStakeType}): Promise<LandIds[]>;
}
interface StoreMappedLandActions {
  fetchOwnedLandIdsWithTier(): Promise<LandIds[]>;
}

enum CurrentState {
  CONNECT_WALLET,
  STAKE_LOCKED,
  CONTRACT_FULL,
  AMOUNT_TOO_BIG,
  WAITING,
  INPUT_ZERO,
  INSUFFICIENT_BALANCE,
  NOT_ENOUGH_FUNDS_IN_EXIT_POOL,
  NOT_ENOUGH_FUNDS_IN_EXIT_POOL_FOR_FEE,
  OK,
}

enum RewardClaimState {
  LOADING,
  REWARD_LOCKED,
  OK,
  NO_REWARD,
}

interface LandIds {
  id: string,
  tier: number,
}

interface StakeData {
  contractBalance: string;
  currentRewardEarned: string;
  ownBalance: string;
  remainingCapacityForDeposit: BN;
  remainingCapacityForWithdraw: BN;
  rewardDistributionTimeLeft: number;
  rewardMinimumStakeTime: number;
  stakedBalance: string;
  unlockTimeLeft: number;
}

interface Data {
  textAmount: string,
  idsToStake: LandIds[],
  isOpen: boolean,
  isDeposit: boolean,
  isLoadingClaim: boolean,
  isLoadingStake: boolean,
  startedStaking: boolean,
  rewardClaimLoading: boolean,
  stakeUnlockTimeLeftCurrentEstimate: number,
  stakeRewardDistributionTimeLeftCurrentEstimate: number,
  ownedLandIds: LandIds[],
  stakedIds: LandIds[],
  secondsInterval: ReturnType<typeof setInterval> | null,
  stakeRewardProgressInterval: ReturnType<typeof setInterval> | null,
}

type AllStakeTypes = StakeType | NftStakeType;

export default Vue.extend({
  components: {
    Multiselect,
  },
  props: {
    stakeTitle: {
      type: String,
      required: true,
    },
    stakeType: {
      type: String as PropType<AllStakeTypes>,
      required: true,
    },
    stakeTokenName: {
      type: String,
      required: true,
    },
    rewardTokenName: {
      type: String,
      required: true,
    },
    minimumStakeTime: {
      type: Number,
      required: true,
    },
    estimatedYield: {
      type: BN,
      required: true,
    },
    rewardsDuration: {
      type: Number,
      required: true,
    },
    deprecated: {
      type: Boolean,
    },
    rewardDistributionTimeLeft: {
      type: Number,
      required: true,
    },
    currentRewardEarned: {
      type: String,
      required: true,
    },
    totalStaked: {
      type: String,
      required: true,
    },
    walletBalance: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      textAmount: '',
      idsToStake: [],
      isOpen: false,
      isDeposit: true,
      isLoadingClaim: false,
      isLoadingStake: false,
      startedStaking: false,
      rewardClaimLoading: false,
      stakeUnlockTimeLeftCurrentEstimate: 0,
      stakeRewardDistributionTimeLeftCurrentEstimate: 0,
      ownedLandIds: [],
      stakedIds: [],
      secondsInterval: null,
      stakeRewardProgressInterval: null,
      CurrentState,
      RewardClaimState,
    } as Data;
  },
  computed: {
    ...mapState(['defaultAccount']),
    ...mapState('staking', (['staking'])),
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
      return this.isNftStaking ?
        this.ownedLandIds.filter(land => +land.tier === +this.tier).length.toFixed(3) : toBN(this.walletBalance).dividedBy(1e18).toFixed(3);
    },
    stakedBalanceFormatted(): string {
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

    stakedBalance(): BN{
      return toBN(this.stakeData.stakedBalance);
    },

    remainingCapacityForDeposit(): BN | null {
      if (!this.stakeData.remainingCapacityForDeposit) {
        return null;
      }
      return this.stakeData.remainingCapacityForDeposit;
    },

    remainingCapacityForWithdraw(): BN {
      return this.stakeData.remainingCapacityForWithdraw;
    },

    contractBalance(): BN {
      return toBN(this.stakeData.contractBalance);
    },

    currentState(): CurrentState {
      // no account connect / error
      if (!this.defaultAccount) {
        return CurrentState.CONNECT_WALLET;
      }

      // staked funds still locked
      if (!this.isDeposit && this.unlockTimeLeftInternal > 0) {
        return CurrentState.STAKE_LOCKED;
      }

      // limit of contract reached
      if (
        this.remainingCapacityForDeposit &&
        this.remainingCapacityForDeposit.eq(0) &&
        this.isDeposit
      ) {
        return CurrentState.CONTRACT_FULL;
      }

      // limit of contract will be reached due to deposit
      if (
        this.remainingCapacityForDeposit &&
        this.bigNumberAmount.gt(this.remainingCapacityForDeposit) &&
        this.isDeposit
      ) {
        return CurrentState.AMOUNT_TOO_BIG;
      }

      // no input given
      if (isStakeType(this.stakeType) && +this.textAmount <= 0) {
        return CurrentState.INPUT_ZERO;
      }

      if (isNftStakeType(this.stakeType) && this.idsToStake.length === 0) {
        return CurrentState.INPUT_ZERO;
      }

      const hasSufficientBalance = this.isDeposit
        ? toBN(this.walletBalance).gte(this.bigNumberAmount)
        : this.stakedBalance.gte(this.bigNumberAmount);

      // not enough funds in wallet
      if (!hasSufficientBalance) {
        return CurrentState.INSUFFICIENT_BALANCE;
      }

      // user input bigger than funds in pool
      if (this.bigNumberAmount.gt(this.contractBalance) && !this.isDeposit) {
        return CurrentState.NOT_ENOUGH_FUNDS_IN_EXIT_POOL;
      }

      // user input bigger than funds in pool
      if (
        this.bigNumberAmount.gt(this.remainingCapacityForWithdraw) &&
        !this.isDeposit
      ) {
        return CurrentState.NOT_ENOUGH_FUNDS_IN_EXIT_POOL;
      }

      return CurrentState.OK;
    },

    submitButtonLabel(): TranslateResult {
      switch (this.currentState) {
      case CurrentState.OK:
        return this.isDeposit ? i18n.t('stake.stakeButtonLabel') : i18n.t('stake.unstakeButtonLabel');
      case CurrentState.CONTRACT_FULL:
        return i18n.t('stake.contractIsFullButtonLabel');
      case CurrentState.AMOUNT_TOO_BIG:
        return i18n.t('stake.amountIsTooBigButtonLabel');
      case CurrentState.WAITING:
        return i18n.t('stake.waitingButtonLabel');
      case CurrentState.INPUT_ZERO:
        return i18n.t('stake.enterAnAmountButtonLabel');
      case CurrentState.INSUFFICIENT_BALANCE:
        return i18n.t('stake.insufficientBalanceButtonLabel');
      case CurrentState.NOT_ENOUGH_FUNDS_IN_EXIT_POOL:
        return i18n.t('stake.notEnoughFundsInExitPoolButtonLabel');
      case CurrentState.STAKE_LOCKED:
        return i18n.t('stake.sorryStake', {estimatedUnlockTimeLeftFormatted : this.estimatedUnlockTimeLeftFormatted});
      default:
        return i18n.t('stake.connectToWalletButtonLabel');
      }
    },

    rewardClaimState(): RewardClaimState {
      if (this.isLoadingClaim) {
        return RewardClaimState.LOADING;
      }
      if (this.unlockTimeLeftInternal > 0) {
        return RewardClaimState.REWARD_LOCKED;
      }
      if(!toBN(this.currentRewardEarned).gt(0)){
        return RewardClaimState.NO_REWARD;
      }
      return RewardClaimState.OK;
    },

    claimRewardButtonLabel(): TranslateResult {
      switch (this.rewardClaimState) {
      case RewardClaimState.LOADING:
        return i18n.t('stake.loading');
      case RewardClaimState.REWARD_LOCKED:
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
  },
  beforeDestroy() {
    if(this.stakeRewardProgressInterval) clearInterval(this.stakeRewardProgressInterval);
    if(this.secondsInterval) clearInterval(this.secondsInterval);
  },
  watch: {
    rewardDistributionTimeLeftInternal(newValue, oldValue) {
      if (newValue !== oldValue) {
        this.stakeRewardDistributionTimeLeftCurrentEstimate = newValue;
      }
    },
    unlockTimeLeftInternal(newValue, oldValue) {
      if (newValue !== oldValue) {
        this.stakeUnlockTimeLeftCurrentEstimate = newValue;
      }
    },
    textAmount(newValue, oldVal) {
      if (newValue.length > 40) {
        this.textAmount = oldVal;
        return;
      }
      if (newValue[newValue.length - 1] === 0) {
        this.textAmount = newValue;
        return;
      }
      if (
        newValue[newValue.length - 1] === '.' &&
        newValue[newValue.length - 2] !== '.'
      ) {
        return;
      }
      if (isNaN(newValue)) {
        this.textAmount = oldVal;
        return;
      }
      if (!newValue) {
        this.textAmount = '0';
      }
    },
    isDeposit() {
      this.textAmount = '';
      this.idsToStake = [];
    },
    async defaultAccount(newVal) {
      if (newVal) {
        await this.fetchData();
        if(this.stakeType.startsWith('cbkLand')) {
          await this.updateOwnedLands();
        }
      }
    },
  },
  methods:{
    ...mapActions(
      'staking',
      [
        'getStakedIds',
        'fetchStakeDetails',
        'stake',
        'stakeNfts',
        'unstake',
        'unstakeNfts',
        'unstakeKing',
        'claimKingReward',
        'stakeUnclaimedRewards',
        'claimReward',
      ]) as StoreMappedStakingActions,
    ...mapActions(['fetchOwnedLandIdsWithTier']) as StoreMappedLandActions,

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
      if (this.isLoadingStake || this.currentState !== CurrentState.OK) return;
      const amount = this.bigNumberAmount.toString();

      try {
        this.isLoadingStake = true;

        if (this.isDeposit) {
          //stake
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
        this.isLoadingStake = false;
        this.textAmount = '';
        this.idsToStake = [];
      }
    },
    async onClaimReward(): Promise<void> {
      if (this.rewardClaimState !== RewardClaimState.OK) return;

      try {
        this.isLoadingClaim = true;

        if(this.stakeType === 'king') {
          await this.claimKingReward();
        }
        else {
          await this.claimReward({ stakeType: this.stakeType });
        }
      } catch (e) {
        console.error(e);
      } finally {
        this.isLoadingClaim = false;
      }
    },
    async fetchData(): Promise<void> {
      try {
        await this.fetchStakeDetails({ stakeType: this.stakeType });
      } catch (err) {
        console.log(err);
      }
    },
    async updateOwnedLands(): Promise<void> {
      this.ownedLandIds = await this.fetchOwnedLandIdsWithTier();
      this.stakedIds = await this.getStakedIds({ stakeType: this.stakeType });
    }
  },
});
</script>

<style src="vue-multiselect/dist/vue-multiselect.min.css"></style>
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
.claim-rewards-btns button{
  min-width: 70px;
  padding: 5px 10px;
}

.btn-restake{
  border: none;
  background: none;
  color: #9D98A1;
  font: normal 16px/21px Roboto;
  text-align: center;
}

.stake-button span{
  font: normal 16px/21px Roboto;
  text-align: center;
}

.stake-button{
  font: normal 16px/21px Roboto;
  text-align: center;
  background: #9E8A57; /* change to: #1168D0; */
  border-radius: 5px;
  border:none;
  color: #FFFFFF;
  width:100%;
  padding:5px 23px;
}

.stake-button:disabled{
  background: #404857;
  color: #9D98A1;
  cursor: default;
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
