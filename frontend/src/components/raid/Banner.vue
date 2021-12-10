<template>
  <div class="banner">
    <div class="content-wrap">
      <CharacterBio />
    </div>
  </div>
</template>

<script>
import CharacterBio from '@/components/raid/CharacterBio';
export default {
  name: 'Banner',
  components: {
    CharacterBio,
  }
};
</script>

<style scoped>
.content-wrap {
  padding: 0;
}
.banner {
  width: 100%;
  background: url("../../assets/new-ui/background/artwork-fantasy-art-ruins-game-wallpaper.png") no-repeat;
  background-size: cover;
  border-bottom: 1px solid #384050;
  padding-left: 557px;
  position: relative;
}
</style>
