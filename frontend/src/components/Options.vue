<template>
  <div class="body main-font">
    <img src="../assets/new-ui/6351903_burger_list_menu_navigation_icon@2x.png" class="burger-icon" @click="openMenu"/>
    <div class="menu-open">
      <div @click="closeMenu" class="x-button">X Close</div>
      <div></div>
      <div class="ads"></div>
      <div class="menu-icons">
        <div class="row-icons">
            <div class="menu-icon">
            <img src="../assets/new-ui/char-icon@2x.png">
            <p>Character</p>
          </div>

          <div class="menu-icon">
            <img src="../assets/new-ui/char-icon@2x.png">
            <p>Blacksmith</p>
          </div>

          <div class="menu-icon">
            <img src="../assets/new-ui/char-icon@2x.png">
            <p>Combat</p>
          </div>

          <div class="menu-icon">
            <img src="../assets/new-ui/char-icon@2x.png">
            <p>Arena</p>
          </div>
        </div>

        <div class="row-icons">
            <div class="menu-icon">
            <img src="../assets/new-ui/char-icon@2x.png">
            <p>Raid</p>
          </div>

          <div class="menu-icon">
            <img src="../assets/new-ui/char-icon@2x.png">
            <p>Quest</p>
          </div>

          <div class="menu-icon">
            <img src="../assets/new-ui/char-icon@2x.png">
            <p>Bazaar</p>
          </div>

          <div class="menu-icon">
            <img src="../assets/new-ui/char-icon@2x.png">
            <p>Stake</p>
          </div>
        </div>

        <div class="row-icons">
            <div class="menu-icon">
            <img src="../assets/new-ui/char-icon@2x.png">
            <p>Treasury</p>
          </div>

          <div class="menu-icon">
            <img src="../assets/new-ui/char-icon@2x.png">
            <p>Leaderboard</p>
          </div>

          <div class="menu-icon">
            <img src="../assets/new-ui/char-icon@2x.png">
            <p>NFT Bridge</p>
          </div>

          <div class="menu-icon">
            <img src="../assets/new-ui/char-icon@2x.png">
            <p>Wiki</p>
          </div>
        </div>

         <div class="row-icons">
            <div class="menu-icon">
            <img src="../assets/new-ui/char-icon@2x.png">
            <p>Settings</p>
          </div>
        </div>

      </div>
    </div>
    <!-- <b-navbar-nav>
      <div>
      <b-nav-item-dropdown right>
        <template #button-content>
          <i class="fa fa-bars menu-burger"></i>
        </template>
        <b-dropdown-group>

        <b-dropdown-header>{{$t('optionsMenu.links')}}</b-dropdown-header>

          <b-dropdown-item v-if="currentChainSupportsClaimTokens()" @click="onClaimTokens()"><i
            class="fa fa-coins mr-2"></i>{{ $t('optionsMenu.claimSkill') }}
          </b-dropdown-item>

          <b-dropdown-item :to="{ name: 'leaderboard' }" class="gtag-link-others" tagname="leaderboard_screen">
        <i class="fa fa-trophy mr-2"></i>{{$t('optionsMenu.leaderboard')}}
        </b-dropdown-item>

        <b-dropdown-item :to="{ name: 'portal' }"><i class="fa fa-dungeon mr-2"></i>{{$t('optionsMenu.portal')}}</b-dropdown-item>

        <b-dropdown-item href="https://cryptoblades.gitbook.io/wiki/" target="_blank"><i class="fa fa-book mr-2"></i>{{$t('optionsMenu.wiki')}} <b-icon scale="0.8" icon="question-circle"/></b-dropdown-item>

        <b-dropdown-item :to="{ name: 'nft-display' }">
          <img src="https://seiyria.com/gameicons-font/svg/crystal-ball.svg" class="nft-display-icon"/>
           {{$t('optionsMenu.nftDisplay')}}
        </b-dropdown-item>

        <b-dropdown-item :to="{ name: 'bridge' }" v-if="isBridgeEnabled">
           <i class="fa fa-exchange-alt mr-2"></i>{{$t('optionsMenu.bridgeNfts')}}
        </b-dropdown-item>

        </b-dropdown-group>

        <hr class="border-light">

        <b-dropdown-group class="mb-2">

       <b-dropdown-item :to="{ name: 'options' }">
        <i class="fa fa-cog mr-2"></i>{{$t('optionsMenu.options')}}
        </b-dropdown-item>
        </b-dropdown-group>
      </b-nav-item-dropdown>
       </div>
    </b-navbar-nav> -->

    <b-modal class="centered-modal" ref="need-gas-modal" :title="$t('needGasModal.title')"
      @ok="claimSkill(ClaimStage.Stake)" :ok-title="$t('needGasModal.okTitle')"
      @cancel="$router.push({ name: 'portal' })" :cancel-title="$t('needGasModal.cancelTitle')" >
        {{$t('needGasModal.needWithdraw')}}
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
  </div>
</template>

<script lang="ts">
import Events from '../events';
import {mapActions, mapGetters, mapState} from 'vuex';
import BigNumber from 'bignumber.js';
import {Accessors} from 'vue/types/options';
import Vue from 'vue';
import {fromWeiEther, toBN} from '../utils/common';
import {nft_bridge as bridgeEnabled} from './../feature-flags';

