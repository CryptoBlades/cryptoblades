<template>
  <div class="main-content">
    <div class="content-wrap">
      <CharacterInfo />
      <div class="char-img">
        <img :src="require('@/assets/new-ui/character/character-' + characterID + '.png')" alt="character-default">
      </div>
      <CharacterSkin />
    </div>
  </div>
</template>

<script>
import CharacterInfo from '@/components/Character/Info';
import CharacterSkin from '@/components/Character/Skin';

export default {
  name: 'Home',
  components: {
    CharacterInfo,
    CharacterSkin
  },
  computed : {
    characterID() {
      return this.$route.params.id;
    }
  }
};
</script>

<style scoped>
.content-wrap {
  background: url("../assets/new-ui/background/artwork-fantasy-art-ruins-game-wallpaper.png") no-repeat;
  background-size: cover;
}
</style>
