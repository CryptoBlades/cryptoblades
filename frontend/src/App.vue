<template>
  <div class="app">
    <nav-bar />
    <character-bar v-if="!featureFlagStakeOnly && currentCharacterId !== null" />
    <div class="content dark-bg-text">
      <router-view v-if="canShowApp" />
    </div>
    <div class="content dark-bg-text" v-if="!canShowApp">
      {{$t('app.cantView')}}
    </div>
    <div class="fullscreen-warning" v-if="!hideWalletWarning && (showMetamaskWarning || showNetworkError)">
      <div class="starter-panel">
        <div class="tob-bg-img promotion-decoration">
          <img class="vertical-decoration bottom" src="./assets/border-element.png">
        </div>
        <span class="starter-panel-heading">{{ $t('app.warning.title') }}</span>
        <div class="center">
          <big-button class="button common-width-button"
          :mainText="$t('app.warning.buttons.addMetamask')" @click="startOnboarding" v-if="showMetamaskWarning" />
          <big-button class="button common-width-button"
          :mainText="$t('app.warning.buttons.network')" @click="configureMetamask" v-if="showNetworkError" />
          <big-button class="button common-width-button"
          :mainText="$t('app.warning.buttons.hide')" @click="toggleHideWalletWarning" />
        </div>
      </div>
    </div>
    <div
      class="fullscreen-warning"
      v-if="!hideWalletWarning && !showMetamaskWarning && (errorMessage || (ownCharacters.length === 0 && skillBalance === '0' && !hasStakedBalance))"
    >
      <div class="starter-panel">
        <img class="mini-icon-starter" src="./assets/placeholder/sword-placeholder-6.png" alt="cross swords" srcset="" />
        <span class="starter-panel-heading">{{ errorMessage || $t('app.warning.start') }}</span>
        <img class="mini-icon-starter" src="./assets/placeholder/sword-placeholder-6.png" alt="cross swords" srcset="" />
        <div>
          <big-button class="button mm-button" :mainText="$t('app.warning.buttons.confMetamask')" @click="configureMetamask" />
          <big-button v-bind:class="[isConnecting ? 'disabled' : '']" class="button mm-button"
          :mainText="$t('app.warning.buttons.startMetamask')" @click="connectMetamask" />
        </div>
        <div class="seperator"></div>
        <div class="instructions-list">
          <p>{{ $t('app.warning.message.' + currentChain + '.instructions', {recruitCost: this.recruitCost}) }}</p>
          <ul class="unstyled-list">
            <li>
              <span v-html="$t('app.warning.message.' + currentChain + '.inst1', {link1: getExchangeTransakUrl()})"></span>
            </li>
            <li>
              <span v-html="$t('app.warning.message.' + currentChain + '.inst2', {link1: getExchangeUrl})"></span>
            </li>
            <li>
              <span v-html="$t('app.warning.message.' + currentChain + '.inst3')"></span>
            </li>
            <li>
              <span v-html="$t('app.warning.message.' + currentChain + '.inst4')"></span>
            </li>
          </ul>
          <p>
            {{ $t('app.warning.message.happyEarning') }}
          </p>
        </div>
        <div class="seperator"></div>
        <small-button class="button mm-button" @click="toggleHideWalletWarning" :text="$t('app.warning.buttons.hide')" />
      </div>
      <div class="ad-container">
        <Adsense v-if="showAds && !isMobile()"
          data-ad-client="ca-pub-6717992096530538"
          data-ad-slot="5115599573"
          data-ad-format="auto"
          data-full-width-responsive="yes"
          />
      </div>
    </div>
  </div>
</template>

<script>
import BN from 'bignumber.js';

import {mapState, mapActions, mapGetters, mapMutations} from 'vuex';
import _ from 'lodash';
import Vue from 'vue';
import Events from './events';
import MetaMaskOnboarding from '@metamask/onboarding';
import BigButton from './components/BigButton.vue';
import SmallButton from './components/SmallButton.vue';
import NavBar from './components/NavBar.vue';
import CharacterBar from './components/CharacterBar.vue';
import { apiUrl } from './utils/common';
import i18n from './i18n';
import { getConfigValue } from './contracts';
import '@/mixins/general';
import config from '../app-config.json';
import { addChainToRouter } from '@/utils/common';

Vue.directive('visible', (el, bind) => {
  el.style.visibility = bind.value ? 'visible' : 'hidden';
});

