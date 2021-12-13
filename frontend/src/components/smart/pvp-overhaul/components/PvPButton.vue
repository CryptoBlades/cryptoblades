<template>
  <button @click="$emit('click')" :disabled="disabled" :class="{'disabled': disabled, 'secondary': this.secondary}">
    <span class="text" :class="secondary && 'whiteText'">{{ buttonText }}</span
    ><span class="subtext" :class="secondary && 'whiteText'">{{
      buttonsubText
    }}</span>
  </button>
</template>

<script>
export default {
  props: {
    secondary: {
      type: Boolean,
      default: false,
    },
    disabled: {
      type: Boolean,
      default: false,
    },
    buttonText: String,
    buttonsubText: String,
  },
};
</script>

<style scoped lang="scss">
// @font-face {
//   font-family: 'Trajan';
//   src: url('../../../../assets/fonts/Trajan.ttf') format('truetype');
// }
button {
  display: flex;
  flex-direction: column;
  padding: 1.5rem 2rem;
  align-items: center;
  vertical-align: middle;
  background-image: url('../../../../assets/buttonOutline.svg');
  background-repeat: no-repeat;
  background-size: contain;
  background-color: transparent;
  border: none;
  &.secondary {
    background-color:#141414;
    border: 1px solid #edcd90;
    border-radius: 5px;
    padding: 0.75rem;
    background-image: none;
  }
  .text {
    font-size: 1rem;
    font-weight: 600;
    color: #dabe75;
    font-family: 'Trajan';
    &.whiteText {
      font-size: 1rem;
      font-weight: 400;
      font-family: 'Roboto';
      color: white;
    }
  }
  .subtext {
    font-size: 0.875rem;
    line-height: 1.25rem;
    color: #b4b0a7;
    &.whiteText {
      color: white;
    }
  }
}
.disabled {
  pointer-events: none;
  opacity: 50%;
  border: 1px solid #ffffff50;
}
</style>