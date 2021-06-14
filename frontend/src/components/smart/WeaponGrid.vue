<template>
  <div class="body main-font">
    <select v-model="starFilterValue">
      <option disabled selected value=null>Star Filter</option>
      <option>none</option>
      <option>1</option>
      <option>2</option>
      <option>3</option>
      <option>4</option>
      <option>5</option>
    </select>
    <select v-model="elementFilterValue">
      <option disabled selected value=null>Element Filter</option>
      <option>none</option>
      <option>Fire</option>
      <option>Earth</option>
      <option>Lightning</option>
      <option>Water</option>
    </select>
    <ul class="weapon-grid">
      <li
        class="weapon"
        :class="{ selected: highlight !== null && weapon.id === highlight }"
        v-for="weapon in combinedFilter"
        :key="weapon.id"
        @click="$emit('choose-weapon', weapon.id)"
      >
        <weapon-icon :weapon="weapon" />
      </li>
    </ul>
  </div>
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
    event: 'choose-weapon',
  },
  props: {
    highlight: {
      // this forces Typescript to consider a prop a certain type
      // without us specifying a "type" property;
      // Vue's "type" property is not as flexible as we need it here
      validator(x: string | number | null) {
        void x;
        return true;
      },
      default: null,
    },
    ignore: {
      // this forces Typescript to consider a prop a certain type
      // without us specifying a "type" property;
      // Vue's "type" property is not as flexible as we need it here
      validator(x: string | number | null) {
        void x;
        return true;
      },
      default: null,
    },
    showGivenWeaponIds: {
      type: Boolean,
      default: false,
    },
    weaponIds: {
      type: Array as PropType<string[]>,
      default() {
        return [];
      },
    },
  },

  data() {
    return {
      starFilterValue: null,
      elementFilterValue: '' || null,
    };
  },

  components: {
    WeaponIcon,
  },

  computed: {
    ...(mapState(['ownedWeaponIds']) as Accessors<StoreMappedState>),
    ...(mapGetters(['weaponsWithIds']) as Accessors<StoreMappedGetters>),

    weaponIdsToDisplay(): string[] {
      if (this.showGivenWeaponIds) {
        return this.weaponIds;
      }

      return this.ownedWeaponIds.map((id) => id.toString());
    },

    displayWeapons(): IWeapon[] {
      return this.weaponsWithIds(this.weaponIdsToDisplay).filter(Boolean);
    },

    combinedFilter(): IWeapon[] {
      const hasStars = this.starFilterValue !== 'none' && this.starFilterValue !== null;
      const hasElements = this.elementFilterValue !== 'none' && this.elementFilterValue !== null;

      if (!hasStars && !hasElements) {
        return this.displayWeapons;
      }

      if (hasStars && hasElements) {
        return this.displayWeapons.filter((item) => item.stars === this.starFilterValue! - 1 && item.element.includes(this.elementFilterValue!));
      }

      if (hasElements) return this.displayWeapons.filter((item) => item.element.includes(this.elementFilterValue!));

      return this.displayWeapons.filter((item) => item.stars === this.starFilterValue! - 1);
    },
  },

  watch: {
    async weaponIdsToDisplay(newWeaponIds: string[]) {
      await this.fetchWeapons(newWeaponIds);
    },
  },

  methods: {
    ...(mapActions(['fetchWeapons']) as StoreMappedActions),
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
