<template>
  <div class="pvpCharacterWrapper">
    <img v-if="characterTrait" :src="characterArtSrc" alt="character" class="characterImg" />
  </div>
</template>

<script>
import { getCharacterArtByTrait } from '@/character-arts-placeholder';
export default {
  props: {
    characterTrait: {
      default: '',
      required: true
    }
  },
  computed: {
    characterArtSrc() {
      return getCharacterArtByTrait(this.characterTrait);
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
  padding-bottom: 1rem;
}
.characterImg {
  width: 100%;
  object-fit: contain;
  max-height: 60vh;
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
