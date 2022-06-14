<template>
  <div class="app">
    <nav-bar :isToggled="toggleSideBar"/>
    <div class="content bg-dark">
      <b-row>
        <character-bar :isToggled="toggleSideBar" v-if="currentCharacterId !== null"/>
        <b-col style="padding-left: 0;" :class="renderPageDisplay()">
          <router-view v-if="canShowApp" />
        </b-col>
        <WeaponRowGrid v-if="showWeapon" v-model.lazy="currentWeaponId" :checkForDurability="true"/>
      </b-row>
    </div>
    <div class="content bg-dark" v-if="!canShowApp && !showMetamaskWarning">
      <div class="outcome">
        <i class="fas fa-spinner fa-spin"></i>
      </div>
    </div>
    <div class="fullscreen-warning" v-if="showMetamaskWarning">
      <div class="starter-panel">
        <div class="tob-bg-img promotion-decoration">
          <img class="vertical-decoration bottom" src="./assets/border-element.png">
        </div>
        <span class="starter-panel-heading">{{ $t('app.warning.title') }}</span>
        <div class="center">
          <big-button class="button common-width-button"
          :mainText="$t('app.warning.buttons.addMetamask')" @click="startOnboarding" v-if="showMetamaskWarning" />
          <big-button class="button common-width-button"
          mainText="Wallet Connect" @click="walletConnectOnboarding()" />
        </div>
      </div>
    </div>
    <div
      class="fullscreen-warning"
      v-if="!hideWalletWarning && !showMetamaskWarning && (errorMessage || (ownCharacters.length === 0 && skillBalance === '0'))"
    >
      <div class="starter-panel">
        <img class="mini-icon-starter" src="./assets/placeholder/sword-placeholder-6.png" alt="cross swords" srcset="" />
        <span class="starter-panel-heading">{{ errorMessage || $t('app.warning.start') }}</span>
        <img class="mini-icon-starter" src="./assets/placeholder/sword-placeholder-6.png" alt="cross swords" srcset="" />
        <div>
          <big-button class="button mm-button" :mainText="$t('app.warning.buttons.confMetamask')" @click="configureMetamask" />
          <big-button :class="[isConnecting || isConnected ? 'disabled' : '']" class="button mm-button"
          :mainText="$t('app.warning.buttons.startMetamask')" @click="connectMetamask" />
        </div>
        <div class="seperator"></div>
        <div class="instructions-list">
          <p>{{ $t('app.warning.message.' + currentChain + '.instructions', {recruitCost: this.recruitCost}) }}</p>
          <ul class="unstyled-list">
            <li>
              <span v-html="$t('app.warning.message.' + currentChain + '.inst1', {link1: getExchangeTransakUrl})"></span>
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
      <div v-if="showAds && !isMobile()" class="ad-container">
      <script2 src="https://coinzillatag.com/lib/display.js"></script2>
        <div class="coinzilla" data-zone="C-541621de2f7bb717603"></div>
          <script2>
                window.coinzilla_display = window.coinzilla_display || [];
                var c_display_preferences = {};
                c_display_preferences.zone = "541621de2f7bb717603";
                c_display_preferences.width = "728";
                c_display_preferences.height = "90";
                coinzilla_display.push(c_display_preferences);
          </script2>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
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
import WeaponRowGrid from './components/smart/WeaponRowGrid.vue';
import { apiUrl } from './utils/common';
import i18n from './i18n';
import { getConfigValue } from './contracts';
import '@/mixins/general';
import config from '../app-config.json';
import { addChainToRouter } from '@/utils/common';
import Web3 from 'web3';
import WalletConnectProvider from '@walletconnect/web3-provider';
import { Contracts, ICharacter } from '@/interfaces';
import { Accessors } from 'vue/types/options';

Vue.directive('visible', (el, bind) => {
  el.style.visibility = bind.value ? 'visible' : 'hidden';
});

