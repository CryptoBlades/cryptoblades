<template>
  <div class="pvpCharacterWrapper">
    <img v-if="characterId || characterId === 0" :src="characterArtSrc" alt="character" class="characterImg" />
    <img src="../../assets/placeholder/standImage.png" alt="stand" class="characterStand" />
  </div>
</template>

<script>
import { getCharacterArtById } from '../../character-arts-placeholder';
export default {
  props: {
    characterId: {
      default: null
    }
  },
  computed: {
    characterArtSrc() {
      return getCharacterArtById(this.characterId);
    }
  }
};
</script>

<style scoped lang="scss">
.pvpCharacterWrapper {
  position: relative;
  display: flex;
  flex-direction: column;
  width: 100%;
}
.characterImg {
  position: absolute;
  z-index: 1;
  width: 100%;
  height: 100%;
  bottom: 5%;
  margin: 0 auto;
  left: 50%;
  transform: translate(-50%, 0);
  object-fit: contain;
  display: flex;
  @media only screen and (min-width: 1024px) {
    bottom: 7%;
  }
  @media only screen and (min-width: 1280px) {
    bottom: 10%;
  }
  @media only screen and (min-width: 1680px) {
    bottom: 12%;
  }
}
.characterStand {
  position: absolute;
  bottom: 0;
  display: flex;
  width: 100%;
}
</style>