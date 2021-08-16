<template>
  <div class="body main-font">
    <div class="container">
      <div class="row">
        <div class="col text-center">
          <div class="tob-bg-img">
            <img class="vertical-decoration bottom" src="../assets/border-element.png" />
          </div>
          <hr class="header-border header-border-top" />
          <h2 class="linear-wipe">Options</h2>
          <hr class="header-border header-border-bot" />
        </div>
      </div>
      <div class="row">
        <div class="col">
          <b-list-group class="dark-bg">
            <b-list-group-item class="d-flex justify-content-between align-items-center">
              <h4>3D Graphics</h4>
              <b-form-checkbox size="lg" :checked="showGraphics" @change="toggleGraphics()" switch>
                <b class="float-left">{{ showGraphics ? 'On' : 'Off' }}</b>
              </b-form-checkbox>
            </b-list-group-item>
            <b-list-group-item class="d-flex justify-content-between align-items-center">
              <h4>Hide Rewards Bar</h4>
              <b-form-checkbox size="lg" :checked="hideRewards" @change="toggleRewards()" switch>
                <b class="float-left">{{ hideRewards ? 'On' : 'Off' }}</b>
              </b-form-checkbox>
            </b-list-group-item>
            <b-list-group-item class="d-flex justify-content-between align-items-center">
              <h4>Hide Wallet Warning</h4>
              <b-form-checkbox size="lg" :checked="hideWalletWarning" @change="toggleHideWalletWarning()" switch>
                <b class="float-left">{{ hideWalletWarning ? 'On' : 'Off' }}</b>
              </b-form-checkbox>
            </b-list-group-item>
            <b-list-group-item class="d-flex justify-content-between align-items-center">
              <h4>Stamina Cost per Fight</h4>
              <b-form-select size="lg" v-model="fightMultiplier" @change="setFightMultiplier()">
                <b-form-select-option :value="null" disabled>Please select Stamina Cost per Fight</b-form-select-option>
                <b-form-select-option value="1">40</b-form-select-option>
                <b-form-select-option value="2">80</b-form-select-option>
                <b-form-select-option value="3">120</b-form-select-option>
                <b-form-select-option value="4">160</b-form-select-option>
                <b-form-select-option value="5">200</b-form-select-option>
              </b-form-select>
            </b-list-group-item>
          </b-list-group>
        </div>
        <div class="bot-bg-img">
          <img class="bottom-border" src="../assets/border-element.png" />
        </div>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import Events from '../events';
import { mapActions, mapGetters, mapState } from 'vuex';
import BigNumber from 'bignumber.js';
import { Accessors } from 'vue/types/options';
import Vue from 'vue';
import { toBN, fromWeiEther } from '../utils/common';

interface StoreMappedState {
  skillRewards: string;
  directStakeBonusPercent: number;
}

interface StoreMappedActions {
  claimTokenRewards(): Promise<void>;
}
interface Data {
  showGraphics: boolean;
  hideRewards: boolean;
  hideAdvanced: boolean;
  hideWalletWarning: boolean;
  fightMultiplier: number;
}

interface StoreMappedGetters {
  rewardsClaimTaxAsFactorBN: BigNumber;
  maxRewardsClaimTaxAsFactorBN: BigNumber;
}

enum ClaimStage {
  WaxBridge = 0,
  Stake = 1,
  Claim = 2,
}

