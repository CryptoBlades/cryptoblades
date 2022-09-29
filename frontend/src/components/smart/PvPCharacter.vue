<template>
  <div class="pvpCharacterWrapper">
    <img v-if="characterTrait" :src="characterArtSrc" alt="character" class="characterImg" />
  </div>
</template>

<script>
import { getCharacterArtByTraitAndVersion } from '@/character-arts-placeholder';
export default {
  props: {
    characterTrait: {
      default: '',
      required: true
    },
    characterVersion: {
      default: 0,
      required: true
    }
  },
  computed: {
    characterArtSrc() {
      return getCharacterArtByTraitAndVersion(this.characterTrait, this.characterVersion);
    }
  }
};
</script>

<style scoped lang="scss">
.pvpCharacterWrapper {
  position: relative;
  width: 100%;
  max-width: 500px;
  max-height: 100vh;
  height: max-content;
  background-image: url("../../assets/placeholder/standImage.png");
  background-size: contain;
  background-position-y: bottom;
  background-repeat: no-repeat;
  padding-bottom: 10%;
}
.characterImg {
  width: 100%;
  object-fit: contain;
  max-height: 45vh;
  max-width: 100%;
  transform: none;
}
.characterStand {
  position: absolute;
  bottom: 0;
  display: flex;
  width: 100%;
}
</style>