export default {
  inject: ['web3', 'featureFlagStakeOnly', 'expectedNetworkId', 'expectedNetworkName'],
  components: {
    NavBar,
    CharacterBar,
    BigButton,
    SmallButton,
  },

  data: () => ({
    errorMessage: '',
    hideWalletWarning: false,
    showAds: false,
    isConnecting: false,
    recruitCost: '',
    isOptions: false,
  }),

  computed: {
    ...mapState(['skillBalance', 'defaultAccount', 'currentNetworkId', 'currentCharacterId', 'staking']),
    ...mapGetters(['contracts', 'ownCharacters', 'ownGarrisonCharacters', 'getExchangeUrl',
      'availableStakeTypes', 'availableNftStakeTypes', 'hasStakedBalance']),

    canShowApp() {
      return (this.contracts !== null && !_.isEmpty(this.contracts) && !this.showNetworkError) || (this.isOptions);
    },

    showMetamaskWarning() {
      return !this.web3.currentProvider;
    },

    showNetworkError() {
      return this.expectedNetworkId && this.currentNetworkId !== null && this.currentNetworkId !== this.expectedNetworkId;
    },
    currentChain(){
      return localStorage.getItem('currentChain');
    }
  },

  watch: {
    defaultAccount(account) {
      this.web3.eth.defaultAccount = account;
    },

    async currentCharacterId() {
      await this.updateCharacterStamina(this.currentCharacterId);
    },
    $route(to) {
      // react to route changes
      this.checkChainAndParams();
      if(to.path === '/options') {
        return this.isOptions = true;
      } else this.isOptions = false;

      window.gtag('event', 'page_view', {
        page_title: to.name,
        page_location: to.fullPath,
        page_path: to.path,
        send_to: 'G-C5RLX74PEW',
      });
    },
  },

  methods: {
    ...mapActions({ initializeStore: 'initialize' }),
    ...mapActions([
      'fetchCharacterStamina',
      'pollAccountsAndNetwork',
      'setupWeaponDurabilities',
      'fetchStakeDetails',
      'fetchWaxBridgeDetails',
      'fetchRewardsClaimTax',
      'configureMetaMask'
    ]),
    ...mapGetters([
      'getExchangeTransakUrl'
    ]),
    ...mapMutations(['updateCurrentChainSupportsMerchandise', 'updateCurrentChainSupportsPvP', 'updateCurrentChainSupportsQuests']),
    async checkChainAndParams(){
      const currentChain = localStorage.getItem('currentChain') || 'BSC';
      const paramChain = this.$router.currentRoute.query.chain;
      const supportedChains = config.supportedChains;

      if(!paramChain){
        localStorage.setItem('currentChain', currentChain);
        addChainToRouter(currentChain);
      }

      //add chain as query param if chain unchanged
      if(currentChain === paramChain || !paramChain){
        localStorage.setItem('currentChain', currentChain);
        addChainToRouter(currentChain);
      }

      //set chain in localStorage & MM from query param; check if supported
      else if (currentChain !== paramChain && supportedChains.includes(paramChain)){
        localStorage.setItem('currentChain', paramChain);
        await this.configureMetaMask(+getConfigValue('VUE_APP_NETWORK_ID'));
      }
      this.updateCurrentChainSupportsMerchandise();
      this.updateCurrentChainSupportsPvP();
      this.updateCurrentChainSupportsQuests();
    },
    async updateCharacterStamina(id) {
      if (this.featureFlagStakeOnly) return;

      if (id !== null) {
        await this.fetchCharacterStamina(id);
      }
    },

    checkStorage() {
      this.hideWalletWarning = localStorage.getItem('hideWalletWarning') === 'true';
      this.showAds =  localStorage.getItem('show-ads') === 'true';
    },
    async initializeRecruitCost() {
      const recruitCost = await this.contracts.CryptoBlades.methods.mintCharacterFee().call({ from: this.defaultAccount });
      const skillRecruitCost = await this.contracts.CryptoBlades.methods.usdToSkill(recruitCost).call();
      this.recruitCost = BN(skillRecruitCost)
        .div(BN(10).pow(18))
        .toFixed(4);
    },
    data() {
      return {
        recruitCost: this.recruitCost,
      };
    },

    async startOnboarding() {
      const onboarding = new MetaMaskOnboarding();
      onboarding.startOnboarding();
    },
    async configureMetamask() {
      await this.configureMetaMask(+getConfigValue('VUE_APP_NETWORK_ID'));
    },

    async connectMetamask() {
      const web3 = this.web3.currentProvider;
      this.isConnecting = true;
      this.errorMessage = i18n.t('app.warning.errorMessage.connecting');
      web3
        .request({ method: 'eth_requestAccounts' })
        .then(() => {
          this.errorMessage = i18n.t('app.warning.errorMessage.success');
          this.isConnecting = false;

          this.initializeStore();
          this.toggleHideWalletWarning();
        })
        .catch(() => {
          this.errorMessage = i18n.t('app.warning.errorMessage.error');
          this.isConnecting = false;
        });
    },

    toggleHideWalletWarning() {
      this.hideWalletWarning = !this.hideWalletWarning;
      if (this.hideWalletWarning) localStorage.setItem('hideWalletWarning', 'true');
      else localStorage.setItem('hideWalletWarning', 'false');

      Events.$emit('setting:hideWalletWarning', { value: this.hideWalletWarning });
    },

    async showWarningDialog() {
      await new Promise((resolve) => setTimeout(resolve, 7500));

      if (
        this.hideWalletWarning &&
        !this.showMetamaskWarning &&
        (this.errorMessage || this.showNetworkError || (this.ownCharacters.length === 0 && this.skillBalance === '0' && !this.hasStakedBalance))
      ) {
        this.$dialog.notify.warning(i18n.t('app.warning.message.hideWalletWarning'),
          {
            timeout: 0,
          },
        );
      }
    },

    async checkNotifications() {
      const response = await fetch(apiUrl('static/notifications'));
      const notifications = await response.json();

      const lastHash = localStorage.getItem('lastnotification');
      let shouldContinue = true;

      notifications.forEach((notification) => {
        if (!shouldContinue) return;

        if (lastHash === notification.hash) {
          shouldContinue = false;
          return;
        }

        this.$dialog.notify.warning(
          `${notification.title}
          <br>
          <a href="${notification.link}" target="_blank">Check it out!</a>
          `,
          {
            timeout: 300000,
          },
        );
      });

      localStorage.setItem('lastnotification', notifications[0].hash);
    },
  },

  mounted() {
    this.checkStorage();

    Events.$on('setting:hideRewards', () => this.checkStorage());
    Events.$on('setting:useGraphics', () => this.checkStorage());
    Events.$on('setting:hideWalletWarning', () => this.checkStorage());
    // Events.$on('garrison:characterReceived', (e) => {
    //   this.$dialog.notify.warning(`${i18n.t('app.warning.message.newCharacter')} ID: ${e.id} ${i18n.t('app.warning.message.inGarrison')}!`,
    //     {
    //       timeout: 5000,
    //     },
    //   );
    // });

    document.body.addEventListener('click', (e) => {
      const tagname = e.target.getAttribute('tagname');
      if (!tagname) return;

      if (e.target.nodeName === 'BUTTON') {
        window.gtag('event', 'button_clicked', {
          value: tagname,
        });
      }

      if (e.target.className.includes('gtag-link-others')) {
        window.gtag('event', 'nav', {
          event_category: 'navigation',
          event_label: 'navbar',
          value: tagname,
        });
      }
    });
    this.showWarningDialog();
    if(this.hideWalletWarning) {
      this.configureMetamask();
    }
  },

  async created() {
    this.checkChainAndParams();
    try {
      await this.initializeStore();
    } catch (e) {
      this.errorMessage = i18n.t('app.warning.errorMessage.welcome');
      if (e.code === 4001) {
        this.errorMessage = i18n.t('app.warning.errorMessage.error');
      }

      console.error(e);
      throw e;
    }

    this.pollCharactersStaminaIntervalId = setInterval(async () => {
      this.ownCharacters.forEach(async (c) => {
        await this.updateCharacterStamina(c.id);
      });
      this.ownGarrisonCharacters.forEach(async (c) => {
        await this.updateCharacterStamina(c.id);
      });
    }, 3000);

    this.availableStakeTypes.forEach((item) => {
      this.fetchStakeDetails({ stakeType: item });
    });

    this.availableNftStakeTypes.forEach((item) => {
      this.fetchStakeDetails({ stakeType: item });
    });

    this.slowPollIntervalId = setInterval(async () => {
      await Promise.all([
        this.setupWeaponDurabilities(),
        this.fetchWaxBridgeDetails(),
        this.fetchRewardsClaimTax(),
      ]);
    }, 10 * 1000);

    this.doPollAccounts = true;
    const pollAccounts = async () => {
      if (!this.doPollAccounts) return;

      try {
        await this.pollAccountsAndNetwork();
      } catch (e) {
        console.error(e);
      }

      setTimeout(pollAccounts, 200);
    };

    pollAccounts();

    if (!localStorage.getItem('useGraphics')) localStorage.setItem('useGraphics', 'false');
    if (!localStorage.getItem('hideRewards')) localStorage.setItem('hideRewards', 'false');
    if (!localStorage.getItem('hideWalletWarning')) localStorage.setItem('hideWalletWarning', 'false');
    if (!localStorage.getItem('fightMultiplier')) localStorage.setItem('fightMultiplier', '1');

    this.checkNotifications();
    this.initializeRecruitCost();
  },

  beforeDestroy() {
    this.doPollAccounts = false;
    clearInterval(this.pollCharacterStaminaIntervalId);
    clearInterval(this.slowPollIntervalId);
  },
};
</script>

