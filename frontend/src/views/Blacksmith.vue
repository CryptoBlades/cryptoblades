<template>
  <div class="body">
    <h1>Blacksmith</h1>

    <weapon-grid :weapons="weapons" />

    <div class="button-row">
      <big-button class="button" mainText="Forge sword" subText="(1 loot)" />
      <big-button
        class="button"
        mainText="Reforge sword"
        subText="(+weapon xp sacrificing another)"
      />
    </div>
  </div>
</template>

<script>
import WeaponGrid from "../components/WeaponGrid.vue";
import BigButton from "../components/BigButton.vue";

export default {
  props: ["weapons"],

  components: {
    WeaponGrid,
    BigButton,
  },
};
</script>

<style scoped>
.button-row {
  margin-top: 1em;
  display: flex;
}

.button + .button {
  margin-left: 1em;
}
</style>
