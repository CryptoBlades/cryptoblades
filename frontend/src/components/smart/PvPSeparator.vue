<template>
  <div class="separator" :class="{ dark: dark, vertical: vertical }"></div>
</template>

<script>
export default {
  props: {
    vertical: {
      type: Boolean
    },
    dark: {
      type: Boolean,
    }
  },
};
</script>

<style scoped>
.separator {
  background-color: #7f8693;
  width: 100%;
  height: 1px;
}
.vertical {
  height: 100%;
  width: 1px;
  transform: rotate(180deg);
}
.dark {
  background-color: #363636;
}
</style>