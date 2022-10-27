<template>
  <div class="d-flex flex-column flex-md-row menu-nav justify-content-between">
    <div class="mobile-menu">
      <span :class="activeTab === 'wallet-quests' ? 'active' : ''" @click="$emit('toggle', 'wallet-quests')">
        <span id="wallet-quests"></span> {{$t('quests.questTemplateType.WALLET')}}
      </span>
      <span :class="activeTab === 'character-quests' ? 'active' : ''" @click="$emit('toggle', 'character-quests')">
        <span id="character-quests"></span> {{$t('quests.questTemplateType.CHARACTER')}}
      </span>
    </div>
    <div class="d-flex flex-column flex-md-row">
      <div role="button" class="nav-quest none-mobile" :class="['d-flex gap-3 align-items-center link',
        activeTab === 'wallet-quests' ? 'active' : '']" @click="$emit('toggle', 'wallet-quests')">
        <div class="img-nav">
          <div class="img-frame"></div>
          <img src="../assets/navbar-icons/quests-icon.png"/>
        </div>
        <span class="main-font text-white fs-5">{{$t('quests.questTemplateType.WALLET')}}</span>
      </div>
      <div class="w-100 d-block d-md-none none-mobile"></div>
      <div class="separator d-none d-md-block mx-3 none-mobile"></div>
      <div role="button" class="nav-quest none-mobile" :class="['d-flex gap-3 align-items-center link',
        activeTab === 'character-quests' ? 'active' : '']" @click="$emit('toggle', 'character-quests')">
        <div class="img-nav">
          <div class="img-frame"></div>
          <img src="../assets/navbar-icons/plaza-icon.png"/>
        </div>
        <span class="main-font text-white fs-5">{{$t('quests.questTemplateType.CHARACTER')}}</span>
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
      default: 'wallet-quests'
    },
  },

});

</script>

<style scoped lang="scss">
.mobile-menu{
  display: none;
}

@media (max-width: 767px) {
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
    font-size: 0.8em;
  }

  .mobile-menu > span.active{
    font-family: Trajan;
    color: #fff;
    display: flex;
    align-items: center;
    font-size: 0.8em;
  }

  .none-mobile{
    display: none !important;
  }
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
}

#wallet-quests{
  content: url('../assets/navbar-icons/quests-icon.png');
  height: 1.1em;
  margin-right: 1em;
}

#character-quests {
  content: url('../assets/navbar-icons/plaza-icon.png');
  height: 1.1em;
  margin-right: 1em;
}

</style>
