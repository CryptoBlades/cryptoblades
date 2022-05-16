<template>
    <div class="d-flex gap-4 align-items-center ">
        <div role="button" :class="[
           'd-flex gap-3 align-items-center link',
           (!garrison && havePlazaCharacters) ? 'active' : ''
         ]"
          @click="toggleGarrison"
        >
          <div class="img-nav">
            <div class="img-frame"></div>
            <img src="../assets/navbar-icons/plaza-icon.png"/>
          </div>
          <span class="main-font text-white fs-5">{{$t('Character.info')}}</span>
         </div>
         <div class="separator"></div>
         <div role="button" :class="[
           'd-flex gap-3 align-items-center link',
           (garrison || !havePlazaCharacters) ? 'active' : ''
         ]"
          @click="toggleGarrison"
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
    }
  },
  methods: {
    toggleGarrison(): void {
      this.$emit('toggle');
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