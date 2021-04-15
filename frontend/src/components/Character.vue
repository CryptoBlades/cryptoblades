<template>
  <div class="wrapper">
    <!-- <img src="../assets/chara.png" alt="Placeholder character"> -->
    <div
      class="image"
      :style="{ backgroundImage: `url(${getCharacterArt(this.character)})` }"
    ></div>
  </div>
</template>

<script>
import { getCharacterArt } from '../character-arts-placeholder';

export default {
  props: ['character'],

  methods: {
    getCharacterArt,
  },
};
</script>

<style>
.wrapper {
  margin: 0;
  display: flex;
  justify-content: center;
  align-content: center;
  background: url("../assets/chara-bg.png") center bottom no-repeat;
  padding: 5em;
  padding-bottom: 1em;
}

.image {
  width: 100%;
  background-position: center;
  background-repeat: no-repeat;
  background-size: contain;
}
</style>
