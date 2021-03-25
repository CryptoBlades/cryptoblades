<template>
  <div
    class="weapon-icon"
    :title="JSON.stringify(weapon, null, '  ')"
    @click="$emit('click', weapon)"
  ></div>
</template>

<script>
export default {
  props: ["weapon"],
};
</script>

<style scoped>
.weapon-icon {
  width: 100%;
  height: 100%;
  background-image: url("../assets/sword-placeholder.png");
  background-size: cover;
}
</style>
