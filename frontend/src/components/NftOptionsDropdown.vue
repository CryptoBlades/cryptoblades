<template>
  <div>
    <b-dropdown right no-caret class="options-dropdown">
      <template slot="button-content"><b-icon-three-dots/></template>
      <b-dropdown-item :disabled="isDisabled(option)" v-for="option in options" :key="option.name"
      @click="nftType ? option.handler(nftId, nftType) : option.handler(nftId)">
        {{option.name}} <span v-if="!option.noAmount">({{option.amount}} {{$t('nftOptionsDropdown.left')}})</span>
      </b-dropdown-item>
    </b-dropdown>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import { PropType } from 'vue/types/options';

export interface NftOption {
  name: string;
  amount: number;
  handler: (id: number | string, type?: string) => any;
  hasDefaultOption?: boolean;
  noAmount?: boolean;
}

export default Vue.extend({
  props: {
    options: {
      type: Array as PropType<NftOption[]>,
      default() {
        return [];
      },
    },
    nftId: {
      type: Number,
      default: null
    },
    nftType: {
      type: String,
      default: '',
    }
  },

  methods: {
    isDisabled(option: NftOption): boolean {
      return !option.hasDefaultOption && +option.amount === 0;
    }
  }
});
</script>

<style>
.options-dropdown .btn {
  background: transparent;
  border: 0 !important;
  border-radius: 16px !important;
  z-index: 1;
}

.dropdown-item.disabled {
  opacity: 50%;
  pointer-events: none;
}

.dropdown-item {
  padding: 0;
}

.options-dropdown .btn:not(.disabled):not(:disabled):hover {
  background: #545b62;
  border: 0 !important;
  border-radius: 16px !important;
}
</style>