<template>
  <div class="p-1">
    <h2 class="mt-3">{{ $t('admin.partnerVault.storeERC721Tokens') }}</h2>
    <div class="d-flex align-items-center gap-3">
      <b-form-input v-model="nft.address" :placeholder="$t('admin.partnerVault.pasteInValidERC721Address')"/>
      <b-form-input v-model="nft.identifiers" :placeholder="$t('admin.identifiers')"/>
      <b-button @click="storeNfts()" :disabled="storeNftsButtonDisabled()" variant="primary" class="text-nowrap">
        {{ $t('admin.partnerVault.storeInPartnerVault') }}
      </b-button>
    </div>
    <h2 class="mt-3">{{ $t('admin.partnerVault.storeERC20Tokens') }}</h2>
    <div class="d-flex align-items-center gap-3">
      <b-form-input v-model="currency.address" :placeholder="$t('admin.partnerVault.pasteInValidERC20Address')"/>
      <b-form-input v-model="currency.amount" :placeholder="$t('admin.amount')" type="number" number min="0"/>
      <b-button @click="storeCurrency()" :disabled="storeCurrencyButtonDisabled()" variant="primary"
                class="text-nowrap">
        {{ $t('admin.partnerVault.storeInPartnerVault') }}
      </b-button>
    </div>
    <h2 class="mt-3">{{ $t('admin.partnerVault.checkERC721Balance') }}</h2>
    <div class="d-flex align-items-center gap-3">
      <b-form-input v-model="nftBalance.address" :placeholder="$t('admin.partnerVault.pasteInValidERC721Address')"/>
      <b-form-input v-model="nftBalance.total" :placeholder="$t('admin.total')" type="number" number min="1"
                    readonly/>
      <b-form-input v-model="nftBalance.ids" :placeholder="$t('admin.identifiers')" readonly/>
      <b-button @click="checkNftsBalance()" :disabled="checkNftsBalanceButtonDisabled()" variant="primary"
                class="text-nowrap">
        {{ $t('admin.partnerVault.checkERC721Balance') }}
      </b-button>
    </div>
    <h2 class="mt-3">{{ $t('admin.partnerVault.checkERC20Balance') }}</h2>
    <div class="d-flex align-items-center gap-3">
      <b-form-input v-model="currencyBalance.address" :placeholder="$t('admin.partnerVault.pasteInValidERC20Address')"/>
      <b-form-input v-model="currencyBalance.amount" :placeholder="$t('admin.amount')" type="number" number min="1"
                    readonly/>
      <b-form-input v-model="currencyBalance.symbol" :placeholder="$t('admin.symbol')" readonly/>
      <b-button @click="checkCurrencyBalance()" :disabled="checkCurrencyBalanceButtonDisabled()" variant="primary"
                class="text-nowrap">
        {{ $t('admin.partnerVault.checkERC20Balance') }}
      </b-button>
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import {mapActions} from 'vuex';
import {isValidWeb3Address} from '../../../utils/common';

interface StoreMappedActions {
  storeNftsToPartnerVault(payload: { tokenAddress: string, tokenIds: number[] }): Promise<void>;

  storeCurrencyToPartnerVault(payload: { currencyAddress: string, amount: number }): Promise<void>;

  getCurrencyBalanceInPartnerVault(payload: { currencyAddress: string }): Promise<string[]>;

  getNftsInPartnerVault(payload: { tokenAddress: string }): Promise<string[]>;
}

interface Data {
  nft: {
    address: string;
    identifiers: string;
  };
  currency: {
    address: string;
    amount?: number;
  };
  currencyBalance: {
    address: string;
    amount?: number;
    symbol?: string;
  };
  nftBalance: {
    address: string;
    total?: number;
    ids?: string;
  };
  isLoading: boolean;
}

export default Vue.extend({
  data() {
    return {
      nft: {
        address: '',
        identifiers: '',
      },
      currency: {
        address: '',
        amount: undefined,
      },
      currencyBalance: {
        address: '',
        amount: undefined,
        symbol: undefined,
      },
      nftBalance: {
        address: '',
        total: undefined,
        ids: undefined,
      },
      isLoading: false,
    } as Data;
  },

  methods: {
    ...mapActions([
      'storeNftsToPartnerVault',
      'storeCurrencyToPartnerVault',
      'getCurrencyBalanceInPartnerVault',
      'getNftsInPartnerVault',
    ]) as StoreMappedActions,

    storeNftsButtonDisabled(): boolean {
      return !isValidWeb3Address(this.nft.address)
        || this.nft.identifiers === ''
        || this.isLoading;
    },

    storeCurrencyButtonDisabled(): boolean {
      return !isValidWeb3Address(this.currency.address)
        || !this.currency.amount
        || this.isLoading;
    },

    checkNftsBalanceButtonDisabled(): boolean {
      return !isValidWeb3Address(this.nftBalance.address)
        || this.isLoading;
    },

    checkCurrencyBalanceButtonDisabled(): boolean {
      return !isValidWeb3Address(this.currencyBalance.address)
        || this.isLoading;
    },

    async storeNfts() {
      if (!isValidWeb3Address(this.nft.address) || this.nft.identifiers === '') return;
      try {
        this.isLoading = true;
        await this.storeNftsToPartnerVault({
          tokenAddress: this.nft.address,
          tokenIds: this.nft.identifiers.split(',').map(id => +id),
        });
        this.clearInputs();
      } finally {
        this.isLoading = false;
      }
    },

    async storeCurrency() {
      if (!isValidWeb3Address(this.currency.address) || !this.currency.amount) return;
      try {
        this.isLoading = true;
        await this.storeCurrencyToPartnerVault({
          currencyAddress: this.currency.address,
          amount: this.currency.amount,
        });
        this.clearInputs();
      } finally {
        this.isLoading = false;
      }
    },

    async checkCurrencyBalance() {
      if (!isValidWeb3Address(this.currencyBalance.address)) return;
      try {
        this.isLoading = true;
        const result = await this.getCurrencyBalanceInPartnerVault({
          currencyAddress: this.currencyBalance.address
        });
        this.currencyBalance.amount = +result[0];
        this.currencyBalance.symbol = result[1];
      } finally {
        this.isLoading = false;
      }
    },

    async checkNftsBalance() {
      if (!isValidWeb3Address(this.nftBalance.address)) return;
      try {
        this.isLoading = true;
        const result = await this.getNftsInPartnerVault({
          tokenAddress: this.nftBalance.address
        });
        console.log(result);
        this.nftBalance.ids = result.join(', ');
        this.nftBalance.total = result.length;
      } finally {
        this.isLoading = false;
      }
    },

    clearInputs() {
      this.nft.address = '';
      this.nft.identifiers = '';
      this.currency.address = '';
      this.currency.amount = undefined;
    }
  },
});
</script>

<style scoped>
</style>
