<template>
  <div class="body main-font">
    <div class="blank-slate">
      Portal
      <div>
        The portal allows you to convert your other currencies to BNB. Currently, the portal supports <a href="https://on.wax.io/wax-io/" target="_blank">WAX</a>.
      </div>
      <br />
      <div class="sub-container" v-if="transactionResults != null && !waitingResults">
        We'll get your BNB to you ASAP!
      </div>
      <div class="loading-container waiting" v-if="waitingResults">
        <i class="fas fa-spinner fa-spin"></i>
        Waiting for transaction results...
      </div>
      <div class="blank-slate" v-if="userAccount === null && !has5SkillBalance">
        In order to use the Portal, you will need at least <b>5 SKILL!</b> Please add some here:
        <a v-bind:href="`${getExchangeUrl}`" target="_blank">Swap SKILL/BNB</a>
      </div>
      <div class="blank-slate" v-if="userAccount === null && has5SkillBalance">
        Connect WAX wallet
        <br />
        <big-button class="button" v-if="userAccount === null" mainText="WAX Login" @click="waxLogin" />
      </div>
      <div class="blank-slate" v-if="userAccount != null">
        How much WAX do you want to transfer? You have: {{ waxBalance }}.
        <input v-model="WAXAmount" placeholder="How much WAX?" @input="change($event)" @change="change($event)" />
        <div class="error" v-if="!isValid">Invalid WAX amount. Please use the format: "X.xxxxxxxx" (8 decimals).</div>
        <br />
        <big-button class="button" v-if="userAccount != null" :disabled="!isValid" mainText="Submit" @click="sign" />
      </div>
    </div>
  </div>
</template>

<script>
import BigButton from '../components/BigButton.vue';
import * as waxjs from '@waxio/waxjs/dist';
import { mapGetters, mapState } from 'vuex';
const wax = new waxjs.WaxJS('https://wax.greymass.com', null, null, false);
import { toBN, fromWeiEther } from '../utils/common';

export default {
  data() {
    return {
      userAccount: null,
      publicKey: null,
      WAXAmount: null,
      regex: /^\d+\.\d{8}$/,
      transactionResults: null,
      waitingResults: false,
      waxBalance: 0,
      isValid: null,
    };
  },
  computed: {
    ...mapState(['defaultAccount', 'skillBalance', 'inGameOnlyFunds', 'skillRewards']),
    ...mapGetters(['getExchangeUrl', 'hasStakedBalance']),

    has5SkillBalance() {
      return toBN(fromWeiEther(this.skillBalance)).plus(toBN(fromWeiEther(this.skillRewards))).gte(5);
    },
  },

  methods: {
    async connectWaxWallet() {},
    //normal login. Triggers a popup for non-whitelisted dapps
    async waxLogin() {
      this.userAccount = await wax.login();
      this.publicKey = wax.pubKeys;
      this.getWaxBalance();
    },

    async sign() {
      if (!wax.api) {
        return document.getElementById('response').append('* Login first *');
      }
      try {
        this.waitingResults = true;
        const results = await wax.api.transact(
          {
            actions: [
              {
                account: 'eosio.token',
                name: 'transfer',
                authorization: [
                  {
                    actor: wax.userAccount,
                    permission: 'active',
                  },
                ],
                data: {
                  from: wax.userAccount, //user's BSC Address
                  to: process.env.VUE_APP_WAX_BRIDGE_WAX_WALLET_ADDRESS, //CB Wallet Address
                  quantity: toBN(this.WAXAmount).toFixed(8) + ' WAX', //WAX *needs* to be here.
                  memo: this.defaultAccount,
                },
              },
            ],
          },
          {
            blocksBehind: 3,
            expireSeconds: 30,
          },
        );
        this.transactionResults = results;
        this.waitingResults = false;
        this.error = null;
      } catch (e) {
        console.error(e);
        this.error = e.message;
      }
    },

    async change(e) {
      const number = e.target.value;
      this.isNumberValid(number);
    },

    async isNumberValid(inputNumber) {
      this.isValid = this.regex.test(inputNumber);
    },

    async getWaxBalance() {
      this.waxBalance = await wax.api.rpc.get_currency_balance('eosio.token', this.userAccount, 'WAX');
    },
  },
  components: {
    BigButton,
  },
};
</script>

<style scoped>
.button-row {
  margin-top: 1em;
  display: flex;
}
.sub-container {
  flex: 1;
}
</style>
