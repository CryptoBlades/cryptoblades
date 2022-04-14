<template>
  <div>
    <b-dropdown right no-caret class="options-dropdown">
      <template slot="button-content"><b-icon-three-dots/></template>
      <b-dropdown-item :disabled="isDisabled(option)" v-for="option in options" :key="option.name"
      @click="nftType ? option.handler(nftId, nftType) : option.handler(nftId)">
        {{option.name}} <span v-if="!option.noAmount">({{option.amount}} {{$t('nftOptionsDropdown.left')}})</span>
      </b-dropdown-item>
      <b-dropdown-item v-if="showTransfer" @click="resultMsg = ''; $refs['character-transfer-modal'].show()">
        {{$t('nft.transferMenuItem')}}
      </b-dropdown-item>
    </b-dropdown>

    <b-modal
      class="centered-modal"
      ref="character-transfer-modal"
      :ok-title="$t('nft.transferOkButton')"
      @ok="transfer"
      :ok-disabled="!isValidAddress || receiverAddress === ''  || isSending"
      :cancel-disabled="isSending"
      >
      <template #modal-title>
        Send your {{nftType}} to another account
      </template>
      <b-form-input placeholder="Receiver Address" v-model="receiverAddress"/>
      <div class="transferResultContainer">
        <div class="loader" v-if="isSending">
          <i class="fas fa-spinner fa-spin"></i>
            Loading...
        </div>
        <span class="resultMsg text-center"> {{(!isValidAddress && receiverAddress !== '') ? 'Invalid address' : ''}} </span>
        <span class="resultMsg text-center"> {{resultMsg}} </span>
      </div>
    </b-modal>

  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import { PropType } from 'vue/types/options';
import { mapActions } from 'vuex';

interface StoreMappedActions {
  transferNFT(payload: {
    nftId: number;
    receiverAddress: string;
    nftType: string;
  }): Promise<void>;
}

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
    },
    showTransfer: {
      type: Boolean,
      default: false,
    },
  },
  data: () => ({
    receiverAddress: '' as string,
    isSending: false as boolean,
    resultMsg: '' as string,
    successfullTransfer: false as boolean,
  }),
  computed: {
    isValidAddress() {
      return /^0x[a-fA-F0-9]{40}$/.test(this.receiverAddress);
    },
  },
  methods: {
    ...(mapActions([
      'transferNFT',
    ]) as StoreMappedActions),
    isDisabled(option: NftOption): boolean {
      return !option.hasDefaultOption && +option.amount === 0;
    },
    async transfer(bvModalEvt: Event) {
      bvModalEvt.preventDefault();
      this.isSending = true;
      try {
        await this.transferNFT({
          nftId: this.nftId,
          receiverAddress: this.receiverAddress,
          nftType: this.nftType
        });
      }
      catch(e: any) {
        if(e.code as number === 4001) this.resultMsg = 'You cancelled the transaction.';
        else this.resultMsg = 'Error while transferring your ' + this.nftType + ' to ' + this.receiverAddress;
      }
      this.isSending = false;
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
  opacity: 0.5;
  pointer-events: none;
}

.options-dropdown .btn:not(.disabled):not(:disabled):hover {
  background: #545b62;
  border: 0 !important;
  border-radius: 16px !important;
}
.transferResultContainer{
  display:flex;
  align-items:center;
  flex-direction: column;
  margin-top: 20px;
  overflow: hidden;
}
.resultMsg{
  color: rgb(197, 48, 48);
  font-size: 1.5rem;
}
.success{
  color: rgb(0, 128, 0);
}
.loader{
  text-align: center;
  font-size: 1.5em;
}
</style>
