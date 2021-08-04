<template>
  <div class="app">
    <nav-bar />
    <character-bar v-if="!featureFlagStakeOnly && currentCharacterId !== null" />
    <div class="content dark-bg-text">
      <router-view v-if="canShowApp" />
    </div>
    <div class="fullscreen-warning" v-if="!hideWalletWarning && (showMetamaskWarning || showNetworkError)">
      <div class="starter-panel">
        <span class="starter-panel-heading">Metamask Not Detected Or Incorrect Network</span>
        <div class="center">
          <big-button class="button" :mainText="`Add MetaMask`" @click="startOnboarding" v-if="showMetamaskWarning" />
          <big-button class="button" :mainText="`Switch to BSC Network`" @click="configureMetaMask" v-if="showNetworkError" />
          <small-button class="button" @click="toggleHideWalletWarning" :text="'Hide Warning'" />
        </div>
      </div>
    </div>
    <div
      class="fullscreen-warning"
      v-if="!hideWalletWarning && !showMetamaskWarning && (errorMessage || (ownCharacters.length === 0 && skillBalance === '0' && !hasStakedBalance))"
    >
      <div class="starter-panel">
        <img class="mini-icon-starter" src="./assets/placeholder/sword-placeholder-6.png" alt="" srcset="" />
        <span class="starter-panel-heading">{{ errorMessage || 'Get Started With CryptoBlades' }}</span>
        <img class="mini-icon-starter" src="./assets/placeholder/sword-placeholder-6.png" alt="" srcset="" />
        <div>
          <big-button class="button mm-button" :mainText="`Configure MetaMask`" @click="configureMetaMask" />
          <big-button v-bind:class="[isConnecting ? 'disabled' : '']" class="button mm-button" :mainText="`Connect to MetaMask`" @click="connectMetamask" />
        </div>
        <div class="seperator"></div>
        <div class="instructions-list">
          <p>
            Get started in less than 10 minutes! To recruit your first character you need {{ recruitCost }} SKILL and .001 BNB for gas. You will also need .0015
            BNB to do your first few battles, but don't worry, you earn the battle fees back in SKILL rewards immediately!
          </p>
          <ul class="unstyled-list">
            <li>1. Buying BNB with fiat: <a href="https://youtu.be/6-sUDUE2RPA" target="_blank" rel="noopener noreferrer">Watch Video</a></li>
            <li>
              2. Once you have BNB, go to ApeSwap to obtain SKILL tokens:<br />
              <a v-bind:href="`${getExchangeUrl}`" target="_blank">Trade SKILL/BNB</a>
            </li>
            <li>
              3. Follow this tutorial to swap BNB for SKILL: <a href="https://youtu.be/_zitrvJ7Hl4" target="_blank" rel="noopener noreferrer">Watch Video</a>
            </li>
            <li>
              4. That's it! Now you can create your first character: (<a href="https://youtu.be/ZcNq0jCa28c" target="_blank" rel="noopener noreferrer"
                >Watch 'Getting Started' Video</a
              >)
            </li>
          </ul>
          <p>
            If you have any questions, please join our Discord:
            <a href="https://discord.gg/cryptoblades" target="_blank" rel="noopener noreferrer">https://discord.gg/cryptoblades</a>
          </p>
        </div>
        <div class="seperator"></div>
        <small-button class="button" @click="toggleHideWalletWarning" :text="'Hide Warning'" />
      </div>
    </div>
  </div>
</template>

<script>
import BN from 'bignumber.js';

