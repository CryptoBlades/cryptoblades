<template>
  <div
    class="weapon-icon"
    :style="{ backgroundImage: `url(${getWeaponArt(weapon)})` }"
    :title="JSON.stringify(weapon, null, '  ')"
  ></div>
</template>

<script>
import { getWeaponArt } from "../weapon-arts-placeholder";

export default {
  props: ["weapon"],

  methods: {
    getWeaponArt,
  },
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
