<template>
    <div class="d-flex flex-column flex-md-row menu-nav justify-content-between">
        <div class="mobile-menu">
          <span :class="activeTab === 'info' ? 'active' : ''" @click="$emit('toggle', 'info')">
          <span id="plaza"></span> {{$t('Character.info').toUpperCase()}}</span>
          <span :class="activeTab === 'garrison' ? 'active' : ''" @click="$emit('toggle', 'garrison')">
            <span id="garisson"></span>{{$t('Character.garrison').toUpperCase()}}</span>
          <span :class="activeTab === 'burn' ? 'active' : ''" @click="$emit('toggle', 'burn')">
            <span id="burn"></span>{{$t('Character.burn').toUpperCase()}}</span>
        </div>
        <div class="d-flex flex-column flex-md-row">
          <div role="button" class="nav-char none-mobile" :class="['d-flex gap-3 align-items-center link',
            (activeTab === 'info' && havePlazaCharacters) ? 'active' : '']" @click="$emit('toggle', 'info')">
            <div class="img-nav">
              <div class="img-frame"></div>
              <img src="../assets/navbar-icons/plaza-icon.png"/>
            </div>
            <span class="main-font text-white fs-5">{{$t('Character.info')}}</span>
          </div>
          <div class="w-100 d-block d-md-none none-mobile"></div>
          <div class="separator d-none d-md-block mx-3 none-mobile"></div>
          <div role="button" class="none-mobile" :class="['d-flex gap-3 align-items-center link mt-4 mt-md-0',
            (activeTab === 'garrison') ? 'active' : '']" @click="$emit('toggle', 'garrison')">
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
          <div class="separator d-none d-md-block mx-3 none-mobile"></div>
          <div role="button" class="nav-char none-mobile" :class="['d-flex gap-3 align-items-center link',
            (activeTab === 'burn') ? 'active' : '']" @click="$emit('toggle', 'burn')">
            <div class="img-nav">
              <div class="img-frame"></div>
              <img src="../assets/soul.png"/>
            </div>
            <span class="main-font text-white fs-5">{{$t('Character.characterBurn')}}</span>
          </div>
        </div>
        <div class="d-flex flex-column flex-md-row justify-content-center">
          <div v-if="activeTab === 'garrison'"
              class="mt-4 mt-md-0 ml-md-auto recruit-btn-custom text-uppercase custom-recruit-text-size mint-character"
              @click="$emit('onClaimGarrisonXp')"
              v-tooltip="$t('plaza.claimXp')">
              <span class="gtag-link-others custom-recruit-text"> <span>{{$t('plaza.claimXp')}}</span></span>
          </div>
          <div v-if="ownCharacters.length <= 4 && activeTab === 'info'"
              class="ml-3 mt-4 mt-md-0 ml-md-auto recruit-btn text-uppercase custom-recruit-text-size mint-character"
              @click="$emit('mintCharacter')"
              v-tooltip="$t('plaza.recruitNew')" tagname="recruit_character">
              <span class="gtag-link-others custom-recruit-text"> <span>{{$t('plaza.recruit')}}</span> ({{ recruitCost }} NON-IGO SKILL)</span>
          </div>
          <div v-if="ownCharacters.length <= 4 && activeTab === 'info'"
              class="ml-3 mt-4 mt-md-0 ml-md-auto soul-border text-uppercase custom-recruit-text-size mint-character"
              @click="$emit('changeTab', 'burn')"
              v-tooltip="'Soul Balance'" tagname="recruit_character">
              <span class="gtag-link-others custom-recruit-text">
                <span class="soul-icon"></span>
                {{ soulBalance.toLocaleString() }}
                <span class="add-skill"></span>
              </span>
          </div>
        </div>
    </div>
</template>

<script lang="ts">
import Vue from 'vue';


