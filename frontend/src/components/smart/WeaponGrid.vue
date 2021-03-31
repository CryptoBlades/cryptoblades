<template>
  <div class="weapon-grid-container">
    <ul class="weapon-grid">
      <li
        class="weapon"
        :class="{ selected: weapon.id === value }"
        v-for="weapon in ownWeapons"
        :key="weapon.id"
      >
        <weapon-icon :weapon="weapon" @click="$emit('input', weapon.id)" />
      </li>
    </ul>
  </div>
</template>

<script>
import { mapGetters } from "vuex";
import WeaponIcon from "../WeaponIcon.vue";

export default {
  props: ["value"],

  components: {
    WeaponIcon,
  },

  computed: {
    ...mapGetters(["ownWeapons"]),
  },
};
</script>

<style scoped>
.weapon-grid-container {
  display: flex;
  flex-direction: column;
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
  cursor: pointer;
}

.weapon.selected {
  background: orange;
}
</style>
