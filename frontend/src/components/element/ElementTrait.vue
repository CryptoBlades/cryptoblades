<template>
    <img :width="width" :src="imageSrc" alt="">
</template>
<script lang="ts">
import earth from '@/assets/elements/icon-earth.png';
import fire from '@/assets/elements/icon-fire.png';
import lightning from '@/assets/elements/icon-thunder.png';
import water from '@/assets/elements/icon-water.png';
import Vue from 'vue';
export default Vue.extend({
  data(){
    return{
      imageSrc: '',
      earth,
      fire,
      lightning,
      water,
    };
  },
  props:{
    width:{
      type: Number,
      required: false,
      default: 10,
    },
    traitName:{
      type: String,
      required: false,
    },
  },
  mounted(){
    this.getElementImage();
  },
  methods:{
    getElementImage(){
      if(!this.traitName) return;
      switch(this.traitName.toLowerCase()){
      case 'earth':
        this.imageSrc = earth;
        break;
      case 'water':
        this.imageSrc = water;
        break;
      case 'fire':
        this.imageSrc = fire;
        break;
      case 'lightning':
        this.imageSrc = lightning;
        break;
      default:
        break;
      }
    }
  }
});
</script>
