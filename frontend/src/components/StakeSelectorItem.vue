<template>
  <div class="container">
    <h1 class="stake-type-title">{{ stakeTitle }}</h1>
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
        <div class="stake-stats-item-title">Total Staked</div>
        <div class="stake-stats-item-value">{{ totalStakedFormatted }} {{stakeTokenName}}</div>
      </div>
      <div class="stats-col">
        <div class="stake-stats-item-title">Staked</div>
        <div class="stake-stats-item-value">{{ stakedBalanceFormatted }} {{stakeTokenName}}</div>
      </div>
      <div class="stats-col">
        <div class="stake-stats-item-title">Available in Wallet</div>
        <div class="stake-stats-item-value">{{ walletBalanceFormatted }} {{stakeTokenName}}</div>
      </div>
    </div>
    <div class="claim-rewards-wrapper">
      <div class="claim-rewards">
        <div>
          <div class="stake-stats-item-title">Rewards</div>
          <div class="stake-stats-item-value">{{currentRewardEarnedFormatted}} {{rewardTokenName}}</div>
        </div>
        <div class="claim-rewards-btns">
          <button class="stake-button claim-reward-btn"
            @click="onClaimReward"
            :disabled="rewardClaimState !== 'ok' || !showRewardClaimSection"
            data-toggle="tooltip" data-placement="right" :title="claimRewardButtonLabel"
            >Claim!
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
        @click="isDeposit = true"
        :class="{ btn_active: isDeposit }"
        >
        Stake
        </button>
      <button class="stake-button"
        @click="isDeposit = false"
        :class="{ btn_active: !isDeposit }"
        >
        Unstake
        </button>
    </div>
    <div class="divider"></div>
    <div class="inputSection">
      <!-- Input for stake amount -->
      <input
        v-if="!isNftStaking && currentState !== 'stakeLocked'"
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
      <div v-if="!isNftStaking && currentState !== 'stakeLocked'" class="input-ratio-buttons">
        <button class="stake-button ratio-button" @click="inputByRatio(0.25)">25%</button>
        <button class="stake-button ratio-button" @click="inputByRatio(0.50)">50%</button>
        <button class="stake-button ratio-button" @click="inputByRatio(0.75)">75%</button>
        <button class="stake-button ratio-button" @click="inputByRatio(1)">MAX</button>
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
          <span>{{(isDeposit ? 'You don\'t have any unstaked land!' : 'No land staked or still locked')}}</span>
        </template>
      </multiselect>
      <button class="stake-button stake-submit-button"
        @click="onSubmit"
        :disabled="currentState !== 'ok'"
        >{{ submitButtonLabel }}</button>
    </div>
  </div>
</template>

<script>
import { formatDurationFromSeconds } from '../utils/date-time';
import { isStakeType, isNftStakeType } from '../interfaces/State';
import { toBN } from '@/utils/common';
import { mapActions, mapState } from 'vuex';
import { secondsToDDHHMMSS } from '../utils/date-time';
import Multiselect from 'vue-multiselect';
import Vue from 'vue';

