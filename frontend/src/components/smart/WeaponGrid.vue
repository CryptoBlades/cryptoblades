<template>
  <div>
    <div class="filters row mt-2" v-if="!newWeapon">
      <div class="col-sm-6 col-md-4 stars-elem">
        <strong>Stars</strong>
        <select class="form-control" v-model="starFilter" @change="saveFilters()">
          <option v-for="x in ['', 1, 2, 3, 4, 5]" :value="x" :key="x">{{ x || 'Any' }}</option>
        </select>
      </div>

      <div class="col-sm-6 col-md-4 stars-elem">
        <strong>Element</strong>
        <select class="form-control" v-model="elementFilter" @change="saveFilters()">
          <option v-for="x in ['', 'Earth', 'Fire', 'Lightning', 'Water']" :value="x" :key="x">{{ x || 'Any' }}</option>
        </select>
      </div>

      <div class="col-sm-6 col-md-4 stars-elem" v-if="isMarket">
        <strong>Sort</strong>
        <select class="form-control" v-model="priceSort" @change="saveFilters()">
          <option v-for="x in sorts" :value="x.dir" :key="x.dir">{{ x.name || 'Any' }}</option>
        </select>
      </div>

      <div v-if="showReforgedToggle" class="show-reforged">
        <b-check class="show-reforged-checkbox" v-model="showReforgedWeapons" />
        <strong>Show reforged</strong>
      </div>

      <div v-if="showFavoriteToggle" class="show-reforged show-favorite">
        <b-check class="show-reforged-checkbox" v-model="showFavoriteWeapons" />
        <strong>Show Favorite</strong>
      </div>

      <b-button
        v-if="!newWeapon"
        variant="primary"
        class="ml-3 clear-filters-button"
        :class="{ 'mb-4': showReforgedToggle && showFavoriteToggle }"
        @click="clearFilters"
      >
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
        @click=
        "(!checkForDurability || getWeaponDurability(weapon.id) > 0) && onWeaponClick(weapon.id)"
        @contextmenu="canFavorite && toggleFavorite($event, weapon.id)"
      >
        <div class="weapon-icon-wrapper">
          <weapon-icon class="weapon-icon" :weapon="weapon" :favorite="isFavorite(weapon.id)" />
        </div>
        <div class="above-wrapper" v-if="$slots.above || $scopedSlots.above">
          <slot name="above" :weapon="weapon"></slot>
        </div>
        <slot name="sold" :weapon="weapon"></slot>
      </li>
    </ul>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import Events from '../../events';
import { Accessors, PropType } from 'vue/types/options';
import { mapActions, mapGetters, mapMutations, mapState } from 'vuex';
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
  favorites: Record<number, boolean>;
  priceSort: string;
  showReforgedWeapons: boolean;
  showFavoriteWeapons: boolean;
}