<style>

ul, li {list-style-type: none;}

button.btn.button.main-font.dark-bg-text.encounter-button.btn-styled.btn-primary > h1 {
  font-weight: 600;
  text-align: center;
}

hr.hr-divider {
  border-top: 1px solid #9e8a57;
  margin-bottom: 0.5rem !important;
}
body {
  margin: 0;
  background: linear-gradient(45deg, rgba(20, 20, 20, 1) 100%, rgba(36, 39, 32, 1) 100%);
}

.no-margin {
  margin: 0;
}

.bold {
  font-weight: 1000;
}

.main-font {
  font-family: 'Roboto', sans-serif;
}

.info-divider {
  width: 100%;
  position: relative;
  top: -10px;
}

.title-bg-text {
  color: #9e8a57;
}

.dark-bg-text {
  color: #9e8a57;
}

.body {
  max-height: calc(100vh - 56px - 160px);
}

button,
.pointer {
  cursor: pointer;
}

.blank-slate {
  width: calc(100vw - 36px);
  height: calc(100vh - 56px);

  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;

  font-size: 2rem;
  text-align: center;
}

.error {
  color: red;
}

.fire,
.str {
  color: red;
}

.earth,
.dex {
  color: green;
}

.water,
.int {
  color: cyan;
}

.lightning,
.cha {
  color: yellow;
}

