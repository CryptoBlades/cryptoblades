<template>
  <div class="d-flex flex-column align-items-start gap-2 p-1">
    <h2 class="m-0">{{ $t('admin.revokeGivenRole', {role: roleName}) }}</h2>
    <b-form-input v-model="walletAddress" :placeholder="$t('admin.pasteInValidWalletAddress')"/>
    <b-button variant="primary" @click="onSubmit" :disabled="!isValidWeb3Address(walletAddress) || isLoading">
      {{ $t('admin.revokeRole') }}
    </b-button>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import {mapActions} from 'vuex';
import {Contract} from '@/interfaces';
import {PropType} from 'vue/types/options';
import {isValidWeb3Address} from '@/utils/common';

interface StoreMappedActions {
  revokeRole(payload: { walletAddress: string, contract: Contract<any>, roleMethod: any }): Promise<void>;
}

interface Data {
  walletAddress: string;
  isLoading: boolean;
}

export default Vue.extend({
  props: {
    contract: {
      type: Object as PropType<Contract<any>>,
      required: true,
    },
    roleMethod: {
      type: Function as PropType<() => Promise<void>>,
      required: true,
    },
    roleName: {
      type: String as PropType<string>,
      required: true,
    },
  },

  data() {
    return {
      walletAddress: '',
      isLoading: false,
      isValidWeb3Address
    } as Data;
  },

  methods: {
    ...mapActions(['revokeRole']) as StoreMappedActions,
    async onSubmit() {
      try {
        this.isLoading = true;
        await this.revokeRole({
          walletAddress: this.walletAddress,
          contract: this.contract,
          roleMethod: this.roleMethod
        });
      } catch (e) {
        console.error(e);
      } finally {
        this.walletAddress = '';
        this.isLoading = false;
      }
    }
  },

});
</script>

<style scoped>
.gap-2 {
  gap: 0.5rem;
}
</style>
