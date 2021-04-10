// Taken from https://github.com/SharedStake/SharedStake-ui/blob/8bd7e9873640043dba75c32fdc69d0f6ac8d6fdf/src/components/Stake/Stake.vue

<template>
  <div class="stake">
    <div class="staker">
      <div class="chooser">
        <div class="navbar">
          <button
            class="switch"
            :class="{ switch_active: isDeposit }"
            @click="isDeposit = true"
          >
            <span>Stake</span>
          </button>
          <button
            class="switch"
            :class="{ switch_active: !isDeposit }"
            @click="isDeposit = false"
          >
            <span>Unstake</span>
          </button>
        </div>
      </div>
      <div class="stakePage">
        <div class="sPElement input">
          <div class="inputBody">
            <div class="flex_row">
              <input
                class="token-amount-input"
                inputmode="decimal"
                title="Token Amount"
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
              <div class="ant-col">{{ isDeposit ? "SKILL" : "SKILL" }}</div>
            </div>
            <div class="balance" id="balance" @click="onMAX">
              wallet: {{ inputSideBalance }}
            </div>
          </div>
        </div>

        <div class="down-arrow-spacer"></div>

        <div class="sPElement input">
          <div class="inputBody">
            <div class="flex_row">
              <input
                class="token-amount-input"
                inputmode="decimal"
                title="Token Amount"
                autocomplete="off"
                autocorrect="off"
                type="text"
                pattern="^[0-9]*[.,]?[0-9]*$"
                placeholder="0.0"
                minlength="1"
                maxlength="39"
                spellcheck="false"
                :value="bigNumberAmount.div(1e18)"
                readonly
              />
              <div class="ant-col">
                {{ isDeposit ? "SKILL" : "SKILL" }}
              </div>
            </div>
            <div class="balance" id="balance" @click="onMAX">
              wallet: {{ outputSideBalance }}
            </div>
          </div>
        </div>
        <button
          class="StakeButton"
          :class="{
            switch_active: currentState == 'ok',
          }"
          @click="onSubmit"
        >
          <span v-if="loading">
            <!-- <ImageVue :src="'loading.svg'" :size="'45px'" /> -->
            Loading...
          </span>
          <span v-else>
            {{ submitButtonLabel }}
          </span>
        </button>
      </div>
      <div class="navbar">
        <span id="gas">Gas</span>
        <button
          class="switch"
          :class="{ switch_active: selectedGasLevel === 'low' }"
          @click="selectedGasLevel = 'low'"
        >
          <span>{{ gas.low.toFixed(0) }}</span>
        </button>
        <button
          class="switch"
          :class="{ switch_active: selectedGasLevel == 'medium' }"
          @click="selectedGasLevel = 'medium'"
        >
          <span>{{ gas.medium.toFixed(0) }}</span>
        </button>
        <button
          class="switch"
          :class="{ switch_active: selectedGasLevel == 'high' }"
          @click="selectedGasLevel = 'high'"
        >
          <span>{{ gas.high.toFixed(0) }}</span>
        </button>
      </div>
    </div>
  </div>
</template>

<script>
import BN from "bignumber.js";
BN.config({ ROUNDING_MODE: BN.ROUND_DOWN });
BN.config({ EXPONENTIAL_AT: 100 });
import { mapActions, mapState } from "vuex";

import { getCurrentGasPrices } from "../../utils/common";

const connectToWalletButtonLabel = "Connect to wallet ↗";
const amountIsTooBigButtonLabel = "Amount is too big";
const contractIsFullButtonLabel = "Contract is Full";
const enterAnAmountButtonLabel = "Enter an amount";
const insufficientBalanceButtonLabel = "Insufficient balance";
const notEnoughFundsInExitPoolButtonLabel = "Not enough funds in Exit Pool";
const waitingButtonLabel = "waiting...";

const stakeButtonLabel = "Stake";
const unstakeButtonLabel = "Unstake";