.summary-text {
  font-size: 0.8em;
  color: grey;
}

.fire-icon,
.str-icon {
  color: red;
  content: url('assets/elements/fire.png');
  width: 1em;
  height: 1em;
}

.earth-icon,
.dex-icon {
  color: green;
  content: url('assets/elements/earth.png');
  width: 1em;
  height: 1em;
}

.water-icon,
.int-icon {
  color: cyan;
  content: url('assets/elements/water.png');
  width: 1em;
  height: 1em;
}

.lightning-icon,
.cha-icon {
  color: yellow;
  content: url('assets/elements/lightning.png');
  width: 1em;
  height: 1em;
}

.loading-container {
  position: absolute;
  display: flex;
  justify-content: center;
  align-content: center;
  width: 100%;
  padding-top: 50%;
  font-size: 2rem;
  z-index: 541;
  color: #be9a2c;
}

button.close {
  color: #9e8a57 !important;
}

.mm-button{
  margin: 5px;
  font-size: clamp(24px, 2vw, 40px);
}
.mm-button > h1 {
   font-size: clamp(24px, 2vw, 40px);
}

.btn {
  border: 2px solid #6c5f38 !important;
  border-radius: 0.1em !important;
}

.common-width-button {
  margin: 0.8rem;
  width: 22%;
}

.btn.disabled,
.btn:disabled {
  cursor: auto;
}

.btn:not(.disabled):not(:disabled):hover {
  border: 2px solid #9e8a57 !important;
  background: rgb(61, 61, 64);
  background: linear-gradient(180deg, rgba(51, 51, 54, 1) 0%, rgba(44, 47, 50, 1) 5%, rgba(44, 58, 65, 1) 100%);
}

.btn-primary {
  color: #9e8a57 !important;
  background: rgb(31, 31, 34);
  background: linear-gradient(180deg, rgba(31, 31, 34, 1) 0%, rgba(24, 27, 30, 1) 5%, rgba(24, 38, 45, 1) 100%);
}

.btn-outline-primary {
  color: #9e8a57 !important;
}

.modal-header {
  color: #9e8a57 !important;
  background: rgb(31, 31, 34);
  background: linear-gradient(180deg, rgba(31, 31, 34, 1) 0%, rgba(24, 27, 30, 1) 5%, rgba(24, 38, 45, 1) 100%);
  border-color: #9e8a57 !important;
}

.modal-body {
  color: #9e8a57 !important;
  background: linear-gradient(180deg, rgba(31, 31, 34, 1) 0%, rgba(24, 27, 30, 1) 5%, rgba(24, 38, 45, 1) 100%);
}

.modal-footer {
  color: #9e8a57 !important;
  background: linear-gradient(180deg, rgba(31, 31, 34, 1) 0%, rgba(24, 27, 30, 1) 5%, rgba(24, 38, 45, 1) 100%);
  border-color: #9e8a57 !important;
}

