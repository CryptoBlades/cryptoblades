<template>
    <div class="d-flex flex-column flex-md-row">
        <div role="button" :class="[
           'd-flex gap-3 align-items-center link',
           (!garrison && havePlazaCharacters) ? 'active' : ''
         ]"
          @click="$emit('toggle')"
        >
          <div class="img-nav">
            <div class="img-frame"></div>
            <img src="../assets/navbar-icons/plaza-icon.png"/>
          </div>
          <span class="main-font text-white fs-5">{{$t('Character.info')}}</span>
        </div>
        <div class="w-100 d-block d-md-none"></div>
        <div class="separator d-none d-md-block mx-3"></div>
         <div role="button" :class="[
           'd-flex gap-3 align-items-center link mt-4 mt-md-0',
           (garrison || !havePlazaCharacters) ? 'active' : ''
         ]"
          @click="$emit('toggle')"
         >
          <div class="img-nav">
            <div class="img-frame"></div>
              <div class="gar-container">
                <img class="gar" src="../assets/navbar-icons/plaza-icon.png"/>
              </div>
              <div class="gar-container" >
                <img class="gar" src="../assets/navbar-icons/plaza-icon.png"/>
                <img class="gar" src="../assets/navbar-icons/plaza-icon.png"/>
              </div>
          </div>
          <span  class="main-font text-white fs-5">{{$t('Character.garrison')}}</span>
        </div>
        <div class="w-100 d-block d-md-none"></div>
         <b-button
          v-if="ownCharacters.length <= 4"
          variant="primary"
          class="ml-3 gtag-link-others  mt-4 mt-md-0 ml-md-auto"
          @click="$emit('mintCharacter')"
          v-tooltip="$t('plaza.recruitNew')" tagname="recruit_character">
          {{$t('plaza.recruit')}} ({{ recruitCost }} NON-IGO SKILL) <i class="fas fa-plus"></i>
        </b-button>
    </div>
</template>

<script lang="ts">
import Vue from 'vue';


export default Vue.extend({
  props: {
    garrison: {
      type: Boolean,
      default: false
    },
    havePlazaCharacters: {
      type: Boolean,
      default: false
    },
    ownCharacters: {
      type: Array,
      default: ()=> []
    },
    recruitCost: {
      type: String,
      default: '0'
    }
  },

});

</script>
<style scoped lang="scss">

.link {
    background: transparent;
    outline: none;
    border: none;
}

.active {
  .img-nav {
    .img-frame {
      border-color: #EDCD90;
    }
    img {
      filter: none;
    }
    img.gar{
      filter: none
    }
  }
}

.separator{
  border: 1px solid #7F8693;
  width: 68px;
  height: 0px;
  align-self: center;
}

.img-nav {
  position: relative;
  height: 48px;
  width: 48px;
  display: grid;
  place-items: center;
  padding: 8px;
  .img-frame {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    border: 2px solid #7F8693;
    transform: rotate(45deg);
  }
  img {
    height: 24px;
    filter: grayscale(100%);
  }
  .gar-container{
    display: flex;
    gap: 8px;
  }
  img.gar {
    height: 12px;
    filter: grayscale(100%);
  }
}


</style>