<template>
  <div>
    <b-dropdown right no-caret class="options-dropdown">
      <template slot="button-content"><b-icon-three-dots/></template>
      <b-dropdown-item :disabled="+option.amount === 0" v-for="option in options" :key="option.name" @click="option.handler(nftId)">
        {{option.name}} ({{option.amount}} left)
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
  handler: (id: number | string) => any;
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

.options-dropdown .btn:not(.disabled):not(:disabled):hover {
  background: #545b62;
  border: 0 !important;
  border-radius: 16px !important;
}
</style>