interface RPCS {
  [key: number]: string;
}
interface Data {
  errorMessage: string,
  hideWalletWarning: boolean,
  showAds: boolean,
  isConnecting: boolean,
  isConnected: boolean,
  recruitCost: string,
  showWeapon: boolean,
  currentWeaponId: null | number,
  weaponId: null | number,
  toggleSideBar: boolean,
  currentPath: string,
  showMetamaskWarning: boolean,
  pollCharacterStaminaIntervalId: ReturnType<typeof setInterval> | null,
  slowPollIntervalId: ReturnType<typeof setInterval> | null,
  doPollAccounts: boolean,
}

interface StoreMappedState {
  skillBalance: string,
  defaultAccount: string | null,
  currentNetworkId: number,
  currentCharacterId: number,
  web3: Web3,
  staking: string,
}

interface StoreMappedGetters {
  contracts: Contracts,
  ownCharacters: ICharacter[],
  ownGarrisonCharacters: ICharacter[],
  getExchangeUrl: string,
  getExchangeTransakUrl: string,
}

interface StoreMappedActions {
  initializeStore: () => void,
  fetchCharacterStamina: (characterId: number) => void,
  pollAccountsAndNetwork: () => void,
  configureMetaMask: () => Promise<void>,
}

interface StoreMappedMutations {
  setWeb3: (web3: Web3) => void,
  updateCurrentChainSupportsPvP: () => void,
  updateCurrentChainSupportsQuests: () => void,
}

interface Notification {
  hash: string,
  title: string,
  link: string,
}

