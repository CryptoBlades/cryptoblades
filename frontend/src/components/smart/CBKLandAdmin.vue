<template>
  <div class="p-1">
    <h2>{{ $t('admin.cbkLand.mintLands') }}</h2>
    <div class="d-flex align-items-center gap-3">
      <b-form-input v-model="minter" :placeholder="$t('admin.cbkLand.minter')"></b-form-input>
      <b-form-input v-model="tier" :placeholder="$t('admin.cbkLand.tier')" type="number" number min="0"
                    max="3"></b-form-input>
      <b-form-input v-model="chunkId" :placeholder="$t('admin.cbkLand.chunkId')" type="number" number
                    min="0"></b-form-input>
      <b-form-input v-model="reseller" :placeholder="$t('admin.cbkLand.reseller')"></b-form-input>
      <b-form-input v-model="quantity" :placeholder="$t('admin.cbkLand.quantityOptional')" type="number" number
                    min="1"></b-form-input>
      <b-button @click="mintLand()" :disabled="mintLandButtonDisabled()" variant="primary" class="text-nowrap">
        {{ quantity > 1 ? $t('admin.cbkLand.mintLands') : $t('admin.cbkLand.mintLand') }}
      </b-button>
    </div>
    <h2 class="mt-3">{{ $t('admin.cbkLand.updateChunkIdentifier') }}</h2>
    <div class="d-flex align-items-center gap-3">
      <b-form-input v-model="identifiers" :placeholder="$t('admin.cbkLand.identifiers')"/>
      <b-form-input v-model="updateChunkIdentifier" :placeholder="$t('admin.cbkLand.updateChunkIdentifier')"
                    type="number" number
                    min="1"/>
      <b-button @click="updateId()" :disabled="updateIdsButtonDisabled()" variant="primary" class="text-nowrap">
        {{ quantity > 1 ? $t('admin.cbkLand.updateChunkIds') : $t('admin.cbkLand.updateChunkId') }}
      </b-button>
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import {mapActions} from 'vuex';
import {isValidWeb3Address} from '@/utils/common';

interface StoreMappedActions {
  mintCBKLand(payload: { minter: string, tier: number, chunkId: number, reseller: string }): Promise<void>;

  massMintCBKLand(payload: { minter: string, tier: number, chunkId: number, reseller: string, quantity: number }): Promise<void>;

  updateChunkId(payload: { id: number, chunkId: number }): Promise<void>;

  updateChunkIds(payload: { ids: number[], chunkId: number }): Promise<void>;
}

interface Data {
  minter: string;
  tier?: number;
  chunkId?: number;
  reseller: string;
  quantity?: number;
  updateChunkIdentifier?: number;
  identifiers: string;
  ids: number[];
  isLoading: boolean;
}

export default Vue.extend({
  data() {
    return {
      minter: '',
      tier: undefined,
      chunkId: undefined,
      reseller: '',
      quantity: undefined,
      updateChunkIdentifier: undefined,
      identifiers: '',
      ids: [],
      isLoading: false,
    } as Data;
  },

  computed: {},

  methods: {
    ...mapActions(['mintCBKLand', 'massMintCBKLand', 'updateChunkId', 'updateChunkIds']) as StoreMappedActions,

    mintLandButtonDisabled(): boolean {
      return !isValidWeb3Address(this.minter)
        || this.tier === undefined || this.tier < 0 || this.tier > 3
        || this.chunkId === undefined || this.chunkId < 0 || this.chunkId > 9999
        || !isValidWeb3Address(this.reseller)
        || this.isLoading;
    },

    updateIdsButtonDisabled(): boolean {
      return !this.identifiers
        || this.updateChunkIdentifier === undefined || this.updateChunkIdentifier < 0 || this.updateChunkIdentifier > 9999
        || this.isLoading;
    },

    async mintLand() {
      if (!isValidWeb3Address(this.minter) || !isValidWeb3Address(this.reseller) || this.tier === undefined || this.chunkId === undefined) {
        return;
      }
      try {
        this.isLoading = true;
        if (this.quantity === undefined || this.quantity === 1) {
          await this.mintCBKLand({
            minter: this.minter,
            tier: this.tier,
            chunkId: this.chunkId,
            reseller: this.reseller,
          });
        } else {
          await this.massMintCBKLand({
            minter: this.minter,
            tier: this.tier,
            chunkId: this.chunkId,
            reseller: this.reseller,
            quantity: this.quantity,
          });
        }
        this.clearInputs();
      } finally {
        this.isLoading = false;
      }
    },

    async updateId() {
      if (!this.identifiers || !this.updateChunkIdentifier) return;
      try {
        this.isLoading = true;
        const ids = this.identifiers.split(',').map(id => +id);
        if (ids.length === 1) {
          await this.updateChunkId({
            id: ids[0],
            chunkId: this.updateChunkIdentifier,
          });
        } else {
          await this.updateChunkIds({
            ids,
            chunkId: this.updateChunkIdentifier,
          });
        }
        this.clearInputs();
      } finally {
        this.isLoading = false;
      }

    },

    clearInputs() {
      this.minter = '';
      this.tier = undefined;
      this.chunkId = undefined;
      this.reseller = '';
      this.quantity = undefined;
      this.updateChunkIdentifier = undefined;
      this.identifiers = '';
      this.ids = [];
    }
  },

});
</script>

<style scoped>
.gap-3 {
  gap: 1rem;
}
</style>
