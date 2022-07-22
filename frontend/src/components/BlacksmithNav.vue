<template>
    <div class="d-flex flex-column flex-md-row menu-nav justify-content-between">
        <div class="d-flex flex-column flex-md-row mr-3">
          <div role="button" class="nav-char none-mobile" :class="['d-flex gap-3 align-items-center link',
            (activeTab === 'forge') ? 'active' : '']" @click="$emit('toggle', 'forge')">
            <div class="img-nav">
              <img src="../assets/blacksmith/forge.png"/>
            </div>
            <span class="main-font text-muted fs-5">{{$t('blacksmith.forge')}}</span>
          </div>
          <div class="w-100 d-block d-md-none none-mobile"></div>
          <div class="separator d-none d-md-block mx-3 none-mobile"></div>
          <div role="button" class="none-mobile" :class="['d-flex gap-3 align-items-center link mt-4 mt-md-0',
            (activeTab === 'salvage') ? 'active' : '']" @click="$emit('toggle', 'salvage')">
            <div class="img-nav">
              <img src="../assets/blacksmith/salvage.png"/>
            </div>
            <span  class="main-font text-muted fs-5">{{$t('blacksmith.salvage')}}</span>
          </div>
        </div>
        <div class="d-flex flex-column flex-md-row justify-contenct-center" v-if="activeTab === 'forge'" >
          <cb-button v-if="reforgeWeaponId !== null && ownWeapons.length > 0" class="custom-cb-btn custom-reforge-btn" tagname="weapon_special_forge"
            :title="$t('blacksmith.reforgeWithDust')"
            @clickEvent="$emit('displayDustReforge')"
            :toolTip="$t('blacksmith.useDust')"
          />
          <cb-button class="custom-cb-btn custom-special-forge-btn" tagname="weapon_special_forge" :title="$t('blacksmith.specialForge')"
            @clickEvent="$emit('onClickSpecialForge')"
            :toolTip="$t('blacksmith.specialForgeTooltip')"
          />
          <cb-button class="custom-cb-btn custom-forge-btn gtag-link-others" tagname="weapon_forge_single"
            :title="`${disableForge ? $t('blacksmith.coolingForge') : $t('blacksmith.forge')} x1 <br/>`"
            :isLoading="isLoading"
            :subTitle="`(${forgeCost === '0' ? '0.0000' : forgeCost} SKILL)`" @clickEvent="$emit('onClickForge', 0)" :toolTip="$t('blacksmith.forgeNew')"
            :isDisabled="disableForge"
          />
          <cb-button class="custom-cb-btn custom-forge-btn gtag-link-others" tagname="weapon_forge_multiple"
            :title="`${disableForge ? $t('blacksmith.coolingForge') : $t('blacksmith.forge')} x10 <br/>`"
            :isLoading="isLoading"
            :subTitle="`(${forgeCost === '0' ? '0.0000' : forgeCost} SKILL)`" @clickEvent="$emit('onClickForge', 1)"
            :isDisabled="disableX10Forge || disableForge || (disableX10ForgeWithStaked && useStakedForForge)"
            :toolTip="(disableX10Forge) ? $t('blacksmith.disableDynamicMintingForge') : $t('blacksmith.forge10New')"
            :style="disableX10Forge ? 'opacity: 0.5' : ''"
          />
          <b-checkbox
            class="custom-staking-checkbox"
            :disabled="disableUseStakedForForge"
            @change="$emit('setStakedForForgeValue', $event)">
            <span v-if="disableUseStakedForForge"> <b>{{$t('blacksmith.notEnoughStakedSkill')}}<br></b></span>
            <span v-html="$t('blacksmith.spendStakedFunds')"></span>
          </b-checkbox>
          <div class="tooltip-container">
            <b-icon-question-circle class="centered-icon" scale="1.5"
              v-on:click="$emit('onShowForgeDetails')" v-tooltip.bottom="$t('blacksmith.clickForForgePercentages')"/>
          </div>
      </div>
    </div>
</template>

<script lang="ts">
import Vue from 'vue';

export default Vue.extend({
  props: {
    activeTab: {
      type: String,
      required: true
    },
    forgeCost: {
      type: String,
      required: true,
    },
    isLoading: {
      type: Boolean,
      default: true
    },
    disableForge: {
      type: Boolean,
      required: false,
      default: false
    },
    disableX10Forge: {
      type: Boolean,
      required: false,
      default: false
    },
    disableX10ForgeWithStaked: {
      type: Boolean,
      required: false,
      default: false
    },
    useStakedForForge: {
      type: Boolean,
      required: false,
      default: false
    },
    disableUseStakedForForge: {
      type: Boolean,
      required: false,
      default: false
    },
    ownWeapons: {
      type: Array,
      required: true,
    },
    reforgeWeaponId: {
      type: String,
      required: false,
      default: null
    },
  },

});

</script>
<style scoped lang="scss">
*{
  z-index: 1;
}
.custom-reforge-btn{
  margin-right: -5px !important;
}
.custom-special-forge-btn{
  margin-right: 15px !important;
}
.custom-staking-checkbox{
  font-size: 14px;
  margin-right: 15px;
}

.custom-cb-btn{
  height: 120% !important;
  font-weight: normal !important;
  margin-top: -3px !important;
  font-size: 14px !important;
}
.custom-forge-btn{
  margin-right: 15px !important;
  font-size: 14px !important;
}
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

.mint-blacksmith {
  z-index: 1;
}

.mint-blacksmith > span{
  font-family: Roboto;
  color: #e9c97a;
}

.mint-blacksmith > span > span{
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
  height: 40px;
  width: 35px;
  display: grid;
  place-items: center;
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
    height: 40px;
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

.blacksmith-content{
  padding: 50px;
}

.mobile-menu{
  display: none;
}

.tooltip-container{
  display: flex;
  align-items: center;
  justify-content: center;
}
.custom-control-label > span {
  white-space: nowrap;
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

  .blacksmith-content div.menu-nav{
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

  .blacksmith-content{
    padding: 0px;
  }

  .char-info{
    padding: 50px !important;
  }
}
</style>
