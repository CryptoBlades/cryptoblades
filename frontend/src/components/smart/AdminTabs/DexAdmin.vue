<template>
  <div class="p-1">
    <h2 class="mt-2">{{
        $t('admin.dex.setFeePercentageCurrentDefault0_3', {feePercentage: currentDexFeePercentage})
      }}</h2>
    <div class="d-flex align-items-center gap-3">
      <b-form-input v-model="newDexFeePercentage" :placeholder="$t('admin.dex.dexFeePercentage')" number type="number"/>
      <b-button @click="setNewDexFeePercentage()" :disabled="setNewDexFeePercentageButtonDisabled"
                variant="info" class="text-nowrap">
        {{ $t('admin.dex.setFeePercentage') }}
      </b-button>
    </div>
    <h2 class="mt-3">{{ $t('admin.dex.addNewTokenPair') }}</h2>
    <div class="d-flex align-items-center gap-3 flex-wrap">
      <b-form-input v-model="newTokenPair.tokenA" :placeholder="$t('admin.dex.firstTokenAddress')"/>
      <b-form-input v-model="newTokenPair.amountA" type="number" number min="0"
                    :placeholder="$t('admin.dex.firstTokenAmount')"/>
      <b-form-input v-model="newTokenPair.tokenB" :placeholder="$t('admin.dex.secondTokenAddress')"/>
      <b-form-input v-model="newTokenPair.amountB" type="number" number min="0"
                    :placeholder="$t('admin.dex.secondTokenAmount')"/>
      <b-button @click="addNewTokenPair()" :disabled="addNewTokenPairButtonDisabled"
                variant="info" class="text-nowrap">
        {{ $t('admin.dex.addNewTokenPair') }}
      </b-button>
    </div>
    <h2 class="mt-3">{{ $t('admin.dex.addLiquidity') }}</h2>
    <div class="d-flex align-items-center gap-3 flex-wrap">
      <b-form-input v-model="newLiquidity.tokenA" :placeholder="$t('admin.dex.firstTokenAddress')"/>
      <b-form-input v-model="newLiquidity.amountA" type="number" number min="0"
                    :placeholder="$t('admin.dex.firstTokenAmount')"/>
      <b-form-input v-model="newLiquidity.tokenB" :placeholder="$t('admin.dex.secondTokenAddress')"/>
      <b-form-input v-model="newLiquidity.amountB" type="number" number min="0"
                    :placeholder="$t('admin.dex.secondTokenAmount')"/>
      <b-button @click="addNewLiquidity()" :disabled="addNewLiquidityButtonDisabled"
                variant="info" class="text-nowrap">
        {{ $t('admin.dex.addLiquidity') }}
      </b-button>
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import {mapActions} from 'vuex';
import {isValidWeb3Address} from '../../../utils/common';

interface StoreMappedActions {
  getDexFeePercentage(): Promise<number>;

  setDexFeePercentage(payload: { fee: number }): Promise<void>;

  addDexTokenPair(payload: { tokenPair: TokenPair }): Promise<void>;

  addDexLiquidity(payload: { tokenPair: TokenPair }): Promise<void>;
}

export interface TokenPair {
  tokenA: string;
  amountA?: number;
  tokenB: string;
  amountB?: number;
}

interface Data {
  newDexFeePercentage?: number;
  currentDexFeePercentage?: number;
  newTokenPair: TokenPair;
  newLiquidity: TokenPair;
  isLoading: boolean;
}

export default Vue.extend({
  data() {
    return {
      newDexFeePercentage: undefined,
      currentDexFeePercentage: undefined,
      newTokenPair: {
        tokenA: '',
        amountA: undefined,
        tokenB: '',
        amountB: undefined,
      },
      newLiquidity: {
        tokenA: '',
        amountA: undefined,
        tokenB: '',
        amountB: undefined,
      },
      isLoading: false,
    } as Data;
  },

  computed: {
    setNewDexFeePercentageButtonDisabled(): boolean {
      return this.newDexFeePercentage === undefined
        || this.isLoading;
    },
    addNewTokenPairButtonDisabled(): boolean {
      return !isValidWeb3Address(this.newTokenPair.tokenA)
        || this.newTokenPair.amountA === undefined
        || !isValidWeb3Address(this.newTokenPair.tokenB)
        || this.newTokenPair.amountB === undefined
        || this.isLoading;
    },
    addNewLiquidityButtonDisabled(): boolean {
      return !isValidWeb3Address(this.newLiquidity.tokenA)
        || this.newLiquidity.amountA === undefined
        || !isValidWeb3Address(this.newLiquidity.tokenB)
        || this.newLiquidity.amountB === undefined
        || this.isLoading;
    },
  },

  methods: {
    ...mapActions([
      'getDexFeePercentage',
      'setDexFeePercentage',
      'addDexTokenPair',
      'addDexLiquidity',
    ]) as StoreMappedActions,

    async setNewDexFeePercentage() {
      if (this.setNewDexFeePercentageButtonDisabled) return;
      try {
        this.isLoading = true;
        await this.setDexFeePercentage({fee: this.newDexFeePercentage!});
        await this.fetchCurrentDexFeePercentage();
        this.newDexFeePercentage = undefined;
      } finally {
        this.isLoading = false;
      }
    },

    async fetchCurrentDexFeePercentage() {
      try {
        this.isLoading = true;
        this.currentDexFeePercentage = await this.getDexFeePercentage();
      } finally {
        this.isLoading = false;
      }
    },

    async addNewTokenPair() {
      if (!isValidWeb3Address(this.newTokenPair.tokenA) || this.newTokenPair.amountA === undefined
        || !isValidWeb3Address(this.newTokenPair.tokenB) || this.newTokenPair.amountB === undefined) return;
      try {
        this.isLoading = true;
        await this.addDexTokenPair(this.newTokenPair);
        this.newTokenPair = {
          tokenA: '',
          amountA: undefined,
          tokenB: '',
          amountB: undefined,
        };
      } finally {
        this.isLoading = false;
      }
    },

    async addNewLiquidity() {
      if (!isValidWeb3Address(this.newLiquidity.tokenA) || this.newLiquidity.amountA === undefined
        || !isValidWeb3Address(this.newLiquidity.tokenB) || this.newLiquidity.amountB === undefined) return;
      try {
        this.isLoading = true;
        await this.addDexLiquidity(this.newLiquidity);
        this.newLiquidity = {
          tokenA: '',
          amountA: undefined,
          tokenB: '',
          amountB: undefined,
        };
      } finally {
        this.isLoading = false;
      }
    },
  },

  async mounted() {
    await this.fetchCurrentDexFeePercentage();
  }
});
</script>

<style scoped>
</style>
