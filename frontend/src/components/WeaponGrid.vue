<template>
  <div class="weapon-grid-container">
    <h2 class="header">Weapons</h2>
    <ul class="weapon-grid">
      <li class="weapon" v-for="weapon in weapons" :key="weapon.id">
        <weapon-icon :weapon="weapon" @click="$emit('select', weapon)" />
      </li>
    </ul>
  </div>
</template>

<script>
import WeaponIcon from "./WeaponIcon.vue";

export default {
  props: ["weapons"],

  components: {
    WeaponIcon,
  },
};
</script>

<style scoped>
.weapon-grid-container {
  display: flex;
  flex-direction: column;
}

.header {
  margin: 0.2cm 0;
}

.weapon-grid {
  list-style-type: none;
  margin: 0;
  padding: 0.5em;
  display: flex;
  flex-wrap: wrap;
  align-content: flex-start;
  background: lightgray;
}

.weapon {
  width: 2em;
  height: 2em;
  margin: 0.5em;
  background: gray;
}
</style>