export default {
  // components: { ImageVue, StakeGauge },
  data: () => ({
    textAmount: "",
    isDeposit: true,
    gas: { low: 90, medium: 130, high: 180 },
    loading: true,
    errorWhenUpdating: null,
    selectedGasLevel: "medium",
  }),
  async mounted() {
    this.gas = await getCurrentGasPrices();
    this.loading = false;

    await this.fetchData();
  },
  computed: {
    ...mapState([
      "defaultAccount",
      "skillBalance",
      "stakedSkillBalance",
      "stakeRemainingCapacityForDeposit",
      "stakeRemainingCapacityForWithdraw",
      "stakeContractBalance",
    ]),

    walletBalance() {
      return BN(this.skillBalance);
    },

    stakedBalance() {
      return BN(this.stakedSkillBalance);
    },

    remainingCapacityForDeposit() {
      if (this.stakeRemainingCapacityForDeposit == null) {
        return null;
      }

      return BN(this.stakeRemainingCapacityForDeposit);
    },

    remainingCapacityForWithdraw() {
      return BN(this.stakeRemainingCapacityForWithdraw);
    },

    contractBalance() {
      return BN(this.stakeContractBalance);
    },

    validator() {
      return null;
    },

    chosenGas() {
      return this.gas[this.selectedGasLevel];
    },

    inputSideBalance() {
      const b = this.isDeposit ? this.walletBalance : this.stakedBalance;
      return b.dividedBy(1e18).toFixed(6);
    },

    outputSideBalance() {
      const b = this.isDeposit ? this.stakedBalance : this.walletBalance;
      return b.dividedBy(1e18).toFixed(6);
    },

    currentState() {
      if (this.defaultAccount == null || this.errorWhenUpdating != null) {
        return "connectWallet";
      }

      if (
        this.remainingCapacityForDeposit != null &&
        this.remainingCapacityForDeposit.eq(0) &&
        this.isDeposit
      ) {
        return "contractFull";
      }

      if (
        this.remainingCapacityForDeposit != null &&
        this.bigNumberAmount.gt(this.remainingCapacityForDeposit) &&
        this.isDeposit
      ) {
        return "amountIsTooBig";
      }

      if (this.textAmount[this.textAmount.length - 1] === ".") {
        return "waiting";
      }

      if (this.textAmount <= 0) {
        return "inputIsZero";
      }

      const hasSufficientBalance = this.isDeposit
        ? this.walletBalance.gte(this.bigNumberAmount)
        : this.stakedBalance.gte(this.bigNumberAmount);

      if (!hasSufficientBalance) {
        return "insufficientBalance";
      }

      if (this.bigNumberAmount.gt(this.contractBalance) && !this.isDeposit) {
        return "notEnoughFundsInExitPool";
      }

      if (
        this.bigNumberAmount.gt(this.remainingCapacityForWithdraw) &&
        !this.isDeposit
      ) {
        return "notEnoughFundsInExitPool";
      }

      return "ok";
    },

    submitButtonLabel() {
      switch (this.currentState) {
        case "ok":
          return this.isDeposit ? stakeButtonLabel : unstakeButtonLabel;
        case "contractFull":
          return contractIsFullButtonLabel;
        case "amountIsTooBig":
          return amountIsTooBigButtonLabel;
        case "waiting":
          return waitingButtonLabel;
        case "inputIsZero":
          return enterAnAmountButtonLabel;
        case "insufficientBalance":
          return insufficientBalanceButtonLabel;
        case "notEnoughFundsInExitPool":
          return notEnoughFundsInExitPoolButtonLabel;
        default:
          return connectToWalletButtonLabel;
      }
    },

    bigNumberAmount: {
      get() {
        if (!this.textAmount) return BN(0);

        return BN(this.textAmount).multipliedBy(1e18);
      },
      set(newBnAmount) {
        this.textAmount = newBnAmount.dividedBy(1e18);
      },
    },
  },
  methods: {
    ...mapActions(["fetchStakeDetails", "stake", "unstake"]),

    async onMAX() {
      if (this.isDeposit) {
        console.log(this.walletBalance.toString());
        const walletBalance = this.walletBalance;

        if (
          this.remainingCapacityForDeposit != null &&
          this.remainingCapacityForDeposit.eq(0)
        ) {
          return;
        }

        this.bigNumberAmount = BN(walletBalance);

        if (
          this.remainingCapacityForDeposit != null &&
          this.bigNumberAmount.gt(this.remainingCapacityForDeposit)
        ) {
          this.bigNumberAmount = BN(this.remainingCapacityForDeposit);
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
      if (this.currentState !== "ok") return;

      const amount = this.bigNumberAmount.toString();
      console.log("It is showtime:", this.bigNumberAmount, amount);

      if (this.isDeposit) {
        await this.stake({ amount, gas: this.chosenGas });
      } else {
        //unstake
        await this.unstake({ amount, gas: this.chosenGas });
      }
    },
    async fetchData() {
      //balances
      try {
        this.errorWhenUpdating = null;
        this.loading = true;

        await this.fetchStakeDetails();
      } catch (err) {
        this.errorWhenUpdating = err.message;
        console.log(err);
      } finally {
        this.loading = false;
      }
    },
  },
  watch: {
    textAmount: function (newValue, oldVal) {
      if (newValue.length > 40) {
        this.textAmount = oldVal;
        return;
      }

      if (newValue[newValue.length - 1] == 0) {
        this.textAmount = newValue;
        return;
      }

      if (
        newValue[newValue.length - 1] === "." &&
        newValue[newValue.length - 2] !== "."
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
    isDeposit: function () {
      this.textAmount = "";
    },
    async defaultAccount(newVal) {
      if (newVal) {
        await this.fetchData();
      }
    },
  },
};
</script>

<style scoped>
.stake {
  display: inline-block;
  /* background-image: url(bg-1.png); */
  background-repeat: no-repeat;
  background-position: center;
  min-height: 800px;
}
.staker {
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  max-width: 375px;
  width: 100%;
  background-color: #181818;
  height: 90%;
  max-height: 716px;
  overflow: visible;
  box-shadow: 0 0 50px rgb(0 0 0 / 10%);
  border-radius: 2px;
  position: relative;
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
  min-height: 634px;
}
.chooser {
  background-color: rgb(15, 16, 19);
  height: 72px;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0 16px;
}
.navbar {
  display: flex;
  border: 1px solid #3c3c3c;
  box-sizing: border-box;
  border-radius: 100px;
  width: 100%;
}
#gas {
  padding: 0 20px;
  font-size: 16px;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 100%;
  color: #fff;
}
.switch {
  height: 40px;
  padding: 0 20px;
  font-size: 16px;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 100%;
  border-color: transparent;
  color: #fff;
  border-radius: 100px;
  line-height: 24px;
  box-sizing: border-box;
  white-space: nowrap;
  text-align: center;
  border: 1px solid transparent;
  box-shadow: 0 2px 0 rgb(0 0 0 / 2%);
  cursor: pointer;
  transition: all 0.3s cubic-bezier(0.645, 0.045, 0.355, 1);
  user-select: none;
  touch-action: manipulation;
  background: transparent;
}

.stakePage {
  width: calc(100% - 20px);
  padding: 10px;
  height: calc(80% - 20px);
  display: grid;
  grid-template-columns: 1fr;
  grid-template-rows: 1fr 0.2fr 1fr 0.5fr;
  gap: 0px 0px;
  grid-template-areas:
    "."
    "."
    ".";
  justify-content: center;
  align-items: center;
}
.sPElement {
  align-self: center;
  justify-self: center;
  color: #fff;
}
.input {
  border-radius: 4px;
  width: 100%;
  height: 180px;
  max-width: 362px;
  overflow: hidden;
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: rgb(15, 16, 19);
  border: none;
  font-weight: 500;
}
.inputBody {
  position: relative;
  height: 100%;
  padding: 0 0 0 0;
  width: 100%;
  display: flex;
  flex-direction: column;
  justify-content: space-around;
  align-items: center;
}
.StakeButton {
  width: 100%;
  display: flex;
  justify-content: center;
  align-items: center;
  border: 1px solid #3c3c3c;
  box-sizing: border-box;
  background-color: rgb(15, 16, 19);
  color: #fff;
  height: 50px;
  padding: 0 20px;
  font-size: 16px;
  border-radius: 100px;
  line-height: 24px;
  box-shadow: 0 2px 0 rgb(0 0 0 / 2%);
  transition: all 0.3s cubic-bezier(0.645, 0.045, 0.355, 1);
  border-radius: 100px;
}
.switch_active {
  border: 2px solid rgb(37, 167, 219);
  border-radius: 100px;
  color: #fff;
  cursor: pointer;
  font-weight: bold;
}
.switch_active:hover,
.switch:hover {
  transform: scale(0.98);
}
.balance {
  margin-top: 8px;
  font-size: 12px;
  line-height: 20px;
  text-align: center;
  letter-spacing: 0.3px;
  display: flex;
  justify-content: center;
  align-items: center;
  text-decoration: underline;
  z-index: 10;
  cursor: pointer;
  font-weight: bolder;
}
.token-amount-input {
  box-sizing: border-box;
  z-index: 10;
  margin: 0;
  padding: 0;
  font-variant: tabular-nums;
  list-style: none;
  font-feature-settings: "tnum";
  position: relative;
  display: inline-block;
  width: 70%;
  padding: 4px 11px;
  color: #fff;
  background-color: transparent;
  outline-width: 0;
  font-size: 34px;
  line-height: 40px;
  text-align: right;
  height: 40px;
  padding-bottom: 0;
  text-overflow: ellipsis;
  border-radius: 2px;
  border: none;
  touch-action: manipulation;
}
.ant-col {
  box-sizing: border-box;
  display: block;
  box-sizing: border-box;
  width: 50%;
}
.background3,
.background2 {
  /* background-image: url(Eth.png); */
  position: absolute;
  z-index: 0;
  width: 200%;
  height: 200%;
  top: -50%;
  left: -50%;
  background-size: contain;
  background-repeat: no-repeat;
  background-position: center;
  mask-image: radial-gradient(
    circle,
    rgba(0, 0, 0, 1) 20%,
    rgba(0, 0, 0, 0.4) 60%
  );
  opacity: 0.05;
  transition: all 0.3s cubic-bezier(0.645, 0.045, 0.355, 1);
}
.notification {
  width: 90%;
  padding: 5%;
  color: tomato;
  font-size: 16px;
}
.underline {
  text-decoration: underline;
}
.gauge {
  padding-top: 1rem;
}

.down-arrow-spacer {
  height: 2em;
  background-image: url("../../assets/down.png");
  background-repeat: no-repeat;
  background-position: center center;
  background-size: contain;
}

.flex_row {
  display: flex;
  flex-direction: row;
  align-items: center;
  justify-content: space-evenly;
}
.flex_column {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: space-evenly;
}
</style>