export default Vue.extend({
  props: {
    soulBalance: {
      type: Number,
      default: 0
    },
    activeTab: {
      type: String,
      default: 'info'
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
.custom-padding-claim-garrison-xp{
  padding: 10px 40px 10px 40px !important;
}
.custom-recruit-text{
  color: #e9c97a;
}
.recruit-btn-custom{
  display: flex;
  flex-direction: column;
  height: 100%;
  margin-right: 15px;
  align-items: center;
  vertical-align: middle;
  align-items: center;
  justify-content: space-between;
  background-image: url('../assets/recruit-btn.svg');
  background-color: transparent;
  background-repeat: no-repeat;
  background-size: 100% 100%;
  object-fit: fill;
  padding: 5px 70px 5px 80px;
  border: none;
  font-family: Oswald;
  color: #fff;
  font-size: 20px;
  margin: auto;
  cursor: pointer;
}

.recruit-btn{
  display: flex;
  flex-direction: column;
  height: 100%;
  margin-right: 15px;
  align-items: center;
  vertical-align: middle;
  justify-content: center;
  background-image: url('../assets/recruit-btn.svg');
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

.soul-border{
  display: flex;
  flex-direction: column;
  height: 100%;
  margin-right: 15px;
  align-items: center;
  vertical-align: middle;
  align-items: center;
  justify-content: space-between;
  background-image: url('../assets/sool-border.svg');
  background-color: transparent;
  background-repeat: no-repeat;
  background-size: 100% 100%;
  object-fit: fill;
  padding: 5px 30px 5px 30px;
  border: none;
  font-family: Oswald;
  color: #fff;
  font-size: 17px;
  margin: auto;
  margin-right: -10px;
  cursor: pointer;
}

.soul-border > span{
  color: #fff !important;
}

.soul-icon{
  content: url('../assets/soul-icon.png');
  height: 17px;
  width: 12px;
  margin-right: 20px;
}

.add-skill{
  content: url('../assets/add-skill-icon.svg');
  height: 17px;
  width: 17px;
  margin-left: 5px;
  margin-bottom: -2px;
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

.mint-character > span{
  font-family: Roboto;
  color: #e9c97a;
}

.mint-character > span > span{
  font-family: Roboto;
  color: #fff;
}

.separator{
  border: 1px solid #7F8693;
  width: 68px;
  height: 0px;
  align-self: center;
}

.img-nav {
  position: relative;
  height: 28px;
  width: 28px;
  display: grid;
  place-items: center;
  padding: 5px;
  .img-frame {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    border: 1px solid #7F8693;
    transform: rotate(45deg);
  }
  img {
    height: 13px;
    filter: grayscale(100%);
  }
  .gar-container{
    display: flex;
    gap: 8px;
  }
  img.gar {
    height: 5px;
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
    padding: 0px 0px 10px 0px;
    align-items: center;
    border-bottom: 1px solid rgba(255, 255, 255, 0.418);
    z-index: 5;
  }

  .mobile-menu > span{
    font-family: Trajan;
    color: rgba(255, 255, 255, 0.459);
    display: flex;
    align-items: center;
  }

  .recruit-btn{
    background-image: url('../assets/recruit-btn.svg');
  }

  .recruit-btn{
    display: flex;
    flex-direction: column;
    height: 100%;
    margin-right: 15px;
    align-items: center;
    vertical-align: middle;
    justify-content: center;
    background-color: transparent;
    background-repeat: no-repeat;
    background-size: 100% 100%;
    object-fit: fill;
    padding: 7px 40px 7px 40px;
    border: none;
    font-family: Oswald;
    color: #fff;
    font-size: 17px;
    margin: auto;
    margin-right: -10px;
    cursor: pointer;
  }

  .recruit-btn > span {
    font-size: 0.8em;
    span{
      font-size: 0.9em;
    }
  }

  .char-content div.menu-nav{
    height: 100% !important;
    background-color: #000E29;
  }

  .mobile-menu > span.active{
    font-family: Trajan;
    color: #fff;
    display: flex;
    align-items: center;
    font-size: 0.8em;
  }

  .mobile-menu > span{
    font-family: Trajan;
    display: flex;
    align-items: center;
    font-size: 0.8em;
  }
  .none-mobile{
    display: none !important;
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

#burn{
  content: url('../assets/soul.png');
  height: 1.1em;
  margin-right: 1em;
}

</style>