const sorts = [
  { name: 'Any', dir: '' },
  { name: 'Price: Low -> High', dir: 1 },
  { name: 'Price: High -> Low', dir: -1 },
];

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
    showReforgedWeaponsDefVal: {
      type: Boolean,
      default: true,
    },
    showFavoriteToggle: {
      type: Boolean,
      default: true,
    },
    showFavoriteWeaponsDefVal: {
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
    },
    checkForDurability: {
      type: Boolean,
      default: false,
    },
    newWeapon: {
      type: Boolean,
      default: false,
    },
  },

  data() {
    return {
      starFilter: '',
      elementFilter: '',
      favorites: {},
      priceSort: '',
      sorts,
      showReforgedWeapons: this.showReforgedWeaponsDefVal,
      showFavoriteWeapons: this.showFavoriteWeaponsDefVal,
    } as Data;
  },

  components: {
    WeaponIcon
  },

  computed: {
    ...(mapState(['ownedWeaponIds']) as Accessors<StoreMappedState>),
    ...(mapGetters(['weaponsWithIds','getWeaponDurability',]) as Accessors<StoreMappedGetters>),

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

      const allIgnore: string[] = [];
      if (this.ignore) {
        allIgnore.push((this.ignore || '').toString());
      }
      if (!this.showFavoriteWeapons) {
        for (const key in this.favorites) {
          allIgnore.push(key);
        }
      }
      items = items.filter((x) => allIgnore.findIndex((y) => y === x.id.toString()) < 0);


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
  },

  watch: {
    async weaponIdsToDisplay(newWeaponIds: string[]) {
      await this.fetchWeapons(newWeaponIds);
    },
  },

  methods: {
    ...(mapActions(['fetchWeapons']) as StoreMappedActions),
    ...(mapMutations(['setCurrentWeapon'])),

    saveFilters() {
      if(this.isMarket) {
        sessionStorage.setItem('market-weapon-starfilter', this.starFilter);
        sessionStorage.setItem('market-weapon-elementfilter', this.elementFilter);
        sessionStorage.setItem('market-weapon-price-order', this.priceSort);
      } else {
        sessionStorage.setItem('weapon-starfilter', this.starFilter);
        sessionStorage.setItem('weapon-elementfilter', this.elementFilter);
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

      Events.$emit('weapon:newFavorite', { value: weaponId });
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
      if(this.isMarket) {
        sessionStorage.removeItem('market-weapon-starfilter');
        sessionStorage.removeItem('market-weapon-elementfilter');
        sessionStorage.removeItem('market-weapon-price-order');
      } else {
        sessionStorage.removeItem('weapon-starfilter');
        sessionStorage.removeItem('weapon-elementfilter');
      }
      this.elementFilter = '';
      this.starFilter = '';
      this.priceSort = '';

      this.$emit('weapon-filters-changed');
    },

    onWeaponClick(id: number) {
      this.setCurrentWeapon(id);
      this.$emit('choose-weapon', id);
    },

    checkStorageFavorite() {
      const favoritesFromStorage = localStorage.getItem('favorites');
      if (favoritesFromStorage) {
        this.favorites = JSON.parse(favoritesFromStorage);
      }
    }
  },

  mounted() {

    this.checkStorageFavorite();

    Events.$on('weapon:newFavorite', () => this.checkStorageFavorite());

    if(this.isMarket) {
      this.starFilter = sessionStorage.getItem('market-weapon-starfilter') || '';
      this.elementFilter = sessionStorage.getItem('market-weapon-elementfilter') || '';
      this.priceSort = sessionStorage.getItem('market-weapon-price-order') || '';
    } else {
      this.starFilter = sessionStorage.getItem('weapon-starfilter') || '';
      this.elementFilter = sessionStorage.getItem('weapon-elementfilter') || '';
    }
  },
});
</script>

<style scoped>
.stars-elem {
  margin-bottom: 20px;
  max-width: 300px;
  width: 100%;
}
.filters {
   justify-content: center;
   width: 100%;
   max-width: 900px;
   margin: 0 auto;
   align-content: center;
   border-bottom: 0.2px solid rgba(102, 80, 80, 0.1);
   margin-bottom: 20px;
}
.weapon-grid {
  list-style-type: none;
  justify-content: center;
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
  overflow: hidden;
}

.weapon.selected {
  outline: solid currentcolor 2px;
}

.weapon-icon-wrapper {
  width: 12em;
  height: 12em;
}

.above-wrapper {
  padding: 0.1rem;
}

.toggle-button {
  align-self: stretch;
}

.show-reforged {
  display: flex;
  flex-direction: row;
  align-self: center;
}

.show-favorite {
    margin-left: 15px;
  }

.show-reforged-checkbox {
  margin-left: 5px;
}

.clear-filters-button {
  align-self: flex-end;
  height: fit-content;
}

.clear-filters-button {
  display: flex;
  flex-direction: row;
  align-self: center;
}

@media (max-width: 576px) {
  .weapon-grid {
    justify-content: center;
    margin-top: 10px;
  }

  .show-reforged {
    width: 100%;
    justify-content: center;
    margin-bottom: 15px;
  }

  .clear-filters-button {
    width: 100%;
    display: flex;
    flex-direction: row;
    align-self: center;
    text-align: center;
    justify-content: center;
    margin: 0 auto;
  }

  .ml-3 {
    margin-left: 0 !important;
  }
}

/* Needed to adjust weapon list */
@media all and (max-width: 767.98px) {
  .weapon-grid {
    padding-left: 2em;
    justify-content: center;
  }
  .stars-elem {
  margin-bottom: 20px;
  max-width: 500px;
  width: 100%;
}
  li.weapon {
    display: inline-block;
    margin: auto;
  }
}

.sold {
    height: 40px;
    width: 230px;
    background-color: rgb(187, 33, 0);
    transform: rotate(15deg);
    left: -20px;
    position: absolute;
    top: 110px;
    z-index: 100;
}

.sold span {
    text-align: center;
    width: auto;
    color: white;
    display: block;
    font-size: 30px;
    font-weight: bold;
    line-height: 40px;
    text-shadow: 0 0 5px #333, 0 0 10px #333, 0 0 15px #333, 0 0 10px #333;
    text-transform: uppercase;
}

.fix-h24 {
  height: 24px;
}
</style>
