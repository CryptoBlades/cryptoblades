<template>
  <div class="body main-font">
    <div class="blank-slate">
      Portal
      <br />
      <div class="sub-container" v-if="transactionResults != null && !waitingResults">
        We'll get your BNB to you ASAP!
      </div>
      <div class="loading-container waiting" v-if="waitingResults">
        <i class="fas fa-spinner fa-spin"></i>
        Waiting for transaction results...
      </div>
      <div class="blank-slate" v-if="userAccount === null">
        Connect WAX wallet
        <br />
        <big-button class="button" v-if="userAccount === null" mainText="WAX Login" @click="waxLogin" />
      </div>
      <div class="blank-slate" v-if="userAccount != null">
        How Much Wax?
        <input v-model="WAXAmount" placeholder="How much WAX?" @input="change($event)" @change="change($event)" />
        <div class="error" v-if="!isValid">Number is Invalid</div>
        <br />
        <big-button class="button" v-if="userAccount != null" mainText="Submit" @click="sign" />
      </div>
    </div>
  </div>
</template>

<script>
import BigButton from '../components/BigButton.vue';
import * as waxjs from '@waxio/waxjs/dist';
import { mapState } from 'vuex';
const wax = new waxjs.WaxJS('https://wax.greymass.com', null, null, false);
export default {
  data() {
    return {
      userAccount: null,
      publicKey: null,
      WAXAmount: null,
      regex: /^\d+(\.\d{8})?$/,
      transactionResults: null,
      waitingResults: false,
    };
  },
  computed: {
    ...mapState(['defaultAccount']),
  },
  methods: {
    async connectWaxWallet() {},
    //normal login. Triggers a popup for non-whitelisted dapps
    async waxLogin() {
      this.userAccount = await wax.login();
      this.publicKey = wax.pubKeys;
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
                  quantity: this.WAXAmount + ' WAX', //WAX *needs* to be here.
                  memo: this.defaultAccount,
                },
              },
            ],
          },
          {
            blocksBehind: 3,
            expireSeconds: 30,
          }
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
