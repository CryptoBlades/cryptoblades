<template>
     <div class="skale-banner">
      <p>{{$t('skaleBanner.clickToRequest')}}</p>
      <button class="skale-btn" @click="getSkale" :disabled="isLoading">
        {{ isLoading ? $t('skaleBanner.pleaseWait') : $t('skaleBanner.requestSkale')}}
      </button>
    </div>
</template>

<script lang="ts">
import Vue from 'vue';
import { requestSkale } from '@/utils/common';

export default Vue.extend({
  data() {
    return {
      isLoading: false
    };
  },
  props: ['walletAddress'],
  methods: {
    requestSkale,
    async getSkale(){
      this.isLoading = true;
      const response = await this.requestSkale(this.walletAddress);
      (this as any).$dialog.notify.success(response);
      this.isLoading = false;
    }
  },
});
</script>

<style lang="scss" scoped>
  .skale-banner{
    display: flex;
    justify-content: center;
    align-items: center;
    padding-top: 1em;
    padding-bottom: 1em;
    gap: 1em;
    background-color: #000612;
    border-bottom: 1px solid #ffffff57;
    p{
      font-family: Roboto;
      margin: 0px;
    }
    button{
      &:hover{
        border: 1px solid rgb(255, 255, 255);
      }
      font-family: Roboto;
      background-color: rgba(255, 255, 255, 0);
      color: #fff;
      border: 1px solid rgba(255, 255, 255, 0.466);
      border-radius: 5px;
      padding: 0.2em 1.3em;
    }
  }

@media (max-width: 600px) {
  .skale-banner{
    padding-left: 1em;
    padding-right: 1em;
    font-size: 0.8em;
    button{
      font-size: 0.96em;
      white-space: nowrap;
    }
  }
}
</style>


