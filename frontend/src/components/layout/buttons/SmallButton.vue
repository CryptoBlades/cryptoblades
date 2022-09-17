<template>
  <button :disabled="disabled" class="button main-font dark-bg-text" @click="$emit('click')">
    {{ text }}
  </button>
</template>

<script lang="ts">
export default {
  props: ['text', 'disabled'],
};
</script>

<style>
.button {
  border: 2px solid #6c5f38;
  border-radius: 0.1em;
  background: rgb(31, 31, 34);
  background: linear-gradient(180deg, rgba(31, 31, 34, 1) 0%, rgba(24, 27, 30, 1) 5%, rgba(24, 38, 45, 1) 100%);

}

.button:hover:not(:disabled) {
  background-color: rgba(255, 255, 255, 0.1);
  border-color: currentColor;
  cursor: pointer;
}

.button:disabled {
  opacity: 0.4 !important;
}

</style>