.b-pagination > li > .page-link {
  color: #9e8a57;
  background: linear-gradient(180deg, rgba(31, 31, 34, 1) 0%, rgba(24, 27, 30, 1) 5%, rgba(24, 38, 45, 1) 100%);
  border-color: #9e8a576e;
}

.b-pagination > .page-item.active > .page-link {
  color: #9e8a57;
  background: linear-gradient(180deg, rgba(31, 31, 34, 1) 0%, rgba(24, 27, 30, 1) 5%, rgba(24, 38, 45, 1) 100%);
  border-color: #9e8a57;
}

.b-pagination > .page-item.disabled > .page-link {
  color: #b3b0a72a;
  background: linear-gradient(180deg, rgba(31, 31, 34, 1) 0%, rgba(24, 27, 30, 1) 5%, rgba(24, 38, 45, 1) 100%);
  border-color: #9e8a576e;
}
.nav-tabs {
  border-bottom: 2px solid #9e8a57 !important;
}

.nav-tabs .nav-link.active {
  color: #9e8a57 !important;
  border: 2px solid #9e8a57 !important;
  background: linear-gradient(180deg, rgba(31, 31, 34, 1) 0%, rgba(24, 27, 30, 1) 5%, rgba(24, 38, 45, 1) 100%);
}

.nav-tabs .nav-link:hover,
.nav-tabs .nav-link:focus {
  border-color: #9e8a57 #9e8a57 #9e8a57 !important;
}

.outline {
  color: #000;
  text-shadow: -1px 0 #fff, 0 1px #fff, 1px 0 #fff, 0 -1px #fff;
}

.black-outline {
  text-shadow: -1px 0 #000, 0 1px #000, 1px 0 #000, 0 -1px #000;
}

div.bg-success {
  background-color: #19682b !important;
}

.nav.nav-pills .nav-link {
  color: #9e8a57 !important;
  border: 2px solid #6c5f38;
  border-radius: 0.1em;
  background: rgb(31, 31, 34);
  background: linear-gradient(180deg, rgba(31, 31, 34, 1) 0%, rgba(24, 27, 30, 1) 5%, rgba(24, 38, 45, 1) 100%);
}

.nav.nav-pills .nav-link.active {
  border: 2px solid #9e8a57 !important;
  background: rgb(61, 61, 64);
  background: linear-gradient(180deg, rgba(51, 51, 54, 1) 0%, rgba(44, 47, 50, 1) 5%, rgba(44, 58, 65, 1) 100%);
}
</style>
<style scoped>
.app {
  margin: 0;
}

.content {
  padding: 0 1em;
  height: auto;
  background: linear-gradient(45deg, rgba(20, 20, 20, 1) 100%, rgba(36, 39, 32, 1) 100%);
  margin: auto;
}

.fullscreen-warning {
  position: fixed;
  top: 0;
  left: 0;
  background: rgba(0, 0, 0, 0.425);
  height: 100vh;
  width: 100vw;
  display: flex;
  justify-content: center;
  align-items: center;
  flex-direction: column;
  font-size: 3rem;
  color: #fff;
}

.starter-panel {
  width: 100%;
  max-width: 28em;
  background: rgba(0, 0, 0, 1);
  box-shadow: 0 2px 4px #ffffff38;
  border: 1px solid #9e8a57;
  border-radius: 5px;
  padding: 0.5em;
  margin: auto;
  text-align: center;
  overflow: auto auto;
}

.starter-panel-heading {
  margin-left: 15px;
  font-size: clamp(18px, 2vw, 45px);
  color: #9e8a57;
}

.starter-msg {
  font-size: 0.85em;
}
.instructions-list {
  text-align: start;
  padding: 15px;
  font-size: clamp(18px, 2vw, 24px);
}

.unstyled-list {
  list-style-type: none;
  padding-left: clamp(10px,2vw,40px);
}
.seperator {
  border: 1px solid #9e8a57;
  border-radius: 3px;
  width: 100%;
}

.mini-icon-starter {
  width: clamp(50px, 4vw, 100px);
  margin: 5px;
}

.vertical-decoration {
  width: 50%;
}

.center {
  display: flex;
  justify-content: center;
  align-items: center;
}

.border-main {
  border: 1px solid #9e8a57;
}

@media all and (max-width: 767.98px) {
  .content {
    padding: 10px;
  }
  .dark-bg-text {
    width: 100%;
  }
  .vertical-decoration {
    width: 100%;
  }
}
</style>
