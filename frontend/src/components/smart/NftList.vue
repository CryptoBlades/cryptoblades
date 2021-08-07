<template>
  <div>
    <div v-if="isShop">
      <div class="centered-text-div" v-if="(!nftIdTypes || nftIdTypes.length === 0)">
        <span>Nothing to buy at this time</span>
      </div>
      <ul class="nft-grid">
        <li class="nft"
        v-for="nft in nftIdTypes" :key="nft.nftType + nft.nftId">
          <nft-icon :nft="nft" :isShop="isShop" :favorite="isFavorite(nft.typeId, nft.nftId)"/>
          <b-button
            variant="primary"
            class="shop-button"
            @click="onShieldBuy()">
            <span class="gtag-link-others">
              Buy ({{ nft.nftPrice }} SKILL)
            </span>
          </b-button>
        </li>
      </ul>
    </div>

    <div v-if="!isShop">
      <div class="filters row mt-2">
        <div v-if="!isMarket" class="col-sm-6 col-md-4 dropdown-elem">
          <strong>Nft Type</strong>
          <select class="form-control" v-model="typeFilter" @change="saveFilters()">
            <option v-for="x in ['', 'Shield']" :value="x" :key="x">{{ x || 'Any' }}</option>
          </select>
        </div>

        <div class="col-sm-6 col-md-4 dropdown-elem">
          <strong>Stars</strong>
          <select class="form-control" v-model="starFilter" @change="saveFilters()">
            <option v-for="x in ['', 1, 2, 3, 4, 5]" :value="x" :key="x">{{ x || 'Any' }}</option>
          </select>
        </div>

        <div class="col-sm-6 col-md-4 dropdown-elem">
          <strong>Element</strong>
          <select class="form-control" v-model="elementFilter" @change="saveFilters()">
            <option v-for="x in ['', 'Earth', 'Fire', 'Lightning', 'Water']" :value="x" :key="x">{{ x || 'Any' }}</option>
          </select>
        </div>

        <div class="col-sm-6 col-md-4 dropdown-elem" v-if="isMarket">
          <strong>Sort</strong>
          <select class="form-control" v-model="priceSort" @change="saveFilters()">
            <option v-for="x in sorts" :value="x.dir" :key="x.dir">{{ x.name || 'Any' }}</option>
          </select>
        </div>

        <div v-if="showFavoriteToggle" class="show-favorite">
          <b-check class="show-favorite-checkbox" v-model="showFavoriteNfts" />
          <strong>Show Favorite</strong>
        </div>

        <b-button
          variant="primary"
          class="ml-3 clear-filters-button"
          @click="clearFilters"
        >
          <span>
            Clear Filters
          </span>
        </b-button>
      </div>
      <ul class="nft-grid">
        <li class="nft" v-for="nft in nonIgnoredNfts" :key="nft.nftType + nft.nftId"
          :class="{ selected: highlight !== null && nft.nftType + nft.nftId === highlight }"
          @click="onNftClick(nft.nftType, nft.nftId)"
          @contextmenu="canFavorite && toggleFavorite($event, nft.nftType, nft.nftId)"
        >
          <nft-icon :favorite="isFavorite(nft.nftType, nft.nftId)" :nft="nft" :isShop="isShop"/>
          <div class="above-wrapper" v-if="$slots.above || $scopedSlots.above">
            <slot name="above" :nft="nft"></slot>
          </div>
          <slot name="sold" :nft="nft"></slot>
        </li>
      </ul>
    </div>
  </div>
</template>

<script lang="ts">
import { mapActions, mapGetters, mapMutations, mapState } from 'vuex';
import Events from '../../events';
import NftIcon from '../NftIcon.vue';
import { Nft } from '@/interfaces/Nft';
import Vue from 'vue';
import { Accessors, PropType } from 'vue/types/options';
import { IState } from '@/interfaces';

const sorts = [
  { name: 'Any', dir: '' },
  { name: 'Price: Low -> High', dir: 1 },
  { name: 'Price: High -> Low', dir: -1 },
];

interface Data {
  typeFilter: string;
  starFilter: string;
  elementFilter: string;
  favorites: Record<string, Record<number, boolean>>;
  priceSort: string;
  showFavoriteNfts: boolean;
}

export interface NftIdType {
  nftId: number | string;
  nftType: string;
}

type StoreMappedState = Pick<IState, 'ownedShieldIds'>;

