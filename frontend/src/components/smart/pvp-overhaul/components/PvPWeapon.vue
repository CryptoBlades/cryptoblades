<template>
  <div>
    <div v-if="disabled">
      DISABLED
    </div>
    <div v-else class="mainWrapper" @click="$emit('click')">
      <div class="starsWrapper">
        <img
          v-for="index in stars"
          :key="index"
          src="../../../../assets/star.svg"
          alt="star"
        />
      </div>
      <div class="weaponWrapper">
        <img :src="getWeaponArtById(weaponId)" alt="weapon image">
      </div>
      <div class="elementWrapper">
        <img :src="getElementImageUrl" alt="element icon" />
      </div>
    </div>
  </div>
</template>

<script>
import fire from '../../../../assets/elements/fire.png';
import water from '../../../../assets/elements/water.png';
import earth from '../../../../assets/elements/earth.png';
import lightning from '../../../../assets/elements/lightning.png';
import { getWeaponArtById } from '../../../../weapon-arts-placeholder';

export default {
  props: {
    stars: {
      type: Number,
      required: true,
      min: 0,
      max: 5,
      default: 0
    },
    element: {
      type: String,
      required: true,
      default: ''
    },
    weaponId: {
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
  },

  methods: {
    getWeaponArtById,
  },
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
.weaponWrapper {
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
</style>