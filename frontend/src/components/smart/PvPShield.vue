<template>
  <div>
    <div class="mainWrapper" @click="$emit('click')" :id="`${shieldId}-info`">
      <div class="starsWrapper">
        <img
          v-for="index in (shield.stars + 1)"
          :key="index"
          src="../../assets/star.svg"
          alt="star"
        />
      </div>
      <div class="shieldWrapper">
        <img :src="getShieldArt(shieldId)" alt="shield image">
        <b-popover ref="shield-info" :target="`${shieldId}-info`" triggers="hover">
          <div v-if="shieldId" class="shield-icon-wrapper">
            <nft-icon class="shield-icon" :nft="formattedShield" />
          </div>
        </b-popover>
      </div>
      <div class="elementWrapper">
        <img :src="getElementImageUrl" alt="element icon" />
      </div>
    </div>
  </div>
</template>

<script>
import fire from '../../assets/elements/fire.png';
import water from '../../assets/elements/water.png';
import earth from '../../assets/elements/earth.png';
import lightning from '../../assets/elements/lightning.png';
import foundersShield from '../../assets/shield1.png';
import legendaryShield from '../../assets/shield2.png';
import { BPopover } from 'bootstrap-vue';
import NftIcon from '../NftIcon.vue';

export default {
  components: {
    'nft-icon': NftIcon,
    'b-popover': BPopover,
  },

  props: {
    shield: {
      required: true,
    },
    shieldId: {
      type: String
    },
    disabled: {
      type: Boolean,
      default: false
    }
  },

  computed: {
    getElementImageUrl() {
      if (this.element === 'Fire') {
        return fire;
      }
      if (this.element === 'Water') {
        return water;
      }
      if (this.element === 'Earth') {
        return earth;
      } else {
        return lightning;
      }
    },

    formattedShield() {
      return {
        ...this.shield,
        type: 'shield'
      };
    }
  },

  methods: {
    getShieldArt(shieldId) {
      if(shieldId <= 10000){
        return foundersShield;
      }
      else if (shieldId > 10000 || shieldId <= 25000){
        return legendaryShield;
      }
      else{
        return '';
      }
    },
  }
};
</script>

<style scoped lang="scss">
.mainWrapper {
  position: relative;
  display: flex;
  flex-direction: column;
  height: 4.5rem;
  width: 4.5rem;
  padding: 0.25rem;
  border-radius: 0.375rem;
  background-color: #151515;
  border: 1px solid #cec198;
  :hover {
    cursor: pointer;
  }
}
.disabled {
  opacity: 30%;
  pointer-events: none;
}
.starsWrapper {
  display: flex;
  height: 13%;
  margin-left: 0.1rem;

  img {
    height: 0.5rem;
    width: 0.45rem;
    margin-right: 0.125rem;
    pointer-events: none;
  }
}
.shieldWrapper {
  display: flex;
  margin: 0 auto;
  height: 80%;
  width: 80%;
}
.elementWrapper {
  position: absolute;
  display: flex;
  width: 1.5rem;
  margin-left: auto;
  margin-right: auto;
  left: 0;
  right: 0;
  bottom: -25%;
  padding: 0.2rem;
  border: 1px solid #cec198;
  border-radius: 9999px;
  background-color: #151515;

  img {
    max-width: 100%;
    max-height: 100%;
  }
}
.shield-icon {
  height: 100%;
  width: 100%;
  position: relative;
  overflow: hidden;
}
.shield-icon-wrapper {
  background: rgba(255, 255, 255, 0.1);
  width: 12em;
  height: 12em;
  margin: 0 auto;
}
</style>