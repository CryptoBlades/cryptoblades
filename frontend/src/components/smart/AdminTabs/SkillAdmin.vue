<template>
    <div class="p-1">
        <h2>{{ $t('admin.skill.transferSkill') }}</h2>
        <div class="d-flex flex-column gap-2 m">
          <div class="d-flex align-items-center gap-3">
            <b-form-input v-model="transferModel.sourceWallet" :placeholder="$t('admin.skill.sourceWalletAddress')"/>
            <b-form-input v-model="transferModel.receiverAddress" :placeholder="$t('admin.skill.receiverWalletAddress')"/>
            <b-form-input v-model="transferModel.amount" :placeholder="$t('admin.skill.amount')" type="number" number min="0"/>
          </div>

          <div>
            {{ $t('admin.skill.skillAllowance') }} : {{ skillAllowance }}
          </div>
          <div>
            <b-button
                  :disabled="transferDisabled || loading"
                  @click="onTransfer"
                  variant="info"
                  class="text-nowrap"
            >
                {{ $t('admin.skill.transfer') }}
            </b-button>
          </div>
        </div>

    </div>
</template>

<script lang="ts">
import Vue from 'vue';
import { mapActions } from 'vuex';
import { isValidWeb3Address } from '@/utils/common';
import Web3 from 'web3';

export default Vue.extend({
  data() {
    return {
      loading: false,
      transferModel: {
        sourceWallet: null,
        receiverAddress: null,
        amount: 0
      },
      skillAllowance: 0
    };
  },
  watch: {
    transferModel: {
      async handler() {
        if(isValidWeb3Address(this.transferModel.receiverAddress || '') && isValidWeb3Address(this.transferModel.sourceWallet || '')) {
          this.skillAllowance = Number(Web3.utils.fromWei(await this.getSkillAllowance({
            sourceAddress: this.transferModel.sourceWallet,
            receiverAddress: this.transferModel.receiverAddress
          }), 'ether'));
        } else {
          this.skillAllowance = 0;
        }
      },
      deep: true
    }
  },
  computed: {
    transferDisabled(): boolean {
      return (!isValidWeb3Address(this.transferModel.receiverAddress || '')
        || !isValidWeb3Address(this.transferModel.sourceWallet || ''))
        || this.skillAllowance < this.transferModel.amount
        || this.transferModel.amount <= 0;
    }
  },
  methods: {
    ...mapActions([
      'approveSkillTransfer',
      'transferSkill',
      'getSkillAllowance',
      'fetchSkillBalance'
    ]),
    async onTransfer() {
      this.loading = true;
      try {
        await this.transferSkill({sourceAddress: this.transferModel.sourceWallet,
          receiverAddress:  this.transferModel.receiverAddress, amount:  this.transferModel.amount });

        await this.fetchSkillBalance();

        this.resetFormFields();
      } catch(e) {
        console.error(e);
      } finally {
        this.loading = false;
      }
    },
    resetFormFields() {
      this.transferModel = {
        sourceWallet: null,
        receiverAddress: null,
        amount: 0
      };
    }
  },
});
</script>

<style scoped>
</style>