export default Vue.extend({
  created() {
    this.showGraphics = localStorage.getItem('useGraphics') === 'true';
    this.hideRewards = localStorage.getItem('hideRewards') === 'true';
    this.hideAdvanced = localStorage.getItem('hideAdvanced') === 'true';
    this.hideWalletWarning = localStorage.getItem('hideWalletWarning') === 'true';
    this.fightMultiplier = Number(localStorage.getItem('fightMultiplier'));
  },
  data() {
    return {
      showGraphics: false,
      hideRewards: false,
      hideAdvanced: false,
      hideWalletWarning: false,
      fightMultiplier: 1,
      checked: false,
      ClaimStage,
    } as Data;
  },

  computed: {
    ...(mapState(['skillRewards', 'directStakeBonusPercent']) as Accessors<StoreMappedState>),
    ...(mapGetters(['rewardsClaimTaxAsFactorBN', 'maxRewardsClaimTaxAsFactorBN']) as Accessors<StoreMappedGetters>),

    formattedSkillReward(): string {
      const skillRewards = fromWeiEther(this.skillRewards);
      return `${toBN(skillRewards).toFixed(4)}`;
    },
    formattedTaxAmount(): string {
      const skillRewards = fromWeiEther((parseFloat(this.skillRewards)* parseFloat(String(this.rewardsClaimTaxAsFactorBN))).toString());
      return `${toBN(skillRewards).toFixed(4)}`;
    },
    formattedRewardsClaimTax(): string {
      const frac = this.skillRewards === '0' ? this.maxRewardsClaimTaxAsFactorBN : this.rewardsClaimTaxAsFactorBN;

      return `${frac.multipliedBy(100).decimalPlaces(0, BigNumber.ROUND_HALF_UP)}%`;
    },
    formattedBonusLost(): string {
      const skillLost = fromWeiEther((parseFloat(this.skillRewards)*this.directStakeBonusPercent/100).toString());
      return `${toBN(skillLost).toFixed(4)}`;
    },
    canClaimTokens(): boolean {
      if (toBN(this.skillRewards).lte(0)) {
        return false;
      }
      return true;
    },
  },

  methods: {
    ...(mapActions(['claimTokenRewards']) as StoreMappedActions),
    toggleGraphics() {
      this.showGraphics = !this.showGraphics;
      if (this.showGraphics) localStorage.setItem('useGraphics', 'true');
      else localStorage.setItem('useGraphics', 'false');

      Events.$emit('setting:useGraphics', { value: this.showGraphics });
    },

    toggleRewards() {
      this.hideRewards = !this.hideRewards;
      if (this.hideRewards) localStorage.setItem('hideRewards', 'true');
      else localStorage.setItem('hideRewards', 'false');

      Events.$emit('setting:hideRewards', { value: this.hideRewards });
    },

    toggleAdvanced() {
      this.hideAdvanced = !this.hideAdvanced;
      if (this.hideAdvanced) localStorage.setItem('hideAdvanced', 'true');
      else localStorage.setItem('hideAdvanced', 'false');

      Events.$emit('setting:hideAdvanced', { value: this.hideAdvanced });
    },
    async onClaimTokens() {
      if (this.canClaimTokens) {
        await this.claimTokenRewards();
      }
    },
    async claimSkill(stage: ClaimStage) {
      if (stage === ClaimStage.WaxBridge) {
        (this.$refs['need-gas-modal'] as any).show();
      }
      if (stage === ClaimStage.Stake) {
        (this.$refs['stake-suggestion-modal'] as any).show();
      }
      if (stage === ClaimStage.Claim) {
        (this.$refs['stake-suggestion-modal'] as any).hide();
        (this.$refs['claim-confirmation-modal'] as any).show();
      }
    },

    toggleHideWalletWarning() {
      this.hideWalletWarning = !this.hideWalletWarning;
      if (this.hideWalletWarning) localStorage.setItem('hideWalletWarning', 'true');
      else localStorage.setItem('hideWalletWarning', 'false');

      Events.$emit('setting:hideWalletWarning', { value: this.hideWalletWarning });
    },

    setFightMultiplier() {
      localStorage.setItem('fightMultiplier', this.fightMultiplier.toString());

      Events.$emit('setting:fightMultiplier', { value: this.fightMultiplier });
    },
  },
});
</script>

<style>
.list-group {
  border: 2px solid #9e8a57;
  border-radius: 5px;
  background: linear-gradient(120deg, rgba(20, 20, 20, 1) 0%, rgb(41, 43, 38) 100%);
  max-width: 900px;
  margin: 0 auto;
}
.list-group-item {
  background: none !important;
  border: 0.2px dashed #9e8a57 !important;
}
.top-bg-img,
.bot-bg-img {
  width: 100%;
  text-align: center;
}
.top-bg-img > img,
.bot-bg-img > img {
  width: 100%;
}
.vertical-decoration {
  width: 100%;
}
.vertical-decoration.bottom {
  transform: scaleY(-1) !important;
  margin: 0 auto;
  display: block;
}

.botom-border {
  margin: 0 auto;
  display: block;
}
.header-border-top {
  border-style: solid;
  border-color: #9e8a57;
  border-width: 1px 0 0 0;
  border-radius: 20px;
}
.header-border-top:after {
  display: block;
  content: '';
  height: 30px;
  margin-top: -31px;
  border-style: solid;
  border-color: #9e8a57;
  border-width: 0 0 1px 0;
  border-radius: 20px;
}
.header-border-bot {
  border-style: solid;
  border-color: #9e8a57;
  border-width: 1px 0 0 0;
  border-radius: 20px;
  padding: 0;
}
.header-border-bot:after {
  display: block;
  content: '';
  border-style: solid;
  border-color: #9e8a57;
  border-width: 0 0 1px 0;
  border-radius: 20px;
}

.header-border {
  max-width: 700px;
}

.linear-wipe {
  font-weight: 900;
  text-align: center;
  background: linear-gradient(to right, rgb(248, 218, 136) 20%, rgb(88, 82, 23) 40%, rgb(87, 87, 34) 60%, rgb(177, 150, 92) 80%);
  background-size: 200% auto;
  color: #000;
  background-clip: text;
  text-fill-color: transparent;
  text-shadow: 0px 2px 3px rgba(0, 0, 0, 0.4), 0px 4px 7px rgba(0, 0, 0, 0.1), 0px 9px 12px rgba(0, 0, 0, 0.1);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  animation: shine 1s linear infinite;
  @keyframes shine {
    to {
      background-position: 200% center;
    }
  }
}

.custom-control-input:checked ~ .custom-control-label::before {
  background: linear-gradient(to right, rgb(136, 101, 55) 20%, rgb(88, 82, 23) 40%, rgb(87, 87, 34) 60%, rgb(177, 150, 92) 80%);
  border: #9e8a57;
}

.list-group-item > h4 {
  font-weight: 900;
  background: linear-gradient(to right, rgb(248, 218, 136) 20%, rgb(88, 82, 23) 40%, rgb(87, 87, 34) 60%, rgb(177, 150, 92) 80%);
  background-size: 200% auto;
  color: #000;
  background-clip: text;
  text-fill-color: transparent;
  text-shadow: 0px 2px 3px rgba(0, 0, 0, 0.4), 0px 4px 7px rgba(0, 0, 0, 0.1), 0px 9px 12px rgba(0, 0, 0, 0.1);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  animation: shine 1s linear infinite;
  @keyframes shine {
    to {
      background-position: 200% center;
    }
  }
}

.fullscreen-warning {
  z-index: 999999;
}
</style>
