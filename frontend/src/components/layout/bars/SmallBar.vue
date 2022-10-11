<template>
  <div class="bar-section" :title="altText" v-if="!showMinimalVersion">
    <i
      class="icon fas"
      :style="{ color: primaryColor }"
      :class="{ [faIcon]: true }"
    ></i>
    <div class="bar-wrapper">
      <div
        class="bar"
        :style="{ width: percent, background: primaryColor }"
      ></div>
    </div>
    <span class="bar-text">{{ current }} / {{ max }}</span>
  </div>

  <span v-else>({{ current }} / {{ max }})</span>
</template>

<script lang="ts">
export default {
  props: ['current', 'max', 'faIcon', 'primaryColor', 'altText', 'showMinimalVersion'],

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
.bar-section {
  display: flex;
  align-items: center;
}

.bar-section > * + * {
  margin-left: 0.5rem;
}

.icon {
  font-size: 0.85rem;
  width: 1.2em;
  text-align: center;
}

.bar-wrapper {
  width: 12.5rem;
  height: 70%;
  background: rgba(0, 0, 0, 0.35);
}

.bar-wrapper .bar {
  height: 100%;
}

.bar-text {
  font-size: 0.85rem;
}
</style>
