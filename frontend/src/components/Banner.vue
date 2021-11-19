<template>
  <div class="banner">
    <div class="content-wrap">
      <CharacterSummary />
      <Leaderboard />
    </div>
  </div>
</template>

<script>
import CharacterSummary from '@/components/CharacterSummary';
import Leaderboard from '@/components/Leaderboard';
export default {
  name: 'Banner',
  components: {
    CharacterSummary,
    Leaderboard
  }
};
</script>

<style scoped>
.banner {
  width: 100%;
  background: url("../assets/new-ui/background/artwork-fantasy-art-ruins-game-wallpaper.png") no-repeat;
  background-size: cover;
  border-bottom: 1px solid #384050;
}
</style>
