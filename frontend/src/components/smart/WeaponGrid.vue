<template>
  <div>
    <div class="filters row mt-2 pl-2">
      <div class="col-sm-6 col-md-2">
        <strong>Stars</strong>
        <select class="form-control" v-model="starFilter" @change="saveFilters()">
          <option v-for="x in ['', 1, 2, 3, 4, 5]" :value="x" :key="x">{{ x || 'Any' }}</option>
        </select>
      </div>

      <div class="col-sm-6 col-md-2">
        <strong>Element</strong>
        <select class="form-control" v-model="elementFilter" @change="saveFilters()">
          <option v-for="x in ['', 'Earth', 'Fire', 'Lightning', 'Water']" :value="x" :key="x">{{ x || 'Any' }}</option>
        </select>
      </div>
    </div>

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

Vue.directive('visible', (el, bind) => {
  el.style.visibility=(bind.value) ? 'visible' : 'hidden';});

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
    },
    showLimit: {
      type: Number,
      default: 0
    }
  },

  data() {
    return {
      starFilter: '',
      elementFilter: ''
    };
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
      let items = this.displayWeapons;

      if(this.ignore) {
        items = items.filter(x => x.id.toString() !== (this.ignore || '').toString());
      }

      if(this.starFilter) {
        items = items.filter(x => x.stars === (+this.starFilter - 1));
      }

      if(this.elementFilter) {
        items = items.filter(x => x.element.includes(this.elementFilter));
      }

      if(this.showLimit > 0 && items.length > this.showLimit) {
        items = items.slice(0, this.showLimit);
      }

      return items;
    }
  },

  watch: {
    async weaponIdsToDisplay(newWeaponIds: string[]) {
      await this.fetchWeapons(newWeaponIds);
    }
  },

  methods: {
    ...(mapActions(['fetchWeapons']) as StoreMappedActions),

    saveFilters() {
      localStorage.setItem('weapon-starfilter', this.starFilter);
      localStorage.setItem('weapon-elementfilter', this.elementFilter);
      this.$emit('weapon-filters-changed');
    }
  },

  mounted() {
    this.starFilter = localStorage.getItem('weapon-starfilter') || '';
    this.elementFilter = localStorage.getItem('weapon-elementfilter') || '';
  }
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

@media (max-width: 576px) {
  .weapon-grid {
    justify-content: center;
    margin-top : 10px;
  }
}
</style>
