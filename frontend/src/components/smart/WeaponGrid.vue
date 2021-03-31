<template>
  <ul class="weapon-grid">
    <li
      class="weapon"
      :class="{ selected: weapon.id === value }"
      v-for="weapon in ownWeapons"
      :key="weapon.id"
      :title="JSON.stringify(weapon, null, '  ')"
      @click="$emit('input', weapon.id)"
    >
      <img src="../../assets/sword-placeholder.png" alt="Placeholder weapon" />
    </li>
  </ul>
</template>

<script>
import { mapGetters } from "vuex";

export default {
  props: ["value"],

  computed: {
    ...mapGetters(["ownWeapons"]),
  },
};
</script>

<style scoped>
.weapon-grid {
  list-style-type: none;
  margin: 0;
  padding: 0;
  display: grid;
  padding: 0.5em;
  grid-template-columns: repeat(auto-fit, 7em);
  gap: 0.5em;
}

.weapon {
  width: 6em;
  height: 6em;
  background: white;
  box-shadow: 0 2px 4px gray;
  border-radius: 5px;
  padding: 0.5em;
  cursor: pointer;
}

.weapon img {
  width: 100%;
  height: 100%;
}

.weapon.selected {
  background: orange;
}
</style>
