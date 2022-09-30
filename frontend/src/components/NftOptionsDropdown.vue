<template>
  <div>
    <b-dropdown right no-caret class="options-dropdown">
      <template slot="button-content"><b-icon-three-dots/></template>
      <b-dropdown-item :disabled="isDisabled(option)" v-for="option in options" :key="option.name"
      @click="nftType ? option.handler(nftId, nftType) : option.handler(nftId)">
        {{option.name}} <span v-if="!option.noAmount">({{option.amount}} {{$t('nftOptionsDropdown.left')}})</span>
      </b-dropdown-item>
      <b-dropdown-item v-if="showTransfer" @click="resultMsg = ''; $refs['character-transfer-modal'].show()">
        {{$t('nftOptionsDropdown.transferMenuItem')}}
      </b-dropdown-item>
    </b-dropdown>

    <b-modal
      centered
      hide-header hide-footer
      class="centered-modal"
      ref="character-transfer-modal"
      :ok-title="$t('nftOptionsDropdown.transferOkButton')"
      @ok="transfer"
      @shown="$refs.receiverAddress.focus()"
      :ok-disabled="!isValidAddress || receiverAddress === ''  || isSending"
      :cancel-disabled="isSending"
      >
      <div class="p-4">
        <h3 class="confirmation-title mb-5">{{$t('nftOptionsDropdown.sendYour')}} {{nftType}} {{$t('nftOptionsDropdown.toAnother')}} </h3>
        <b-form-input ref="receiverAddress" class="transfer-input" @keydown.enter.native="transfer"
                      :placeholder="$t('nftOptionsDropdown.receiverAddress')" v-model="receiverAddress"/>
        <div class="transferResultContainer">
          <div class="loader" v-if="isSending">
            <i class="fas fa-spinner fa-spin"></i>
              {{$t('loading')}}
          </div>
          <span class="resultMsg text-center"> {{(!isValidAddress && receiverAddress !== '') ? $t('nftOptionsDropdown.invalidAddress') : ''}} </span>
          <span class="resultMsg text-center"> {{resultMsg}} </span>
        </div>
        <div class="footer-btn">
          <button class="close-btn" @click="transfer">
            {{isSending ? t('nftOptionsDropdown.sending') : $t('nftOptionsDropdown.transfer')}}
          </button>
        </div>
      </div>
      <div class="footer-close" @click="$refs['character-transfer-modal'].hide()">
        <p class="tapAny mt-4">{{$t('tapAnyWhere')}}</p>
        <p class="close-icon"></p>
      </div>
    </b-modal>

  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import { PropType } from 'vue/types/options';
import { mapActions } from 'vuex';
import i18n from '@/i18n';
import {isValidWeb3Address} from '../utils/common';

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
      return isValidWeb3Address(this.receiverAddress);
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
        (this.$refs['character-transfer-modal'] as any).hide();
      }
      catch(e: any) {
        if(e.code as number === 4001) this.resultMsg = i18n.t('nftOptionsDropdown.cancelledTransaction').toString();
        else this.resultMsg =
         i18n.t('nftOptionsDropdown.errorTransfer').toString() + ' ' + this.nftType + ' ' +
         i18n.t('nftOptionsDropdown.to').toString() + ' ' + this.receiverAddress;
      }
      this.isSending = false;
    }
  }
});
</script>

<style>
.dropdown-menu {
  background: rgb(0,14,41);
  background: linear-gradient(
    45deg,
    rgb(0,14,41) 0%,
    rgb(1, 20, 57) 100%
  );
  border: 1px solid rgba(245, 245, 245, 0.116);
}

.dropdown-menu li a:hover {
  background: transparent;
}

.options-dropdown .btn {
  background: transparent;
  border-radius: 16px !important;
  z-index: 1;
}
.btn{
  border: 0 !important;
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

.transfer-input.form-control{
  background-color: #000E1D;
  border: 1px solid #323E55;
  color: rgb(255, 255, 255);
  font-family: Roboto;
  height: 3em;
}
.resultMsg{
  color: rgb(255, 91, 91);
  font-size: .9rem;
  font-family: Roboto;
}
.success{
  color: rgb(0, 128, 0);
}
.loader{
  text-align: center;
  font-size: 1.5em;
}
</style>
