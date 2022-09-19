<template>
  <div class="loader-color-width"
    :style="'background-color:' + bgColor + ';width:'+ width"></div>
</template>

<script lang="ts">

export default {
  props: ['bgColor', 'width'],
};

</script>

<style>
@keyframes blinkDiv {
  from{
    opacity: 1;
  }
  to{
    opacity: 0.4;
  }
}
.loader-color-width{
  height: 0.7em;
  animation: blinkDiv 2s infinite;
  margin-left: 50%;
  transform: translateX(-50%);
  margin-bottom: 0.40em;
  margin-top: 0.40;
}
</style>