import { mapState, mapActions, mapGetters } from 'vuex';
import _ from 'lodash';
import Vue from 'vue';
import Events from './events';
import MetaMaskOnboarding from '@metamask/onboarding';
import BigButton from './components/BigButton.vue';
import SmallButton from './components/SmallButton.vue';
import NavBar from './components/NavBar.vue';
import CharacterBar from './components/CharacterBar.vue';
import { apiUrl } from './utils/common';

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
    isConnecting: false,
    recruitCost: '',
  }),

  computed: {
    ...mapState(['skillBalance', 'defaultAccount', 'currentNetworkId', 'currentCharacterId', 'staking']),
    ...mapGetters(['contracts', 'ownCharacters', 'getExchangeUrl', 'availableStakeTypes', 'hasStakedBalance']),

    canShowApp() {
      return this.contracts !== null && !_.isEmpty(this.contracts) && !this.showNetworkError;
    },

    showMetamaskWarning() {
      return !this.web3.currentProvider;
    },

    showNetworkError() {
      return this.expectedNetworkId && this.currentNetworkId !== null && this.currentNetworkId !== this.expectedNetworkId;
    },
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
      'fetchCharacterTransferCooldownForOwnCharacters',
      'setupWeaponDurabilities',
      'fetchStakeDetails',
      'fetchWaxBridgeDetails',
      'fetchRewardsClaimTax',
    ]),

    async updateCharacterStamina(id) {
      if (this.featureFlagStakeOnly) return;

      if (id !== null) {
        await this.fetchCharacterStamina(id);
      }
    },

    checkStorage() {
      this.hideWalletWarning = localStorage.getItem('hideWalletWarning') === 'true';
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
    async configureMetaMask() {
      const web3 = this.web3.currentProvider;
      if (this.currentNetworkId === 97) {
        try {
          await web3.request({
            method: 'wallet_switchEthereumChain',
            params: [{ chainId: '0x61' }],
          });
        } catch (switchError) {
          try {
            await web3.request({
              method: 'wallet_addEthereumChain',
              params: [
                {
                  chainId: '0x61',
                  chainName: 'Binance Smart Chain Testnet',
                  nativeCurrency: {
                    name: 'Binance Coin',
                    symbol: 'BNB',
                    decimals: 18,
                  },
                  rpcUrls: ['https://data-seed-prebsc-1-s1.binance.org:8545/'],
                  blockExplorerUrls: ['https://testnet.bscscan.com'],
                },
              ],
            });
          } catch (addError) {
            console.error(addError);
          }
        }

        try {
          await web3.request({
            method: 'wallet_watchAsset',
            params: {
              type: 'ERC20',
              options: {
                address: '0xcaf53066e36eef55ed0663419adff6e503bd134f',
                symbol: 'SKILL',
                decimals: 18,
                image: 'https://app.cryptoblades.io/android-chrome-512x512.png',
              },
            },
          });
        } catch (error) {
          console.error(error);
        }
      } else {
        {
          try {
            await web3.request({
              method: 'wallet_switchEthereumChain',
              params: [{ chainId: '0x38' }],
            });
          } catch (switchError) {
            try {
              await web3.request({
                method: 'wallet_addEthereumChain',
                params: [
                  {
                    chainId: '0x38',
                    chainName: 'Binance Smart Chain Mainnet',
                    nativeCurrency: {
                      name: 'Binance Coin',
                      symbol: 'BNB',
                      decimals: 18,
                    },
                    rpcUrls: ['https://bsc-dataseed.binance.org/'],
                    blockExplorerUrls: ['https://bscscan.com/'],
                  },
                ],
              });
            } catch (addError) {
              console.error(addError);
            }
          }

          try {
            await web3.request({
              method: 'wallet_watchAsset',
              params: {
                type: 'ERC20',
                options: {
                  address: '0x154a9f9cbd3449ad22fdae23044319d6ef2a1fab',
                  symbol: 'SKILL',
                  decimals: 18,
                  image: 'https://app.cryptoblades.io/android-chrome-512x512.png',
                },
              },
            });
          } catch (error) {
            console.error(error);
          }
        }
      }
    },

    async connectMetamask() {
      const web3 = this.web3.currentProvider;
      this.isConnecting = true;
      this.errorMessage = 'Connecting to MetaMask...';
      web3
        .request({ method: 'eth_requestAccounts' })
        .then(() => {
          this.errorMessage = 'Success: MetaMask connected.';
          this.isConnecting = false;
        })
        .catch(() => {
          this.errorMessage = 'Error: MetaMask could not get permissions.';
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
        this.$dialog.notify.warning(
          `You have hidden the wallet warning and it would now be displayed. If you are trying to play,
        please disable the option and follow the instructions, otherwise close and ignore.`,
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

      notifications.forEach((notif) => {
        if (!shouldContinue) return;

        if (lastHash === notif.hash) {
          shouldContinue = false;
          return;
        }

        this.$dialog.notify.warning(
          `${notif.title}
          <br>
          <a href="${notif.link}" target="_blank">Check it out!</a>
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
  },

  async created() {
    try {
      await this.initializeStore();
    } catch (e) {
      this.errorMessage = 'Welcome to CryptoBlades. Here is how you can get started.';
      if (e.code === 4001) {
        this.errorMessage = 'Error: MetaMask could not get permissions.';
      }

      console.error(e);
      throw e;
    }

    this.pollCharactersStaminaIntervalId = setInterval(async () => {
      this.ownCharacters.forEach(async (c) => {
        await this.updateCharacterStamina(c.id);
      });
    }, 3000);

    this.availableStakeTypes.forEach((item) => {
      this.fetchStakeDetails({ stakeType: item });
    });

    this.slowPollIntervalId = setInterval(async () => {
      await Promise.all([
        this.fetchCharacterTransferCooldownForOwnCharacters(),
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

.mm-button {
  margin: 5px;
  margin-left: 5px;
  margin-right: 5px;
}

.btn {
  border: 2px solid #6c5f38 !important;
  border-radius: 0.1em !important;
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
  height: calc(100vh - 56px);
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
  font-size: 45px;
}

.starter-msg {
  font-size: 0.85em;
}
.instructions-list {
  text-align: start;
  padding: 15px;
  font-size: 0.5em;
}

.unstyled-list {
  list-style-type: none;
}
.seperator {
  border: 1px solid #9e8a57;
  border-radius: 3px;
  width: 100%;
}

.mini-icon-starter {
  height: 1.2em;
  width: 1.2em;
  margin: 5px;
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
}
</style>
