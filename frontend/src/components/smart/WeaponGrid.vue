<template>
  <div>
    <span v-if="showLimit > 0 && nonIgnoredWeapons.length >= showLimit">
      <h4>More than {{ showLimit }} results, try adjusting the filters</h4>
    </span>
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

      <div class="col-2" v-if="isMarket">
        <strong>Sort</strong>
        <select class="form-control" v-model="priceSort" @change="saveFilters()">
          <option v-for="x in ['', 'Price: Low -> High', 'Price: High -> Low']" :value="x" :key="x">{{ x || 'Any' }}</option>
        </select>
      </div>

      <div v-if="showReforgedToggle" class="show-reforged">
        <b-check class="show-reforged-checkbox" v-model="showReforgedWeapons" />
        <strong>Show reforged</strong>
      </div>
       <b-button variant="primary" class="ml-3 clear-filters-button" @click="clearFilters" >
          <span>
            Clear Filters
          </span>
        </b-button>
    </div>

    <ul class="weapon-grid">
      <li
        class="weapon"
        :class="{ selected: highlight !== null && weapon.id === highlight }"
        v-for="weapon in nonIgnoredWeapons"
        :key="weapon.id"
        @click="$emit('choose-weapon', weapon.id)"
        @contextmenu="canFavorite && toggleFavorite($event, weapon.id)"
      >
        <b-icon v-if="isFavorite(weapon.id) === true" class="favorite-star" icon="star-fill" variant="warning" />
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

interface Data {
  starFilter: string;
  elementFilter: string;
  showReforgedWeapons: boolean;
  favorites: Record<number, boolean>;
  priceSort: string;
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
    showLimit: {
      type: Number,
      default: 0,
    },
    showReforgedToggle: {
      type: Boolean,
      default: true,
    },
    canFavorite: {
      type: Boolean,
      default: true,
    },
    isMarket: {
      type: Boolean,
      default: false
    }
  },

  data() {
    return {
      starFilter: '',
      elementFilter: '',
      showReforgedWeapons: true,
      favorites: {},
      priceSort: '',
    } as Data;
  },

  components: {
    WeaponIcon
  },

  computed: {
    ...(mapState(['ownedWeaponIds']) as Accessors<StoreMappedState>),
    ...(mapGetters(['weaponsWithIds']) as Accessors<StoreMappedGetters>),

    weaponIdsToDisplay(): string[] {
      if (this.showGivenWeaponIds) {
        return this.weaponIds;
      }

      return this.ownedWeaponIds?.map((id) => id.toString());
    },

    displayWeapons(): IWeapon[] {
      return this.weaponsWithIds(this.weaponIdsToDisplay).filter(Boolean);
    },

    nonIgnoredWeapons(): IWeapon[] {
      let items: IWeapon[] = [];
      this.displayWeapons.forEach((x) => items.push(x));

      if (this.ignore) {
        items = items.filter((x) => x.id.toString() !== (this.ignore || '').toString());
      }

      if (this.starFilter) {
        items = items.filter((x) => x.stars === +this.starFilter - 1);
      }

      if (this.elementFilter) {
        items = items.filter((x) => x.element.includes(this.elementFilter));
      }

      if (!this.showReforgedWeapons) {
        items = items.filter((x) => x.bonusPower === 0);
      }

      if (this.showLimit > 0 && items.length > this.showLimit) {
        items = items.slice(0, this.showLimit);
      }

      const favoriteWeapons: IWeapon[] = [];
      for (const key in this.favorites) {
        const i = items.findIndex((y) => y.id === +key);
        if (i !== -1) {
          favoriteWeapons.push(items[i]);
          items.splice(i, 1);
        }
      }

      return favoriteWeapons.concat(items);
    },

    priceSortAscText() {
      return 'Price: Low -> High';
    },

    priceSortDescText() {
      return 'Price: High -> Low';
    }
  },

  watch: {
    async weaponIdsToDisplay(newWeaponIds: string[]) {
      await this.fetchWeapons(newWeaponIds);
    },
  },

  methods: {
    ...(mapActions(['fetchWeapons']) as StoreMappedActions),

    saveFilters() {
      sessionStorage.setItem('weapon-starfilter', this.starFilter);
      sessionStorage.setItem('weapon-elementfilter', this.elementFilter);

      if(this.isMarket) {
        const sortOrder = this.priceSort === this.priceSortAscText ? '1' :
          this.priceSort === this.priceSortDescText ? '-1' : '';
        sessionStorage.setItem('weapon-price-order', sortOrder);
      }
      this.$emit('weapon-filters-changed');
    },

    toggleFavorite(e: Event, weaponId: number) {
      e.preventDefault();
      if (this.favorites[weaponId]) {
        this.$delete(this.favorites, weaponId);
      } else {
        this.$set(this.favorites, weaponId, true);
      }

      localStorage.setItem('favorites', this.getFavoritesString(this.favorites));
    },

    getFavoritesString(favorites: Record<number, boolean>): string {
      return JSON.stringify(favorites);
    },

    getFavoritesMap(favorites: string): Record<number, boolean> {
      if (!favorites) {
        return {};
      }

      const favoritesMap: Record<number, boolean> = {};
      favorites.split(',').forEach((x) => (favoritesMap[+x] = true));
      return favoritesMap;
    },

    isFavorite(weaponId: number): boolean {
      return this.favorites[weaponId];
    },

    clearFilters() {
      sessionStorage.clear();

      this.elementFilter = '';
      this.starFilter = '';
      this.priceSort = '';

      this.$emit('weapon-filters-changed');
    },
  },

  mounted() {
    this.starFilter = sessionStorage.getItem('weapon-starfilter') || '';
    this.elementFilter = sessionStorage.getItem('weapon-elementfilter') || '';
    if(this.isMarket) {
      this.priceSort = sessionStorage.getItem('weapon-price-order') || '';
    }

    const favoritesFromStorage = localStorage.getItem('favorites');
    if (favoritesFromStorage) {
      this.favorites = JSON.parse(favoritesFromStorage);
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
  background: rgba(255, 255, 255, 0.1);
  border-radius: 5px;
  cursor: pointer;
  position: relative;
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

.toggle-button {
  align-self: stretch;
}

.show-reforged {
  display: flex;
  flex-direction: row;
  align-self: center;
}

.show-reforged-checkbox {
  margin-left: 5px;
}

.clear-filters-button {
  align-self: flex-end;
  height: fit-content;
}

.favorite-star {
  position: absolute;
  bottom: 5px;
  right: 5px;
}

@media (max-width: 576px) {
  .weapon-grid {
    justify-content: center;
    margin-top: 10px;
  }
}

/* Needed to adjust weapon list */
@media all and (max-width: 767.98px) {
  .weapon-grid {
    padding-left: 2em;
  }

  li.weapon {
    display: inline-block;
    margin: auto;
  }
}
</style>
