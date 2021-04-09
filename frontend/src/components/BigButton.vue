<template>
  <button class="button main-font dark-bg-text" @click="$emit('click')">
    <h1>{{ mainText }}</h1>
    <h2>{{ subText }}</h2>
  </button>
</template>

<script>
export default {
  props: ["mainText", "subText"],
};
</script>

<style>
.button {
  background-image: url("../assets/title-bar-bg-better-tiling.png");
  background-color: rgba(255, 255, 255, 0);
  background-blend-mode: lighten;
  border: rgba(0, 0, 0, 0.2) outset 4px;
  border-radius: 0.1em;
}

.button:hover:not(:disabled) {
  background-color: rgba(255, 255, 255, 0.1);
  border-color: currentColor;
  cursor: pointer;
}

.button:disabled {
  opacity: 40%;
}
</style>