interface StoreMappedState {
  skillRewards: string;
  directStakeBonusPercent: number;
}

interface StoreMappedActions {
  claimTokenRewards(): Promise<void>;
}
interface Data {
  isBridgeEnabled: boolean;
  showGraphics: boolean;
  hideRewards: boolean;
  hideWalletWarning: boolean;
  showSkillInUsd: boolean;
}

interface StoreMappedGetters {
  rewardsClaimTaxAsFactorBN: BigNumber;
  maxRewardsClaimTaxAsFactorBN: BigNumber;
}

enum ClaimStage {
  WaxBridge = 0,
  Stake = 1,
  Claim = 2
}

export default Vue.extend({
  created() {
    this.showGraphics = localStorage.getItem('useGraphics') === 'true';
    this.hideRewards = localStorage.getItem('hideRewards') === 'true';
    this.hideWalletWarning = localStorage.getItem('hideWalletWarning') === 'true';
    this.showSkillInUsd = localStorage.getItem('showSkillInUsd') === 'true';
  },

  data() {
    return {
      isBridgeEnabled: bridgeEnabled,
      showGraphics: false,
      hideRewards: false,
      hideWalletWarning: false,
      showSkillInUsd: false,
      ClaimStage
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
      const skillRewards = fromWeiEther(parseFloat(String(parseFloat(this.skillRewards)*parseFloat(String(this.rewardsClaimTaxAsFactorBN)))) + '');
      return `${toBN(skillRewards).toFixed(4)}`;
    },
    formattedRewardsClaimTax(): string {
      const frac =
        this.skillRewards === '0'
          ? this.maxRewardsClaimTaxAsFactorBN
          : this.rewardsClaimTaxAsFactorBN;

      return `${frac.multipliedBy(100).decimalPlaces(0, BigNumber.ROUND_HALF_UP)}%`;
    },
    formattedBonusLost(): string {
      const skillLost = fromWeiEther(parseFloat(String(parseFloat(this.skillRewards)*this.directStakeBonusPercent/100)).toString());
      return `${toBN(skillLost).toFixed(4)}`;
    },
    canClaimTokens(): boolean {
      return !toBN(this.skillRewards).lte(0);
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

    openMenu() {
      console.log('open menu');
    },

    closeMenu() {
      console.log('close menu');
    },

    toggleRewards() {
      this.hideRewards = !this.hideRewards;
      if (this.hideRewards) localStorage.setItem('hideRewards', 'true');
      else localStorage.setItem('hideRewards', 'false');

      Events.$emit('setting:hideRewards', { value: this.hideRewards });
    },

    async onClaimTokens() {
      if(this.canClaimTokens) {
        await this.claimTokenRewards();
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
    },

    toggleHideWalletWarning() {
      this.hideWalletWarning = !this.hideWalletWarning;
      if (this.hideWalletWarning) localStorage.setItem('hideWalletWarning', 'true');
      else localStorage.setItem('hideWalletWarning', 'false');

      Events.$emit('setting:hideWalletWarning', { value: this.hideWalletWarning });
    },

    toggleShowSkillInUsd() {
      this.showSkillInUsd = !this.showSkillInUsd;
      if (this.showSkillInUsd) localStorage.setItem('showSkillInUsd', 'true');
      else localStorage.setItem('showSkillInUsd', 'false');

      Events.$emit('setting:showSkillInUsd', { value: this.showSkillInUsd });
    },

    currentChainSupportsClaimTokens() {
      return (localStorage.getItem('currentChain') || 'BSC') !== 'BSC';
    },
  }
});
</script>

<style scoped>
.nft-display-icon {
  margin-left: -3px;
  height: 20px;
  filter: invert(75%) sepia(8%) saturate(243%) hue-rotate(8deg) brightness(96%) contrast(81%);
}
.menu-burger {
  font-size: 35px;
}

.burger-icon {
  width: 35px;
  margin: 25px;
}
.burger-icon:hover {
  cursor: pointer;
}

.menu-open {
    height: 100%;
    width: 100%;
    top: 0;
    position: fixed;
    z-index: 999999;
    background: rgb(3, 75, 3);
    left: 0;
    padding: 40px;
}

.x-button {
  float: right;
  color : white;
  font-size: 20px;
}

.ads {
  float: left;
  width: 60%;
  background: black;
  height: 100%;
  margin-top: 30px;
}
.menu-icons {
  float : right;
  width: 40%;
  background: rgb(65, 30, 30);
  height: 100%;
  padding-top: 15px;
  display: inline;
}

.menu-icon {
  width: 95px;
  height: 95px;
  background: #1A253B 0% 0% no-repeat padding-box;
  border: 1px solid #344362;
  border-radius: 5px;
  opacity: 1;
  text-align: center;
  padding-top:20px;
  color : white;
}
.menu-icon > img {
  height : 30px;
}
.row-icons {
  display: flex;
  justify-content: space-evenly;
  align-items: center;
  height: 120px;
}

.row-icons:last-child {
  justify-content: flex-start;
  display: flex;
  margin-left: 6.5%;
}
</style>
