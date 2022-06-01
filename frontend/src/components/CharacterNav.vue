<template>
    <div class="d-flex flex-column flex-md-row">
        <div class="mobile-menu">
          <span :class="activeTab === 'info' ? 'active' : ''" @click="activeTab = 'info',$emit('toggle') ">
          <span id="plaza"></span> {{$t('Character.info').toUpperCase()}}</span>
          <span :class="activeTab === 'garrison' ? 'active' : ''" @click="activeTab = 'garrison',$emit('toggle')">
            <span id="garisson"></span>{{$t('Character.garrison').toUpperCase()}}</span>
        </div>
        <div role="button" class="nav-char none-mobile" :class="['d-flex gap-3 align-items-center link',
           (!garrison && havePlazaCharacters) ? 'active' : '']" @click="$emit('toggle')">
          <div class="img-nav">
            <div class="img-frame"></div>
            <img src="../assets/navbar-icons/plaza-icon.png"/>
          </div>
          <span class="main-font text-white fs-5">{{$t('Character.info')}}</span>
        </div>
        <div class="w-100 d-block d-md-none none-mobile"></div>
        <div class="separator d-none d-md-block mx-3 none-mobile"></div>
        <div role="button" class="none-mobile" :class="['d-flex gap-3 align-items-center link mt-4 mt-md-0',
           (garrison || !havePlazaCharacters) ? 'active' : '']" @click="$emit('toggle')">
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
         <div
            v-if="ownCharacters.length <= 4"
            class="ml-3 mt-4 mt-md-0 ml-md-auto recruit-btn text-uppercase custom-recruit-text-size mint-character"
            @click="$emit('mintCharacter')"
            v-tooltip="$t('plaza.recruitNew')" tagname="recruit_character">
            {{$t('plaza.recruit')}} <span class="gtag-link-others custom-recruit-text">({{ recruitCost }} NON-IGO SKILL)</span>
        </div>
    </div>
</template>

<script lang="ts">
import Vue from 'vue';


export default Vue.extend({
  data(){
    return{
      activeTab: 'info'
    };
  },
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
custom-recruit-text-size{
  font-size: 20px;
  font-weight: bold;
}
.custom-recruit-text{
  color: #e9c97a;
}
.recruit-btn{
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
  color: #fff;
  font-size: 17px;
  margin: auto;
  margin-right: -10px;
  cursor: pointer;
}
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

.mint-character {
  z-index: 1;
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

.char-content{
  padding: 50px;
}

.mobile-menu{
  display: none;
}


@media (max-width: 600px) {
   .mobile-menu{
    display: flex;
    justify-content: space-evenly;
    padding: 10px 0px;
    align-items: center;
    background-color: rgba(20, 20, 20);
    border-bottom: 1px solid rgba(255, 255, 255, 0.418);
    z-index: 5;
  }

  .mobile-menu > span{
    font-family: Trajan;
    color: rgba(255, 255, 255, 0.459);
    display: flex;
    align-items: center;
  }

  .mobile-menu > span.active{
    font-family: Trajan;
    color: #fff;
    display: flex;
    align-items: center;
  }

  .none-mobile{
    display: none;
  }

  .char-content{
    padding: 0px;
  }

  .char-info{
    padding: 50px !important;
  }
}

#plaza{
  content: url('../assets/navbar-icons/plaza-icon.png');
  height: 1.1em;
  margin-right: 1em;
}

#garisson{
  content: url('../assets/garisson.png');
  height: 1.1em;
  margin-right: 1em;
}

</style>
