<template>
  <button @click="$emit('click')">
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
</style>
