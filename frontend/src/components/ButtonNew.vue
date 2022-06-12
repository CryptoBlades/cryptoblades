<template>
  <button
    class="button-new"
    v-tooltip="toolTip"
    @click="!isDisabled ? $emit('clickEvent') : ''"
    >
    <span :class="isDisabled ? 'disabled' : ''">
      <span class="custom-title-font" :class="customTitleClass">{{title}}<br></span>
      <span class="custom-subtitle-font" :class="customSubTitleClass">{{subTitle}}</span>
    </span>
  </button>
</template>
<script lang="ts">
import Vue from 'vue';
export default Vue.extend({
  props:{
    title:{
      type:String,
      required:true
    },
    subTitle:{
      type:String,
      required:false
    },
    toolTip:{
      type: String,
      required: false
    },
    isDisabled:{
      type:Boolean,
      required:false,
      default: false
    },
    loadingText:{
      type:String,
      required: false
    },
    customTitleClass:{
      type:String,
      required: false
    },
    customSubTitleClass:{
      type:String,
      required: false
    },
  }
});
</script>
<style lang="scss" scoped>
.disabled{
  opacity: 0.5;
}
.custom-title-font{
  font-family: Oswald;
  color: #fff;
}
.custom-subtitle-font{
  color: #e9c97a;
  font-family: "Roboto", sans-serif;
}
.button-new {
  display: flex;
  flex-direction: column;
  height: 100%;
  margin-right: 15px;
  align-items: center;
  vertical-align: middle;
  justify-content: center;
  background-image: url('../assets/btn-long.svg');
  background-color: transparent;
  background-repeat: no-repeat;
  background-size: 100% 100%;
  object-fit: fill;
  padding: 10px 40px 10px 40px;
  border: none;
  font-family: Oswald;
  text-transform: uppercase;
  color: #fff;
  font-size: 15px;
  margin: auto;
  margin-right: -40px;
  font-weight: bolder;
}
</style>
