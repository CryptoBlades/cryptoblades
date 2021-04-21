<template>
  <ul class="weapon-grid">
    <li
      class="weapon"
      :class="{ selected: weapon.id === highlight }"
      v-for="weapon in displayWeapons"
      :key="weapon.id"
      @click="$emit('choose-weapon', weapon.id)"
    >
      <weapon-icon :weapon="weapon" />
    </li>
  </ul>
</template>

<script lang="ts">
import { mapGetters } from 'vuex';
import { IWeapon } from '../../interfaces';

import WeaponIcon from '../WeaponIcon.vue';

export default {
  props: ['value', 'ignore', 'highlight'],

  components: {
    WeaponIcon,
  },

  computed: {
    ...mapGetters(['ownWeapons']),

    displayWeapons(): IWeapon[] {
      if(!this.ownWeapons) return [];
      return (this.ownWeapons as unknown as IWeapon[]).filter(Boolean).filter((x: IWeapon) => x.id !== (this as any).ignore);
    }
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
  background: rgba(255, 255, 255, 0.1);
  border-radius: 5px;
  cursor: pointer;
}

.weapon img {
  max-width: 100%;
  max-height: 100%;
}

.weapon.selected {
  outline: solid currentcolor 2px;
}
</style>
