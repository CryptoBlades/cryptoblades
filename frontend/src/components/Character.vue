<template>
  <div class="wrapper">
    <!-- <img src="../assets/chara.png" alt="Placeholder character"> -->
    <!-- :style="{ backgroundImage: `url(${getCharacterArt(this.character)})` }" -->
    <div
      class="image"
    >
      <h1>3D Plaza scene coming soon</h1>
    </div>
  </div>
</template>

<script lang="ts">
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
  background: url("../assets/chara-bg.png") center center no-repeat;
  padding: 5em;
  padding-bottom: 1em;
}

.image {
  width: 100%;
  background-position: center;
  background-repeat: no-repeat;
  background-size: contain;
  text-align: center;
  text-shadow: 0 0 5px #333, 0 0 10px #333, 0 0 15px #333, 0 0 10px #333;
  color: #fff;
}
</style>
