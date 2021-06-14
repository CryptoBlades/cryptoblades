<template>
  <ul class="weapon-grid">
    <li
      class="weapon"
      :class="{ selected: highlight !== null && weapon.id === highlight }"
      v-for="weapon in nonIgnoredWeapons"
      :key="weapon.id"
      @click="$emit('choose-weapon', weapon.id)"
    >
      <div class="above-wrapper" v-if="$slots.above || $scopedSlots.above">
        <slot name="above" :weapon="weapon"></slot>
      </div>
      <div class="weapon-icon-wrapper">
        <weapon-icon class="weapon-icon" :weapon="weapon" />
      </div>
    </li>
  </ul>
</template>

<script lang="ts">
import Vue from 'vue';
import { Accessors, PropType } from 'vue/types/options';
import { mapActions, mapGetters, mapState } from 'vuex';
import { IState, IWeapon } from '../../interfaces';

import WeaponIcon from '../WeaponIcon.vue';

type StoreMappedState = Pick<IState, 'ownedWeaponIds'>;

interface StoreMappedGetters {
  weaponsWithIds(weaponIds: (string | number)[]): IWeapon[];
}

interface StoreMappedActions {
  fetchWeapons(weaponIds: string[]): Promise<void>;
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
    ...(mapState(['ownedWeaponIds']) as Accessors<StoreMappedState>),
    ...(mapGetters(['weaponsWithIds']) as Accessors<StoreMappedGetters>),

    weaponIdsToDisplay(): string[] {
      if(this.showGivenWeaponIds) {
        return this.weaponIds;
      }

      return this.ownedWeaponIds.map(id => id.toString());
    },

    displayWeapons(): IWeapon[] {
      return this.weaponsWithIds(this.weaponIdsToDisplay).filter(Boolean);
    },

    nonIgnoredWeapons(): IWeapon[] {
      const ignore = this.ignore;
      if(ignore === null) return this.displayWeapons;

      return this.displayWeapons.filter(x => x.id.toString() !== ignore.toString());
    }
  },

  watch: {
    async weaponIdsToDisplay(newWeaponIds: string[]) {
      await this.fetchWeapons(newWeaponIds);
    }
  },

  methods: {
    ...(mapActions(['fetchWeapons']) as StoreMappedActions)
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
  background: rgba(255, 255, 255, 0.1);
  border-radius: 5px;
  cursor: pointer;
}

.weapon.selected {
  outline: solid currentcolor 2px;
}

.weapon-icon-wrapper {
  width: 12em;
  height: 12em;
}

.above-wrapper {
  padding: 0.5rem;
}
</style>