export default Vue.extend({
  components: {
    NavBar,
    CharacterBar,
    BigButton,
    SmallButton,
    WeaponRowGrid,
  },

  data() {
    return {
      errorMessage: '',
      hideWalletWarning: false,
      showAds: false,
      isConnecting: false,
      isConnected: false,
      recruitCost: '',
      showWeapon: false,
      currentWeaponId: null,
      weaponId: null,
      toggleSideBar: false,
      currentPath: '',
      showMetamaskWarning: false,
      pollCharacterStaminaIntervalId: null,
      slowPollIntervalId: null,
      doPollAccounts: false
    } as Data;
  },

  computed: {
    ...(mapState(['skillBalance', 'defaultAccount', 'currentNetworkId', 'currentCharacterId', 'staking', 'web3']) as Accessors<StoreMappedState>),
    ...(mapGetters(['contracts', 'ownCharacters', 'ownGarrisonCharacters', 'getExchangeUrl', 'getExchangeTransakUrl']) as Accessors<StoreMappedGetters>),

    canShowApp(): boolean {
      return (this.contracts !== null && !_.isEmpty(this.contracts)) || this.isOptions;
    },

    currentChain(): string {
      return localStorage.getItem('currentChain') || '';
    },

    isWalletConnect(): boolean {
      return localStorage.getItem('walletconnect') !== null;
    },

    isOptions(): boolean {
      return (this as any).$route.path === '/options';
    },
  },

  watch: {
    defaultAccount(account) {
      this.web3.eth.defaultAccount = account;
    },

    async currentCharacterId() {
      await this.updateCharacterStamina(this.currentCharacterId);
    },
  },

  methods: {
    ...mapActions([
      'initializeStore',
      'fetchCharacterStamina',
      'pollAccountsAndNetwork',
      'configureMetaMask',
    ]) as StoreMappedActions,
    ...mapMutations([
      'setWeb3',
      'updateCurrentChainSupportsPvP',
      'updateCurrentChainSupportsQuests'
    ])as StoreMappedMutations,
    async checkChainAndParams(){
      const currentChain = localStorage.getItem('currentChain') || 'BNB';

      const paramChain = (this as any).$router.currentRoute.query.chain;
      const supportedChains = window.location.href.startsWith('https://test') ? config.testSupportedChains : config.supportedChains;

      if(!paramChain){
        localStorage.setItem('currentChain', currentChain);
        addChainToRouter(currentChain);
      }

      //add chain as query param if chain unchanged
      if(currentChain === paramChain || !paramChain){
        localStorage.setItem('currentChain', currentChain);
        addChainToRouter(currentChain);
      }

      //if user has an unsupported chain set (e.g. BSC instead of BNB) in storage
      if(!supportedChains.includes(currentChain)){
        localStorage.setItem('currentChain', 'BNB');
        addChainToRouter('BNB');
      }

      //set chain in localStorage & MM from query param; check if supported
      else if (currentChain !== paramChain && supportedChains.includes(paramChain)){
        localStorage.setItem('currentChain', paramChain);
        if(!this.isWalletConnect) await this.configureMetaMask();
      }
      this.updateCurrentChainSupportsPvP();
      this.updateCurrentChainSupportsQuests();
    },
    async updateCharacterStamina(id: number) {
      if (id !== null) {
        await this.fetchCharacterStamina(id);
      }
    },

    checkStorage() {
      this.hideWalletWarning = localStorage.getItem('hideWalletWarning') === 'true';
      if (process.env.NODE_ENV === 'development') this.showAds = false;
      else this.showAds = localStorage.getItem('show-ads') === 'true';
    },
    async initializeRecruitCost() {
      if(!this.contracts.CryptoBlades) return;
      const recruitCost = await this.contracts.CryptoBlades.methods.getMintCharacterFee().call({ from: this.defaultAccount });
      const skillRecruitCost = await this.contracts.CryptoBlades.methods.usdToSkill(recruitCost).call({ from: this.defaultAccount });
      this.recruitCost = new BN(skillRecruitCost)
        .div(new BN(10).pow(18))
        .toFixed(4);
    },

    async startOnboarding() {
      const onboarding = new MetaMaskOnboarding();
      onboarding.startOnboarding();
    },
    async configureMetamask() {
      await this.configureMetaMask();
    },

    async connectMetamask() {
      const web3 = new Web3(Web3.givenProvider);
      this.setWeb3(web3);
      this.isConnecting = true;
      this.errorMessage = i18n.t('app.warning.errorMessage.connecting').toString();
      //test connection
      web3.eth
        .requestAccounts()
        .then(() => {
          this.errorMessage = i18n.t('app.warning.errorMessage.success').toString();
          this.isConnecting = false;
          this.isConnected = true;

          this.initializeStore();
        })
        .catch(() => {
          this.errorMessage = i18n.t('app.warning.errorMessage.error').toString();
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
        (this.errorMessage || (this.ownCharacters.length === 0 && this.skillBalance === '0'))
      ) {
        (this as any).$dialog.notify.warning(i18n.t('app.warning.message.hideWalletWarning'),
          {
            timeout: 0,
          },
        );
      }
    },

    renderPageDisplay(): string{
      let toDisplay;

      if(this.currentCharacterId !== null){
        if(this.toggleSideBar){
          toDisplay = 'can-show-app';
        }else{
          toDisplay = 'col-xl-10 col-lg-9 col-md-9 col-sm-10 cols-11 set-normal';
        }
      }else{
        toDisplay = 'col-xl-12 col-lg-12 col-md-12 col-sm-12 cols-12 set-normal';
      }

      return toDisplay;
    },

    async checkNotifications() {
      const response = await fetch(apiUrl('static/notifications'));
      const notifications = await response.json();

      const lastHash = localStorage.getItem('lastnotification');
      let shouldContinue = true;

      notifications.forEach((notification: Notification) => {
        if (!shouldContinue) return;

        if (lastHash === notification.hash) {
          shouldContinue = false;
          return;
        }

        (this as any).$dialog.notify.warning(
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

    initializeSettings(){
      if (!localStorage.getItem('useGraphics')) localStorage.setItem('useGraphics', 'false');
      if (!localStorage.getItem('hideRewards')) localStorage.setItem('hideRewards', 'false');
      if (!localStorage.getItem('hideWalletWarning')) localStorage.setItem('hideWalletWarning', 'false');
      if (!localStorage.getItem('fightMultiplier')) localStorage.setItem('fightMultiplier', '1');
    },
    async connectWalletConnect(){
      const rpcs = {} as RPCS;
      config.supportedChains.forEach((chain) => {
        const chainId = getConfigValue('VUE_APP_NETWORK_ID', chain);
        rpcs[chainId] = getConfigValue('rpcUrls',chain)[0];
      });
      const provider = new WalletConnectProvider({
        rpc: rpcs,
        chainId: JSON.parse(localStorage.getItem('walletconnect') || '').chainId,
      });

      //  Enable session (triggers QR Code modal)
      await provider.enable();
      this.setWeb3(new Web3(provider as any));
    },
    walletConnectOnboarding(){
      (this as any).$router.push({ name: 'options' });
      this.showMetamaskWarning = false;
      this.hideWalletWarning = true;
    }
  },

  async mounted() {
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
    Events.$on('weapon-inventory', (bol: boolean) =>{
      this.showWeapon = bol;
    });

    Events.$on('chooseweapon', (id: number) =>{
      this.weaponId = id;
    });

    Events.$on('toggle-sideBar', (bol: boolean) =>{
      this.toggleSideBar = bol;
    });
    this.showWarningDialog();
    if(this.hideWalletWarning) {
      this.configureMetamask();
    }
  },
  async created() {
    this.initializeSettings();
    this.checkChainAndParams();
    this.checkStorage();

    if(!this.isWalletConnect){
      await this.connectMetamask();
    }
    else{
      this.showMetamaskWarning = false;
      this.hideWalletWarning = true;
      await this.connectWalletConnect();
    }
    if(!this.web3.currentProvider){
      this.showMetamaskWarning = true;
    }
    try {
      await this.initializeStore();
    } catch (e: any) {
      this.errorMessage = i18n.t('app.warning.errorMessage.welcome').toString();
      if (e.code === 4001) {
        this.errorMessage = i18n.t('app.warning.errorMessage.error').toString();
      }

      console.error(e);
      throw e;
    }

    this.pollCharacterStaminaIntervalId = setInterval(async () => {
      this.ownCharacters.forEach(async (c) => {
        await this.updateCharacterStamina(c.id);
      });
      this.ownGarrisonCharacters.forEach(async (c) => {
        await this.updateCharacterStamina(c.id);
      });
    }, 250000);

    this.doPollAccounts = true;
    const pollAccounts = async () => {
      if (!this.doPollAccounts) return;

      try {
        await this.pollAccountsAndNetwork();
      } catch (e) {
        console.error(e);
      }
    };

    pollAccounts();

    this.checkNotifications();
    this.initializeRecruitCost();
  },

  beforeDestroy() {
    this.doPollAccounts = false;
    if(this.pollCharacterStaminaIntervalId) clearInterval(this.pollCharacterStaminaIntervalId);
    if(this.slowPollIntervalId) clearInterval(this.slowPollIntervalId);
  },

});
</script>

<style lang="scss">

@font-face {
    font-family: 'Trajan';
    src: url('./assets/fonts/Trajan.ttf');
    font-weight: normal;
    font-style: normal;
}

@import url('https://fonts.googleapis.com/css2?family=Cardo:ital,wght@0,400;0,700;1,400&display=swap');
@import url('https://fonts.googleapis.com/css2?family=Oswald:wght@200;300;400;500;600;700&display=swap');
@import '@/scss/app.scss';


button.btn.button.main-font.dark-bg-text.encounter-button.btn-styled.btn-primary > h1 {
  font-weight: 600;
  text-align: center;
}

.app{
  width: auto;
}


.set-normal{
  margin-left: auto;
  margin-right: auto;
  transition: 1s width;
  padding: 0px;
}


hr.hr-divider {
  border-top: 1px solid #9e8a57;
  margin-bottom: 0.5rem !important;
}
body {
  margin: 0;
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

.alt-text {
  font-family: 'Oswald', sans-serif;
}

.info-divider {
  width: 100%;
  position: relative;
  top: -10px;
}


button,
.pointer {
  cursor: pointer;
}

.footer-btn{
  text-align: center;
  padding-top: 2.5em;
  display: flex;
  justify-content: center;
  align-items: center;
  flex-direction: column;
}

.footer-btn > .close-btn{
  width: 100%;
  display: flex;
  justify-content: center;
  align-items: center;
  padding-top: 0.8em;
  padding-bottom: 0.8em;
  font-family: Roboto;
  background-color: #EDCD90;
  border-radius: 2px;
  border: none;
  color: rgb(26, 26, 26);
  text-transform: capitalize;
}

.close-btn.cancel{
  background-color: #e9be6edc;
}

.blank-slate {
  width: calc(100vw - 36px);
  height: calc(100vh - 120px);
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;

  font-size: 2rem;
  text-align: center;
}

.error {
  color: red;
  overflow: hidden;
  max-width: 75vw;
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


.tooltip{
  z-index: 1051;
}

.popover .arrow{
  display: none;
}


.fire-icon,.str-icon {
  color: red;
  content: url('assets/elements/icon-fire.png');
  width: 1em;
  height: 1em;
}

.earth-icon,
.dex-icon {
  color: green;
  content: url('assets/elements/icon-earth.png');
  width: 1em;
  height: 1em;
}

.water-icon,
.int-icon {
  color: cyan;
  content: url('assets/elements/icon-water.png');
  width: 1em;
  height: 1em;
}

.lightning-icon,
.cha-icon {
  color: yellow;
  content: url('assets/elements/icon-thunder.png');
  width: 1em;
  height: 1em;
}
.pwr-icon {
  color: yellow;
  content: url('assets/elements/power-icon.svg');
  width: 0.9em;
  height: 0.9em;
}

.bonus-power-icon {
  content: url('assets/navbar-icons/blacksmith-icon.png');
  width: 0.8em;
  height: 0.8em;
  padding-left: 1px;
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

.clear-filters-button {
  height: fit-content;
  display: flex;
  flex-direction: row;
  align-self: flex-end;
  margin:0 15px;
  margin-bottom: 15px;
  border-radius: 5px;
  border:1px solid #EDCD90;
  background-color: rgba(255, 255, 255, 0);
  font-family: Roboto;
  color: #fff;
  padding: 5px 20px;
}

.clear-filters-button:hover{
  background: rgba(0, 0, 0, 0) !important;
  border: 1px solid #fff !important;
}

.btn {
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
.btn-primary {
  color: $primary !important;
  background: rgb(31, 31, 34);
  background: linear-gradient(180deg, rgba(31, 31, 34, 1) 0%, rgba(24, 27, 30, 1) 5%, rgba(24, 38, 45, 1) 100%);
}

.modal-header {
  color: #9e8a57 !important;
  background: rgb(31, 31, 34);
  background: linear-gradient(180deg, rgba(31, 31, 34, 1) 0%, rgba(24, 27, 30, 1) 5%, rgba(24, 38, 45, 1) 100%);
  border-color: #9e8a57 !important;
}

.character-modal {
  background: #051126!important;
  border: none !important;
  border: 1px solid #43506A!important;
  padding:3rem;
}
.character-modal-mobile {
  padding:2rem;
}

#modal-container > .modal-dialog.modal-md {
  max-width: 700px;
}

.character-modal header.modal-header{
  background: #051126!important;
  border: none;
}

.character-modal header h5{
  text-transform: uppercase;
  text-align: center;
  font: normal normal bold 30px/38px Trajan;
  width: 100%;
}

.confirmation-title{
  text-align: center;
  font-family: Trajan;
}

.character-modal div.modal-body {
  background: #051126!important;
  border: none;
  color: #7F8693!important;
  display: flex;
  flex-direction: column;
}

.character-modal div.modal-body button {
  background-color:#1168D0;
  height: 56px;
  border-radius: 3px;
  margin-top: 1.5rem;
  border: none;
  outline: none;
  color: #fff;
}
.character-modal div.modal-body .input {
  background: #000E1D;
  border: 1px solid #323E55;
  border-radius: 5px;
  height: 70px;
  font: normal normal normal 18px/24px Roboto;
  letter-spacing: 0px;
  color: #7F8693;
  display: flex;
  height: 70px;
}

.tapAny{
  font-family: Roboto;
  color: #9E8A57;
  text-align: center;
  font-size: 0.9em;
  align-self: center;
  font-weight: 500;
  margin-bottom: 0px;
}

.modal-body {
  color: #9e8a57 !important;
  background: linear-gradient(180deg, rgba(31, 31, 34, 1) 0%, rgba(24, 27, 30, 1) 5%, rgba(24, 38, 45, 1) 100%);
  border: 1px solid #ffffff50;
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
.nav-tabs .nav-link{
  border: 1px solid #404857!important;
  background: transparent!important;
  color: white!important;
  text-transform: uppercase;
  font-family: 'Oswald', sans-serif;
  min-height:56px;
  line-height: 38px;
  border-radius: 0px;
}
.nav-tabs .nav-link.active {
  border: 1px solid #404857!important;
  background: #1168D0!important;
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

a.character-tab:hover,
a.character-tab:focus {
  text-shadow: none!important;
}

.nav.nav-pills .nav-link.character-tab{
  border: 1px solid #404857!important;
  background: transparent!important;
  color: white!important;
  text-transform: uppercase;
  font-family: 'Oswald', sans-serif;
  min-height:56px;
  line-height: 38px;
}

 .nav.nav-pills .nav-link.character-tab.active {
  border: 1px solid #404857!important;
  background: #1168D0!important;
}

.character-wrapper{
  flex: 1 1 0!important;
}

.multiselect *{
  background: transparent;
  color:#fff;
}
.multiselect__tags, .multiselect__content-wrapper{
  border:1px solid #404857;
}
.multiselect--above .multiselect__content-wrapper{
  border-top:none;
}

.multiselect__option--selected.multiselect__option--highlight,
.multiselect__option--selected.multiselect__option--highlight::after{
  background: #9E8A57;
}

.multiselect__option--selected,
.multiselect__option--selected::after,
.multiselect__option--highlight,
.multiselect__option--highlight::after{
  background: #404857;
}
</style>
<style scoped>
.app {
  margin: 0;
}

.content {
  padding: 0 1em;
  height: auto;
  margin: auto;
}

.fullscreen-warning {
  position: fixed;
  top: 0;
  left: 0;
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

.bg-image{
  background: url('./assets/combat-bg.png');
  background-repeat: no-repeat;
  background-size:cover;
  border-radius:0px;
}


#blacksmith-bg{
  background: rgba(20, 20, 20, 1);
  background-image: url("./assets/blacksmith/blacksmith-bg.png");
  background-repeat: no-repeat;
  background-size: cover;
}

.can-show-app{
  width: 100%;
  padding: 0px;
}

.outcome {
  /* margin: 20px auto; */
  height: 80vh;
  display: flex;
  justify-content: center;
  align-items: center;
  text-align: center;
  font-size: 3em;
}

@media all and (max-width: 600px) {
  .can-show-app{
    overflow-y: hidden ;
  }
}

@media all and (max-width: 767.98px) {
  .content {
    padding: 10px;
    padding-top: 0px;
  }
  .dark-bg-text {
    width: 100%;
  }
  .vertical-decoration {
    width: 100%;
  }
}
</style>