interface StoreMappedGetters {
  nftsWithIdType(nftIdType: NftIdType[]): Nft[];
  shieldsWithIds(ids: string[]): Nft[];
}

interface StoreMappedActions {
  purchaseShield(): Promise<void>;
}

export default Vue.extend({
  model: {
    prop: 'highlight',
    event: 'choose-nft',
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
    showGivenNftIdTypes: {
      type: Boolean,
      default: false,
    },
    nftIdTypes: {
      type: Array as PropType<NftIdType[]>,
      default() {
        return [];
      },
    },
    isShop: {
      type: Boolean,
      default: false,
    },
    isMarket: {
      type: Boolean,
      default: false,
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
    showLimit: {
      type: Number,
      default: 0,
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
  },

  data() {
    return {
      typeFilter: '',
      starFilter: '',
      elementFilter: '',
      favorites: {},
      priceSort: '',
      sorts,
      showFavoriteNfts: true,
    } as Data;
  },

  components: {
    NftIcon
  },

  computed: {
    ...(mapState(['ownedShieldIds']) as Accessors<StoreMappedState>),
    ...(mapGetters(['shieldsWithIds','nftsWithIdType']) as Accessors<StoreMappedGetters>),

    nftsToDisplay(): NftIdType[] {
      if (this.showGivenNftIdTypes) {
        return this.nftIdTypes;
      }

      const nfts: NftIdType[] = [];

      // push different kinds of nfts to nfts array here
      this.ownedShieldIds?.forEach(id => { nfts.push({ nftId: id, nftType: 'shield' }); });

      return nfts;
    },

    displayNfts(): Nft[] {
      if(this.isMarket && this.showGivenNftIdTypes) {
        const nftType = this.nftIdTypes && this.nftIdTypes[0]?.nftType;
        switch(nftType) {
        case('shield'):
          return this.shieldsWithIds(this.nftsToDisplay.map(x => x.nftId.toString())).filter(Boolean);
        default:
          return [];
        }
      }

      return this.nftsWithIdType(this.nftsToDisplay).filter(Boolean);
    },

    nonIgnoredNfts(): Nft[] {
      let items: Nft[] = [];
      this.displayNfts.forEach((x) => items.push(x));

      const allIgnore: NftIdType[] = [];
      if (!this.showFavoriteNfts) {
        for (const type in Object.keys(this.favorites)) {
          for(const id in Object.keys(this.favorites[type])) {
            allIgnore.push({ nftType: type, nftId: id });
          }
        }
      }
      items = items.filter((x) => allIgnore.findIndex((y) => y.nftId === x.nftId && y.nftType === x.nftType) < 0);

      if(this.typeFilter) {
        items = items.filter((x) => x.nftType.localeCompare(this.typeFilter, undefined, { sensitivity: 'base' } ) === 0);
      }

      if (this.starFilter) {
        items = items.filter((x) => x.stars === +this.starFilter - 1);
      }

      if (this.elementFilter) {
        items = items.filter((x) => x.element?.includes(this.elementFilter));
      }

      if (this.showLimit > 0 && items.length > this.showLimit) {
        items = items.slice(0, this.showLimit);
      }

      const favoriteNfts: Nft[] = [];
      for (const key in this.favorites) {
        const i = items.findIndex((y) => y?.nftId === +key);
        if (i !== -1) {
          favoriteNfts.push(items[i]);
          items.splice(i, 1);
        }
      }

      return favoriteNfts.concat(items);
    },
  },

  watch: {
    async nftsToDisplay(newNftsToDisplay: NftIdType[]) {
      const shieldIds: string[] = [];
      newNftsToDisplay.forEach(x => {
        switch(x.nftType) {
        case('shield'):
          shieldIds.push(x.nftId.toString());
        }
      });

      if(shieldIds.length > 0) {
        await this.fetchShields(shieldIds);
      }
    },
  },

  methods: {
    ...(mapActions(['purchaseShield']) as Accessors<StoreMappedActions>),
    ...mapActions(['fetchShields']),
    ...mapMutations(['setCurrentNft']),

    async onShieldBuy() {
      await this.purchaseShield;
    },

    saveFilters() {
      if(this.isMarket) {
        sessionStorage.setItem('market-nft-typefilter', this.typeFilter);
        sessionStorage.setItem('market-nft-starfilter', this.starFilter);
        sessionStorage.setItem('market-nft-elementfilter', this.elementFilter);
        sessionStorage.setItem('market-nft-price-order', this.priceSort);
      } else {
        sessionStorage.setItem('nft-typefilter', this.typeFilter);
        sessionStorage.setItem('nft-starfilter', this.starFilter);
        sessionStorage.setItem('nft-elementfilter', this.elementFilter);
      }
      this.$emit('nft-filters-changed');
    },

    clearFilters() {
      if(this.isMarket) {
        sessionStorage.removeItem('market-nft-typefilter');
        sessionStorage.removeItem('market-nft-starfilter');
        sessionStorage.removeItem('market-nft-elementfilter');
        sessionStorage.removeItem('market-nft-price-order');
      } else {
        sessionStorage.removeItem('nft-typefilter');
        sessionStorage.removeItem('nft-starfilter');
        sessionStorage.removeItem('nft-elementfilter');
      }

      this.typeFilter = '';
      this.starFilter = '';
      this.elementFilter = '';
      this.priceSort = '';

      this.$emit('nft-filters-changed');
    },

    toggleFavorite(e: Event, nftType: string, nftId: number) {
      e.preventDefault();
      if (this.favorites[nftType] && this.favorites[nftType][nftId]) {
        this.$delete(this.favorites[nftType], nftId);
      } else {
        if(!this.favorites[nftType]) {
          this.$set(this.favorites, nftType, {});
        }
        this.$set(this.favorites[nftType], nftId, true);
      }

      localStorage.setItem('favorite-nfts', this.getFavoritesString(this.favorites));

      Events.$emit('nft:newFavorite', { nftType, nftId });
    },

    onNftClick(type: string, id: number) {
      this.setCurrentNft({ nftType: type, nftId: id });
      this.$emit('choose-nft', type+id);
    },

    getFavoritesString(favorites: Record<string, Record<number, boolean>>): string {
      return JSON.stringify(favorites);
    },

    checkStorageFavorite() {
      const favoritesFromStorage = localStorage.getItem('favorite-nfts');
      if (favoritesFromStorage) {
        this.favorites = JSON.parse(favoritesFromStorage);
      }
    },

    isFavorite(nftType: string, nftId: number): boolean {
      return this.favorites && this.favorites[nftType] && this.favorites[nftType][nftId];
    },
  },

  mounted() {
    this.checkStorageFavorite();

    Events.$on('nft:newFavorite', () => this.checkStorageFavorite());

    if(this.isMarket) {
      this.typeFilter = sessionStorage.getItem('market-nft-typefilter') || '';
      this.starFilter = sessionStorage.getItem('market-nft-starfilter') || '';
      this.elementFilter = sessionStorage.getItem('market-nft-elementfilter') || '';
      this.priceSort = sessionStorage.getItem('market-nft-price-order') || '';
    } else {
      this.typeFilter = sessionStorage.getItem('nft-typefilter') || '';
      this.starFilter = sessionStorage.getItem('nft-starfilter') || '';
      this.elementFilter = sessionStorage.getItem('nft-elementfilter') || '';
    }
  },
});
</script>

<style>
.nft-grid {
  list-style-type: none;
  justify-content: center;
  margin: 0;
  display: grid;
  padding: 0.5em;
  grid-template-columns: repeat(auto-fit, 12em);
  gap: 0.5em;
}
.nft {
  width: 12em;
  background: rgba(255, 255, 255, 0.1);
  border-radius: 5px;
  cursor: pointer;
  position: relative;
  overflow: hidden;
}

.centered-text-div {
  text-align: center;
}

.shop-button {
  position: relative;
  width: 12rem;
}

.row.filters {
   justify-content: center;
   width: 100%;
   max-width: 900px;
   margin: 0 auto;
   align-content: center;
   border-bottom: 0.2px solid rgba(102, 80, 80, 0.1);
   margin-bottom: 20px;
}
.dropdown-elem {
  margin-bottom: 20px;
  max-width: 300px;
  width: 100%;
}

.show-favorite {
  margin-left: 15px;
  display: flex;
  flex-direction: row;
  align-self: center;
}
.show-favorite-checkbox {
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

.above-wrapper {
  padding: 0.1rem;
}

.nft.selected {
  outline: solid currentcolor 2px;
}


@media (max-width: 576px) {
  .weapon-grid {
    justify-content: center;
    margin-top: 10px;
  }

  .show-favorite {
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