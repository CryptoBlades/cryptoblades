<template>
  <div class="outer">
    <div class="bar-wrapper">
      <div class="bar" :style="{ width: percent }"></div>
    </div>
    <div class="text-wrapper">{{ current }} / {{ max }}</div>
  </div>
</template>

<script lang="ts">
export default {
  props: ['current', 'max'],

  computed: {
    factor(): number {
      return Math.min(1, ((this as any).current) / ((this as any).max));
    },

    percent(): string {
      return (this.factor as unknown as number * 100) + '%';
    },
  },
};
</script>

<style scoped>
.outer {
  padding: 0.5em;
  background: gray;
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
