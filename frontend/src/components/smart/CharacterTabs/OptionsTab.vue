<template>
    <b-tab :title="$t('Character.options')" title-item-class="character-wrapper"  title-link-class="character-tab">
      <div class="mt-2">
        <div class="d-flex py-4 options-border">
          <div class="options-text main-font">
            <h3>{{$t('Character.changeTrait')}}</h3>
            <p>{{$t('Character.changeTraitText')}}</p>
          </div>
          <button @click="$emit('openChangeTrait')" class="options-button main-font">{{$t('Character.change')}}</button>
        </div>
        <div  class="d-flex py-4 options-border">
          <div class="options-text main-font">
            <h3>{{$t('Character.sendToGarrison')}}</h3>
            <p>{{$t('Character.sendToGarrisonText')}}</p>
          </div>
          <button @click="$emit('onSendToGarrison')"  class="options-button main-font">{{$t('Character.send')}}</button>
        </div>
        <div  class="d-flex py-4 options-border">
          <div class="options-text main-font">
            <h3>{{$t('Character.transfer')}}</h3>
            <p>{{$t('Character.transferText')}}</p>
          </div>
          <button @click="$emit('openTransferModal')" class="options-button main-font">{{$t('Character.transfer')}}</button>
        </div>
      </div>
    </b-tab>
</template>

<script lang="ts">
import Vue from 'vue';

export default Vue.extend();
</script>

<style lang="scss" scoped>

.options-border {
  border-bottom: 1px solid #404857;
}

.options-text {
  width: 100%;
}

.options-text h3 {
  font-size: 21px;
  line-height: 24px;
  margin: 0;
  color: #fff;
}

.options-text p {
  font-size: 16px;
  line-height: 21px;
  margin: 0;
  color: #B9BFCC;
}

.options-button {
  height: 54px;
  min-width: 150px;
  background-color: #1E293C;
  outline: none;
  border: 1px solid #1E293C;
  color: white;
  font-size: 15px;
  line-height: 20px;
}

.options-button:hover {
  background-color: #1168D0;
}

.options-button:disabled {
  color: #818692;
  background-color: #1E293C;
}


</style>