export default Vue.extend({
  props: [
    'stakeTitle',
    'stakeTokenName',
    'rewardTokenName',
    'stakeType',
    'minimumStakeTime',
    'estimatedYield',
    'rewardsDuration',
    'deprecated',
    'rewardDistributionTimeLeft',
    'currentRewardEarned',
    'totalStaked',
    'walletBalance',
  ],
  components:{
    Multiselect,
  },
  data() {
    return{
      textAmount: '',
      idsToStake: [],
      isOpen: false,
      isDeposit: true,
      loading: false,
      errorWhenUpdating: null,
      rewardClaimLoading: false,
      stakeUnlockTimeLeftCurrentEstimate: 0,
      stakeRewardDistributionTimeLeftCurrentEstimate: 0,
      ownedLandIds: [],
      stakedIds: []
    };
  },
  async mounted() {
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
    clearInterval(this.stakeRewardProgressInterval);
    clearInterval(this.secondsInterval);
  },
  computed: {
    ...mapState(['defaultAccount', 'staking', 'skillRewards']),
    progressBarWidth(){
      if(this.minimumStakeTime === 0) return 100;
      return 100 * ((this.minimumStakeTime - this.stakeUnlockTimeLeftCurrentEstimate) / this.minimumStakeTime);
    },
    tier(){
      return this.stakeType.startsWith('cbkLand') && + this.stakeType.slice(-1) || 0;
    },
    isNftStaking() {
      return isNftStakeType(this.stakeType);
    },
    rewardsDurationFormatted() {
      return formatDurationFromSeconds(this.rewardsDuration);
    },
    currentRewardEarnedFormatted(){
      return toBN(this.currentRewardEarned).dividedBy(1e18);
    },
    totalStakedFormatted(){
      return this.isNftStaking ? this.totalStaked: toBN(this.totalStaked).dividedBy(1e18).toFixed(0);
    },
    walletBalanceFormatted() {
      return toBN(this.walletBalance).dividedBy(1e18).toFixed(3);
      // return this.walletBalance;
    },
    stakedBalanceFormatted(){
      return this.isNftStaking ? this.stakedBalance: toBN(this.stakedBalance).dividedBy(1e18).toFixed(3);
    },
    stakeData() {
      return this.staking[this.stakeType];
    },

    rewardDistributionTimeLeftInternal() { return this.stakeData.rewardDistributionTimeLeft; },
    unlockTimeLeftInternal() { return this.stakeData.unlockTimeLeft; },

    stakingTokenName() {
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

    minimumStakeTimeFormatted() {
      return formatDurationFromSeconds(this.stakeData.rewardMinimumStakeTime);
    },

    estimatedUnlockTimeLeftFormatted() {
      return secondsToDDHHMMSS(this.stakeUnlockTimeLeftCurrentEstimate);
    },

    showRewardClaimSection() {
      if (this.rewardClaimState === 'loading') {
        return true;
      }

      return toBN(this.currentRewardEarned).gt(0);
    },

    stakedBalance() {
      return toBN(this.stakeData.stakedBalance);
    },

    remainingCapacityForDeposit() {
      if (!this.stakeData.remainingCapacityForDeposit) {
        return null;
      }

      return toBN(this.stakeData.remainingCapacityForDeposit);
    },

    remainingCapacityForWithdraw() {
      return toBN(this.stakeData.remainingCapacityForWithdraw);
    },

    contractBalance() {
      return toBN(this.stakeData.contractBalance);
    },

    currentState() {
      if (!this.defaultAccount || this.errorWhenUpdating) {
        return 'connectWallet';
      }

      if (!this.isDeposit && this.unlockTimeLeftInternal > 0) {
        return 'stakeLocked';
      }

      if (
        this.remainingCapacityForDeposit &&
        this.remainingCapacityForDeposit.eq(0) &&
        this.isDeposit
      ) {
        return 'contractFull';
      }

      if (
        this.remainingCapacityForDeposit &&
        this.bigNumberAmount.gt(this.remainingCapacityForDeposit) &&
        this.isDeposit
      ) {
        return 'amountIsTooBig';
      }

      if (this.textAmount[this.textAmount.length - 1] === '.') {
        return 'waiting';
      }

      if (isStakeType(this.stakeType) && this.textAmount <= 0) {
        return 'inputIsZero';
      }

      if (isNftStakeType(this.stakeType) && this.idsToStake.length === 0) {
        return 'inputIsZero';
      }

      const hasSufficientBalance = this.isDeposit
        ? toBN(this.walletBalance).gte(this.bigNumberAmount)
        : toBN(this.stakedBalance).gte(this.bigNumberAmount);

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

    submitButtonLabel() {
      switch (this.currentState) {
      case 'ok':
        return this.isDeposit ? this.$t('stake.stakeButtonLabel') : this.$t('stake.unstakeButtonLabel');
      case 'contractFull':
        return this.$t('stake.contractIsFullButtonLabel');
      case 'amountIsTooBig':
        return this.$t('stake.amountIsTooBigButtonLabel');
      case 'waiting':
        return this.$t('stake.waitingButtonLabel');
      case 'inputIsZero':
        return this.$t('stake.enterAnAmountButtonLabel');
      case 'insufficientBalance':
        return this.$t('stake.insufficientBalanceButtonLabel');
      case 'notEnoughFundsInExitPool':
        return this.$t('stake.notEnoughFundsInExitPoolButtonLabel');
      case 'stakeLocked':
        return this.$t('stake.sorryStake', {estimatedUnlockTimeLeftFormatted : this.estimatedUnlockTimeLeftFormatted});
      default:
        return this.$t('stake.connectToWalletButtonLabel');
      }
    },

    rewardClaimState() {
      if (this.rewardClaimLoading) {
        return 'loading';
      }

      if (this.unlockTimeLeftInternal > 0) {
        return 'rewardLocked';
      }

      return 'ok';
    },

    claimRewardButtonLabel() {
      switch (this.rewardClaimState) {
      case 'loading':
        return this.$t('stake.loading');
      case 'rewardLocked':
        return this.$t('stake.sorryReward', {estimatedUnlockTimeLeftFormatted : this.estimatedUnlockTimeLeftFormatted});
      default:
        return this.$t('stake.claimReward');
      }
    },

    bigNumberAmount: {
      get() {
        if (!this.textAmount) return toBN(0);

        return toBN(this.textAmount).multipliedBy(1e18);
      },
      set(newBnAmount) {
        this.textAmount = newBnAmount.dividedBy(1e18);
      },
    },
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
        this.textAmount = 0;
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
    ...mapActions([
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
    ]),
    inputByRatio(ratio) {
      if(this.isDeposit){
        this.textAmount = toBN(this.walletBalance).dividedBy(1/ratio*1e18).toFixed(18);
      }
      else{
        this.textAmount = toBN(this.stakedBalance).dividedBy(1/ratio*1e18).toFixed(18);
      }
    },
    idWithTier({ id, tier }) {
      return `${id} (${this.$t('stake.tier')} ${tier})`;
    },

    updateEstimates() {
      if (this.stakeUnlockTimeLeftCurrentEstimate > 0) {
        this.stakeUnlockTimeLeftCurrentEstimate--;
      }

      if (this.stakeRewardDistributionTimeLeftCurrentEstimate > 0) {
        this.stakeRewardDistributionTimeLeftCurrentEstimate--;
      }
    },

    async onMAX() {
      if (this.isDeposit) {
        if (
          this.remainingCapacityForDeposit &&
          this.remainingCapacityForDeposit.eq(0)
        ) {
          return;
        }

        this.bigNumberAmount = toBN(this.walletBalance);

        if (
          this.remainingCapacityForDeposit &&
          this.bigNumberAmount.gt(this.remainingCapacityForDeposit)
        ) {
          this.bigNumberAmount = toBN(this.remainingCapacityForDeposit);
        }
      } else {
        this.bigNumberAmount = this.stakedBalance;

        if (this.bigNumberAmount.gt(this.remainingCapacityForWithdraw)) {
          this.bigNumberAmount = this.remainingCapacityForWithdraw;
        }

        if (this.bigNumberAmount.gt(this.contractBalance)) {
          this.bigNumberAmount = this.contractBalance;
        }
      }
    },
    async onSubmit() {
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
    async onClaimReward() {
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
    async fetchData() {
      try {
        this.errorWhenUpdating = null;
        this.loading = true;

        await this.fetchStakeDetails({ stakeType: this.stakeType });
      } catch (err) {
        this.errorWhenUpdating = err.message;
        console.log(err);
      } finally {
        this.loading = false;
      }
    },

    async updateOwnedLands() {
      this.ownedLandIds = await this.getOwnedLandIdsWithTier();
      this.stakedIds = await this.getStakedIds(this.stakeType);
    }
  }
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
