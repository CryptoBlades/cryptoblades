<template>
  <div class="body main-font options">
    <img
      src="../assets/navbar-icons/burger-menu.png"
      class="burger-icon"
      @click="openMenu"
    />
    <div class="menu-open" v-if="isMenuOpen">
      <b-row>
        <b-col>
          <div @click="closeMenu" class="x-button text-right">
            <img src="../assets/navbar-icons/Close.png" alt="Close"/> {{ $t("combat.close") }}
          </div>
        </b-col>
      </b-row>
      <b-row>
        <b-col cols="12" lg="6" sm="12" class="ads">
        </b-col>
        <b-col cols="12" lg="6" sm="12" order-md="1">
          <div class="menu-icons">
            <div class="row-icons">
              <router-link
                class="menu-icon"
                v-if="!stakeOnly"
                :to="{ name: 'plaza' }"
                exact
              >
                <img src="../assets/navbar-icons/plaza-icon.png" alt="Plaza"/>
                <p>{{ $t("viewLink.character") }}</p>
              </router-link>

              <router-link
                class="menu-icon"
                v-if="!stakeOnly"
                :to="{ name: 'blacksmith' }"
                exact
              >
                <img src="../assets/navbar-icons/blacksmith-icon.png" alt="Blacksmith"/>
                <p>{{ $t("viewLink.blacksmith") }}</p>
              </router-link>

              <router-link
                class="menu-icon"
                v-if="!stakeOnly"
                :to="{ name: 'combat' }"
                exact
              >
                <img src="../assets/navbar-icons/combat-icon.png" alt="Combat"/>
                <p>{{ $t("viewLink.combat") }}</p>
              </router-link>

              <router-link
                class="menu-icon"
                v-if="pvp"
                :to="{ name: 'pvp' }"
                exact
                :class="supportsPvP ? '' : 'disabled-link'"
              >
                <img src="../assets/navbar-icons/arena-icon.png" alt="Arena"/>
                <span>{{ $t("viewLink.arena") }} <hint
                  v-if="!supportsPvP"
                  class="hint"
                  :text="$t('viewLink.functionalityNotSupportedTooltip')"
                /></span>
              </router-link>

              <div v-else class="menu-icon disabled-hover">
                <img src="../assets/navbar-icons/arena-icon.png" alt="Arena"/>
                <p>{{ $t("viewLink.arena") }}</p>
              </div>
            </div>

            <div class="row-icons">
              <router-link
                class="menu-icon"
                v-if="!stakeOnly && raid"
                :to="{ name: 'raid' }"
                exact
              >
                <img src="../assets/navbar-icons/raid-icon.png" alt="Raid"/>
                <p>{{ $t("viewLink.raid") }}</p>
              </router-link>

              <div v-if="!raid" class="menu-icon disabled-hover">
                <img src="../assets/navbar-icons/raid-icon.png" alt="Raid"/>
                <p>{{ $t("viewLink.raid") }}</p>
              </div>

              <router-link
                class="menu-icon"
                v-if="quests"
                :to="{ name: 'quests' }"
                exact
                :class="supportsQuests ? '' : 'disabled-link'"
              >
                <img src="../assets/navbar-icons/quests-icon.png" alt="Quests"/>
                <span>{{ $t("viewLink.quests") }} <hint
                  v-if="!supportsQuests"
                  class="hint"
                  :text="$t('viewLink.functionalityNotSupportedTooltip')"
                /></span>
              </router-link>

              <a
                class="menu-icon"
                v-if="!stakeOnly && market"
                href="https://bazaar.market"
                target="_blank"
              >
                <img src="../assets/navbar-icons/bazaar-icon.png" alt="Bazaar"/>
                <p>{{ $t("viewLink.bazaar") }}</p>
              </a>

              <div v-if="!market" class="menu-icon disabled-hover">
                <img src="../assets/navbar-icons/bazaar-icon.png" alt="Bazaar"/>
                <p>{{ $t("viewLink.bazaar") }}</p>
              </div>

              <router-link
                class="menu-icon"
                :to="{ name: 'select-stake-type' }"
                exact
              >
                <img src="../assets/navbar-icons/stake-icon.png" alt="Stake"/>
                <p>{{ $t("viewLink.stake") }}</p>
              </router-link>
            </div>

            <div class="row-icons">
              <router-link class="menu-icon" :to="{ name: 'treasury' }" exact>
                <img src="../assets/navbar-icons/treasury-icon.png" alt="Treasury"/>
                <p>{{ $t("viewLink.treasury") }}</p>
              </router-link>

              <router-link
                class="menu-icon"
                :to="{ name: 'leaderboard' }"
                exact
              >
                <img src="../assets/navbar-icons/leaderboard-icon.png" alt="Leaderboard"/>
                <p>{{ $t("viewLink.leaderboard") }}</p>
              </router-link>

              <router-link
                class="menu-icon"
                :to="{ name: 'bridge' }"
                v-if="isBridgeEnabled"
                exact
              >
                <img src="../assets/navbar-icons/bridge-icon.png" alt="Bridge"/>
                <p>{{ $t("viewLink.nftbridge") }}</p>
              </router-link>

              <div v-else class="menu-icon disabled-hover">
                <img src="../assets/navbar-icons/bridge-icon.png" alt="Bridge"/>
                <p>{{ $t("viewLink.nftbridge") }}</p>
              </div>

              <a
                class="menu-icon"
                href="https://cryptoblades.gitbook.io/wiki/"
                target="_blank"
              >
                <img src="../assets/navbar-icons/wiki-icon.png" alt="Wiki"/>
                <p>{{ $t("viewLink.wiki") }}</p>
              </a>
            </div>

            <div class="row-icons">
              <router-link class="menu-icon" :to="{ name: 'options' }" exact>
                <img src="../assets/navbar-icons/gear-icon.png" alt="Options"/>
                <p>{{ $t("viewLink.settings") }}</p>
              </router-link>

              <router-link
                v-if="hasAdminAccess"
                class="menu-icon"
                :to="{ name: 'admin' }"
                exact
              >
                <img src="../assets/navbar-icons/gear-icon.png" alt="Admin"/>
                <p>{{ $t("viewLink.admin") }}</p>
              </router-link>

              <router-link
                v-if="merchandise"
                class="menu-icon"
                :to="{ name: 'merchandise' }"
                exact
                :class="supportsMerchandise ? '' : 'disabled-link'"
              >
                <img src="../assets/navbar-icons/bazaar-icon.png" alt="Bazaar"/>
                <span>{{ $t("viewLink.merchandise") }} <hint
                  v-if="!supportsMerchandise"
                  class="hint"
                  :text="$t('viewLink.functionalityNotSupportedTooltip')"
                /></span>

              </router-link>
            </div>

            <!-- disabled for now , will integrate later when other UI's merged -->
            <!-- <div class="menu-other-options">
          <div class="current-chain">
            <b>Current Chain</b>
            <select class="form-control wep-trait-form">
                  <option v-for="x in this.$t('chainsList')" :value="x" :key="x">{{ x }}</option>
            </select>
          </div>
          <div class="payout-currency">
            <b>Payout Currency</b>

            <select class="form-control wep-trait-form">
                  <option v-for="p in supportedProjects" :key="p.id" :value="p.id">{{p.tokenSymbol}} ({{p.name}})</option>
            </select>
          </div>
        </div> -->
          </div>
        </b-col>
      </b-row>
      <div></div>
    </div>

    <b-modal
      class="centered-modal"
      ref="need-gas-modal"
      :title="$t('needGasModal.title')"
      @ok="claimSkill(ClaimStage.Stake)"
      :ok-title="$t('needGasModal.okTitle')"
      @cancel="$router.push({ name: 'portal' })"
      :cancel-title="$t('needGasModal.cancelTitle')"
    >
      {{ $t("needGasModal.needWithdraw") }}
      <div class="text-center">
        <hr class="hr-divider"/>
        {{ $t("needGasModal.holdReminder") }}<br/>
        <span v-html="$t('needGasModal.holdReminderText')"></span>
        <div class="row">
          <div class="col-5">{{ $t("needGasModal.yourTax") }}</div>
          <div class="col-2">
            <span class="text-danger font-weight-bold">{{
                formattedRewardsClaimTax
              }}</span>
          </div>
          <div class="col-5 text-left">
            {{ $t("needGasModal.reduces1") }}<br/>
            {{ $t("needGasModal.reduces2") }}
          </div>
        </div>
      </div>
    </b-modal>
    <b-modal
      class="centered-modal"
      ref="stake-suggestion-modal"
      :title="$t('stakeModal.title')"
      @ok="$router.push({ name: 'select-stake-type' })"
      :ok-title="$t('stakeModal.okTitle')"
      :cancel-title="$t('stakeModal.cancelTitle')"
    >
      {{ $t("stakeModal.stakeText") }}
      <a href="#" @click="claimSkill(ClaimStage.Claim)">
        <br/>
        <span v-if="this.rewardsClaimTaxAsFactorBN > 0">{{
            $t("stakeModal.bonusWarning1")
          }}</span>
        <span v-else>{{
            $t("stakeModal.bonusWarning2", {
              formattedTaxAmount: this.formattedTaxAmount,
            })
          }}</span>
      </a>
    </b-modal>
    <b-modal
      class="centered-modal"
      ref="claim-confirmation-modal"
      :title="$t('stakeModal.confirmModal.title')"
      :ok-title="$t('stakeModal.confirmModal.okTitle')"
      :cancel-title="$t('stakeModal.confirmModal.cancelTitle')"
      @ok="onClaimTokens()"
    >
      <span v-if="this.rewardsClaimTaxAsFactorBN > 0">
        {{
          $t("stakeModal.confirmModal.claimWarning2", {
            formattedRewardsClaimTax,
            formattedTaxAmount: this.formattedTaxAmount,
            formattedBonusLost,
          })
        }}
      </span>
      <span v-else>
        {{
          $t("stakeModal.confirmModal.claimWarning1", {formattedBonusLost})
        }}
      </span>
      <b>{{ $t("stakeModal.confirmModal.cantBeUndone") }}</b>
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
import {SupportedProject} from '@/views/Treasury.vue';
import Hint from '@/components/Hint.vue';
import {market, merchandise, portal, pvp, quests, raid, stakeOnly} from '@/feature-flags';

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
  isMenuOpen: boolean;
  hasAdminAccess: boolean;
}

