<template>
  <span class="hint" v-tooltip="tooltipHtml">
    <i class="far fa-question-circle hint" />
  </span>
</template>

<script>
export default {
  props: ['text'],
  computed: {
    tooltipHtml() {
      return this.text;
    }
  },
};
</script>

<style>
.hint {
  font-size: 0.85em;
}
</style>
