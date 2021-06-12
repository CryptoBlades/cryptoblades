<template>
  <ul class="weapon-grid">
    <li
      class="weapon"
      :class="{ selected: highlight !== null && weapon.id === highlight }"
      v-for="weapon in nonIgnoredWeapons"
      :key="weapon.id"
      @click="$emit('choose-weapon', weapon.id)"
    >
      <weapon-icon :weapon="weapon" />
    </li>
  </ul>
</template>

<script lang="ts">
import Vue from 'vue';
import { Accessors, PropType } from 'vue/types/options';
import { mapGetters } from 'vuex';
import { IWeapon } from '../../interfaces';

import WeaponIcon from '../WeaponIcon.vue';

interface StoreMappedGetters {
  ownWeapons: IWeapon[];
  weaponsWithIds(weaponIds: (string | number)[]): IWeapon[];
}

export default Vue.extend({
  model: {
    prop: 'highlight',
    event: 'choose-weapon'
  },
  props: {
    highlight: {
      // this forces Typescript to consider a prop a certain type
      // without us specifying a "type" property;
      // Vue's "type" property is not as flexible as we need it here
      validator(x: string | number | null) { void x; return true; },
      default: null
    },
    ignore: {
      // this forces Typescript to consider a prop a certain type
      // without us specifying a "type" property;
      // Vue's "type" property is not as flexible as we need it here
      validator(x: string | number | null) { void x; return true; },
      default: null
    },
    showGivenWeaponIds: {
      type: Boolean,
      default: false
    },
    weaponIds: {
      type: Array as PropType<string[]>,
      default() { return []; }
    }
  },

  components: {
    WeaponIcon,
  },

  computed: {
    ...(mapGetters(['ownWeapons', 'weaponsWithIds']) as Accessors<StoreMappedGetters>),

    givenWeapons(): IWeapon[] {
      return this.weaponsWithIds(this.weaponIds);
    },

    displayWeapons(): IWeapon[] {
      if(this.showGivenWeaponIds) {
        return this.givenWeapons;
      }

      return this.ownWeapons;
    },

    nonIgnoredWeapons(): IWeapon[] {
      const ignore = this.ignore;
      if(ignore === null) return this.displayWeapons;

      return this.displayWeapons.filter(Boolean).filter(x => x.id.toString() !== ignore.toString());
    }
  },
});
</script>

<style scoped>
.weapon-grid {
  list-style-type: none;
  margin: 0;
  padding: 0;
  display: grid;
  padding: 0.5em;
  grid-template-columns: repeat(auto-fit, 14em);
  gap: 0.5em;
}

.weapon {
  width: 12em;
  height: 12em;
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
