<template>
  <div class="d-flex flex-column align-items-start gap-2 p-1">
    <h2 class="m-0">{{ $t('admin.grantGameAdminRole') }}</h2>
    <b-form-input v-model="walletAddress" :placeholder="$t('admin.pasteInValidWalletAddress')"/>
    <b-button variant="primary" @click="onSubmit" :disabled="!isValidWeb3Address || isLoading">
      {{ $t('admin.grantRole') }}
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
  grantGameAdminRole(payload: { walletAddress: string, contract: Contract<any> }): Promise<void>;
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
  },

  data() {
    return {
      walletAddress: '',
      isLoading: false,
      isValidWeb3Address
    } as Data;
  },

  methods: {
    ...mapActions(['grantGameAdminRole']) as StoreMappedActions,
    async onSubmit() {
      try {
        this.isLoading = true;
        await this.grantGameAdminRole({walletAddress: this.walletAddress, contract: this.contract});
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
