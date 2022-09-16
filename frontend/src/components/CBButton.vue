<template>
  <button
    class="button-new"
    v-tooltip="toolTip"
    @click="!isDisabled ? $emit('clickEvent') : ''"
    :class="isDisabled ? 'disabled' : ''"
    >
    <span v-if="!isLoading">
      <span class="custom-title-font" :class="customTitleClass" v-html="title"></span>
      <span class="custom-subtitle-font" :class="customSubTitleClass">{{subTitle}}</span>
    </span>
    <span v-else :class="isDisabled ? 'disabled' : ''">
      <loader :bgColor="'#ffffff5b'" :width="'50%'" />
      <loader :bgColor="'#e9c97a'" :width="'9em'" />
    </span>
  </button>
</template>
<script lang="ts">
import Vue from 'vue';
import Loader from './loader/Loader.vue';
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
    isLoading:{
      type: Boolean,
      default: false
    }
  },
  components:{
    Loader
  }
});
</script>
<style lang="scss" scoped>
.disabled{
  opacity: 0.5;
}
.custom-title-font{
  font-family: Oswald;
  color: rgba(255, 255, 255);
  white-space: nowrap;
}
.custom-subtitle-font{
  color: #e9c97a;
  font-family: "Roboto", sans-serif;
  font-weight: normal;
  white-space: nowrap;
}
.button-new {
  display: flex;
  flex-direction: column;
  height: 100%;
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
  margin: auto;
  margin-right: -40px;
  font-weight: bolder;
}
</style>
