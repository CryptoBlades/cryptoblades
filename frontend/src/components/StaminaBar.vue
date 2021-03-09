<template>
  <div class="outer">
    <h2 class="header">Stamina</h2>
    <div class="bar-wrapper">
      <div class="bar" :style="{ width: percent + '%' }"></div>
    </div>
    <div class="text-wrapper">{{ current }} / {{ max }}</div>
  </div>
</template>

<script>
export default {
  props: ["current", "max"],

  computed: {
    factor() {
      return this.current / this.max;
    },

    percent() {
      return this.factor * 100 + "";
    },
  },
};
</script>

<style>
.outer {
  padding: 0.5em;
  background: gray;
}

.header {
  margin: 0.2cm 0;
}

.bar {
  height: 1em;
  background: red;
}

.text-wrapper {
  margin-top: 0.5em;
  text-align: center;
  font-size: 1.5em;
}
</style>