interface StoreMappedGetters {
  rewardsClaimTaxAsFactorBN: BigNumber;
  maxRewardsClaimTaxAsFactorBN: BigNumber;
  getPartnerProjects: SupportedProject[];
}


enum ClaimStage {
  WaxBridge = 0,
  Stake = 1,
  Claim = 2
}

export default Vue.extend({
  components: {Hint},
  created() {
    this.showGraphics = localStorage.getItem('useGraphics') === 'true';
    this.hideRewards = localStorage.getItem('hideRewards') === 'true';
    this.hideWalletWarning = localStorage.getItem('hideWalletWarning') === 'true';
    this.showSkillInUsd = localStorage.getItem('showSkillInUsd') === 'true';
  },

  data() {
    return {
      isBridgeEnabled: bridgeEnabled,
      isMenuOpen: false,
      showGraphics: false,
      hideRewards: false,
      hideWalletWarning: false,
      showSkillInUsd: false,
      ClaimStage,
      stakeOnly,
      raid,
      market,
      portal,
      pvp,
      quests,
      merchandise,
      hasAdminAccess: false,
    } as Data;
  },

  watch: {
    $route() {
      this.isMenuOpen = false;
    }
  },
  mounted() {
    this.fetchData();
  },
  computed: {
    ...(mapState(['skillRewards', 'directStakeBonusPercent']) as Accessors<StoreMappedState>),
    ...(mapGetters(['rewardsClaimTaxAsFactorBN', 'maxRewardsClaimTaxAsFactorBN', 'getPartnerProjects']) as Accessors<StoreMappedGetters>),
    ...mapGetters(['getCurrentChainSupportsMerchandise', 'getCurrentChainSupportsPvP', 'getCurrentChainSupportsQuests']),
    supportsMerchandise(): boolean {
      return this.getCurrentChainSupportsMerchandise;
    },
    supportsPvP(): boolean {
      return this.getCurrentChainSupportsPvP;
    },
    supportsQuests(): boolean {
      return this.getCurrentChainSupportsQuests;
    },
    formattedSkillReward(): string {
      const skillRewards = fromWeiEther(this.skillRewards);
      return `${toBN(skillRewards).toFixed(4)}`;
    },
    formattedTaxAmount(): string {
      const skillRewards = fromWeiEther(parseFloat(String(parseFloat(this.skillRewards) * parseFloat(String(this.rewardsClaimTaxAsFactorBN)))) + '');
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
      const skillLost = fromWeiEther(parseFloat(String(parseFloat(this.skillRewards) * this.directStakeBonusPercent / 100)).toString());
      return `${toBN(skillLost).toFixed(4)}`;
    },
    canClaimTokens(): boolean {
      return !toBN(this.skillRewards).lte(0);
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
  },

  methods: {
    ...(mapActions(['claimTokenRewards']) as StoreMappedActions),
    ...mapActions(['userHasAnyAdminAccess', 'userHasAnyMinterAccess']),
    toggleGraphics() {
      this.showGraphics = !this.showGraphics;
      if (this.showGraphics) localStorage.setItem('useGraphics', 'true');
      else localStorage.setItem('useGraphics', 'false');

      Events.$emit('setting:useGraphics', {value: this.showGraphics});
    },

    openMenu() {
      this.isMenuOpen = true;
    },

    closeMenu() {
      this.isMenuOpen = false;
    },

    toggleRewards() {
      this.hideRewards = !this.hideRewards;
      if (this.hideRewards) localStorage.setItem('hideRewards', 'true');
      else localStorage.setItem('hideRewards', 'false');

      Events.$emit('setting:hideRewards', {value: this.hideRewards});
    },
    async fetchData() {
      this.hasAdminAccess = await this.userHasAnyAdminAccess() || await this.userHasAnyMinterAccess();
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

      Events.$emit('setting:hideWalletWarning', {value: this.hideWalletWarning});
    },

    toggleShowSkillInUsd() {
      this.showSkillInUsd = !this.showSkillInUsd;
      if (this.showSkillInUsd) localStorage.setItem('showSkillInUsd', 'true');
      else localStorage.setItem('showSkillInUsd', 'false');

      Events.$emit('setting:showSkillInUsd', {value: this.showSkillInUsd});
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

.options {
  padding: 25px;
}

.ads-space {
  background-color: #373737;
  height: 40%;
  width: 70%;
  display: flex;
  justify-content: center;
  align-items: center;
  color: aliceblue;
  font-size: 20px;
  margin-top: 30px;
  margin-left: 40px;
}

.burger-icon {
  width: 35px;
}

.burger-icon:hover {
  cursor: pointer;
}

.menu-open {
  height: 100%;
  width: 100%;
  top: 0;
  position: fixed;
  z-index: 10;
  background-color: rgb(0 0 0 / 85%);
  left: 0;
  padding: 20px;
}

.disabled-link {
  cursor: not-allowed;
  color: gray;
}

.x-button {
  float: right;
  color: white;
  font-size: 23px;
}

.x-button:hover {
  cursor: pointer;
}

.menu-icons {
  float: right;
  border-bottom: 1px solid #1a253b;
}

.menu-icon {
  min-height: 7rem;
  min-width: 7rem;
  background: #1a253b 0% 0% no-repeat padding-box;
  border: 1px solid #344362;
  border-radius: 5px;
  text-align: center;
  white-space: nowrap;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
}

.menu-icon > img {
  height: 2rem;
}

.row-icons {
  display: flex;
  justify-content: left;
  align-items: center;
  gap: 0.5rem;
  margin: 0.5rem 0;
}

.horizontal-small {
  margin: 45px 35px 45px 35px;
  border-top: 2px solid rgb(85, 84, 84);
}

.row-icons-last {
  justify-content: flex-start;
  display: flex;
  margin-left: 6.5%;
  margin-top: 15px;
}

.menu-other-options {
  display: flex;
  justify-content: center;
}

.current-chain,
.payout-currency {
  width: 50%;
  padding: 15px 35px 15px 35px;
}

.current-chain,
.payout-currency > b {
  font-size: 18px;
  color: white;
}

.disabled-hover {
  cursor: not-allowed;
}

@media (max-width: 576px) {
  .menu-icon {
    min-height: 4rem;
    min-width: 4rem;
  }

  .menu-icon > img {
    height: 1.5rem;
  }
}
</style>
