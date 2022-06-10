<template>
    <div>
      <div>
        <h1 v-if="isLandTab">{{$t('nftList.lands')}} ({{totalNonIgnoredLandsCount}})</h1>
      </div>
      <div class="filters row mt-2" v-if="!isReward && !isBridge">
        <div v-if="!isLandTab" class="col-sm-6 col-md-4 dropdown-elem">
          <strong>{{$t('nftList.nftType')}}</strong>
          <select class="form-control" v-model="typeFilter" @change="saveFilters()">
            <option v-for="x in typesOptions" :value="x" :key="x">{{ x || $t('nftList.sorts.any') }}</option>
          </select>
        </div>

        <div v-if="!isLandTab" class="col-sm-6 col-md-4 dropdown-elem">
          <strong>{{$t('nftList.stars')}}</strong>
          <select class="form-control" v-model="starFilter" @change="saveFilters()">
            <option v-for="x in starsOptions" :value="x" :key="x">{{ x || $t('nftList.sorts.any') }}</option>
          </select>
        </div>

        <div v-if="!isLandTab" class="col-sm-6 col-md-4 dropdown-elem">
          <strong>{{$t('nftList.element')}}</strong>
          <select class="form-control" v-model="elementFilter" @change="saveFilters()">
            <option v-for="x in ['', 'Earth', 'Fire', 'Lightning', 'Water']" :value="x" :key="x">{{ x || $t('nftList.sorts.any') }}</option>
          </select>
        </div>

        <div v-if="showFavoriteToggle && !isLandTab" class="show-favorite">
          <b-check class="show-favorite-checkbox" v-model="showFavoriteNfts" />
          <strong>{{$t('nftList.showFavorite')}}</strong>
        </div>

        <div v-if="isLandTab" class="col-sm-6 col-md-4 dropdown-elem">
          <strong>{{$t('nftList.tier')}}</strong>
          <select class="form-control" v-model="tierFilter">
            <option v-for="x in ['', 1, 2, 3]" :value="x" :key="x">{{ x || $t('nftList.sorts.any') }}</option>
          </select>
        </div>

        <div v-if="isLandTab" class="col-sm-6 col-md-4 dropdown-elem">
          <strong>{{$t('nftList.chunkID')}}</strong>
          <select class="form-control" v-model="chunkIdFilter">
            <option v-for="x in ownedChunkIds" :value="x" :key="x">{{ x || $t('nftList.sorts.any') }}</option>
          </select>
        </div>

        <b-button
          variant="primary"
          class="ml-3 clear-filters-button"
          @click="clearFilters"
        >
          <span>
            {{$t('nftList.clearFilters')}}
          </span>
        </b-button>
      </div>
      <div class="centered-text-div" v-if="isReward && nftIdTypes.length === 0">
        {{$t('nftList.noDrop')}}
      </div>

      <b-pagination v-if="isLandTab" class="customPagination"
        v-visible="nonIgnoredNfts && totalNonIgnoredLandsCount > showLimit"
        align="center" v-model="currentPage"
        :total-rows="totalNonIgnoredLandsCount"
        :per-page="showLimit"
        first-number
        last-number
      ></b-pagination>

      <ul class="nft-grid">
        <li class="nft" v-for="nft in nonIgnoredNfts" :key="`${nft.type}.${nft.id}`"
          :class="{ selected: highlight !== null && `${nft.type}.${nft.id}` === highlight }"
          @click="onNftClick(nft.type, nft.id)"
          @contextmenu="canFavorite && toggleFavorite($event, nft.type, nft.id)"
        >
          <nft-options-dropdown v-if="showNftOptions" :nftType="nft.type" :nftId="+nft.id" :options="options" showTransfer class="nft-options"/>
          <nft-icon :favorite="isFavorite(nft.type, nft.id)" :nft="nft"/>
          <div class="above-wrapper" v-if="$slots.above || $scopedSlots.above">
            <slot name="above" :nft="nft"></slot>
          </div>
          <slot name="sold" :nft="nft"></slot>
        </li>
      </ul>

      <b-pagination v-if="isLandTab" class="customPagination"
        v-visible="nonIgnoredNfts && totalNonIgnoredLandsCount > showLimit"
        align="center" v-model="currentPage"
        :total-rows="totalNonIgnoredLandsCount"
        :per-page="showLimit"
        first-number
        last-number
      ></b-pagination>
    </div>
</template>

<script lang="ts">
import {mapActions, mapGetters, mapMutations, mapState} from 'vuex';
import Events from '../../events';
import NftIcon from '../NftIcon.vue';
import {Nft} from '@/interfaces/Nft';
import Vue from 'vue';
import { Accessors, PropType } from 'vue/types/options';
import { IState } from '@/interfaces';
import _ from 'lodash';
import i18n from '@/i18n';
import { NftOption } from '../NftOptionsDropdown.vue';
import NftOptionsDropdown from '../NftOptionsDropdown.vue';

interface Land {
  tier: string,
  chunkId: string,
  reseller?: string,
}

const sorts = [
  { name: i18n.t('nftList.sorts.any'), dir: '' },
  { name: i18n.t('nftList.sorts.lowToHigh'), dir: 1 },
  { name: i18n.t('nftList.sorts.highToLow'), dir: -1 },
];

interface Data {
  typeFilter: string;
  starFilter: string | number;
  elementFilter: string;
  favorites: Record<string, Record<number, boolean>>;
  priceSort: string;
  showFavoriteNfts: boolean;
  checkOwnedLandsInterval: ReturnType<typeof setInterval> | null;
  ownedLands: Land[];
  tierFilter: string;
  chunkIdFilter: string;
  currentPage: number;
  options: NftOption[];
}

export interface NftIdType {
  id: number | string;
  type: string;
  amount?: number;
}

type StoreMappedState = Pick<IState, 'ownedShieldIds' | 'ownedTrinketIds' | 'ownedJunkIds' | 'ownedKeyLootboxIds'>;

interface StoreMappedGetters {
  nftsWithIdType(nftIdType: NftIdType[]): Nft[];
  shieldsWithIds(ids: string[]): Nft[];
  trinketWithIds(ids: string[]): Nft[];
  junkWithIds(ids: string[]): Nft[];
  keyLootboxesWithIds(ids: string[]): Nft[];
  weaponsWithIds(ids: (string | number)[]): Nft[];
}

interface StoreMappedActions {
  fetchShields(shieldIds: (string | number)[]): Promise<void>;
  fetchJunks(junkIds: (string | number)[]): Promise<void>;
  fetchTrinkets(trinketIds: (string | number)[]): Promise<void>;
  fetchWeapons(weaponIds: (string | number)[]): Promise<void>;
  fetchKeyLootboxes(keyLootboxIds: (string | number)[]): Promise<void>;
  updateTrinketIds(): Promise<void>;
  updateJunkIds(): Promise<void>;
  updateKeyLootboxIds(): Promise<void>;
}

interface StoreMappedLandActions{
  fetchOwnedLands(): Promise<{ 0: string, 1: string, 2: string, 3: string, 4: string }[]>;
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
    isReward: {
      type: Boolean,
      default: false,
    },
    isBridge: {
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
    isSpecials: {
      type: Boolean,
      default: false,
    },
    isLandTab: {
      type: Boolean,
      default: false
    },
    showNftOptions: {
      type: Boolean,
      default: false
    },
    starsOptions: {
      type: Array as PropType<(string | number)[]>,
      default() {
        return ['', 1, 2, 3, 4, 5];
      },
    },
    typesOptions: {
      type: Array as PropType<string[]>,
      default() {
        return ['', 'Shield', 'Trinket', 'Junk', 'Keybox', 'Land'];
      },
    },
    chosenStarsOption: {
      type: [String, Number],
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
      checkOwnedLandsInterval: null,
      ownedLands: [],
      tierFilter: '',
      chunkIdFilter: '',
      currentPage: 1,
      options: []
    } as Data;
  },

  components: {
    NftIcon,
    NftOptionsDropdown
  },

  computed: {
    ...(mapState(['ownedShieldIds', 'ownedTrinketIds', 'ownedJunkIds', 'ownedKeyLootboxIds']) as Accessors<StoreMappedState>),
    ...(mapGetters(['shieldsWithIds', 'trinketWithIds', 'junkWithIds', 'keyLootboxesWithIds',
      'weaponsWithIds','nftsWithIdType']) as Accessors<StoreMappedGetters>),

    nftsToDisplay(): NftIdType[] {
      if (this.showGivenNftIdTypes) {
        return this.nftIdTypes;
      }

      const nfts: NftIdType[] = [];
      // push different kinds of nfts to nfts array here
      this.ownedShieldIds?.forEach(id => { nfts.push({ id, type: 'shield' }); });
      this.ownedTrinketIds?.forEach(id => { nfts.push({ id, type: 'trinket' }); });
      this.ownedJunkIds?.forEach(id => { nfts.push({ id, type: 'junk' }); });
      this.ownedKeyLootboxIds?.forEach(id => { nfts.push({ id, type: 'keybox' }); });

      return nfts;
    },

    displayNfts(): Nft[] {
      if(!this.nftsToDisplay) return [];

      if(this.isReward && this.showGivenNftIdTypes) {
        const rewardedDust = this.nftsToDisplay.filter(x => x.type?.startsWith('dust')).map(x => { return { type: x.type, id: 0, amount: x.amount }; });
        const rewardedWeapons = this.weaponsWithIds(this.nftsToDisplay.filter(x => x.type === 'weapon').map(x => x.id));
        rewardedWeapons.forEach(x => {
          if(x) {
            x.type = 'weapon';
          }
        });

        return this.nftsWithIdType(this.nftsToDisplay).concat(rewardedDust).concat(rewardedWeapons).filter(Boolean);
      }

      if(this.isLandTab) {
        return this.ownedLands.map((x, i) => { return { type: `t${x.tier}land`, id: i, tier: +x.tier, chunkId: +x.chunkId }; });
      }

      return this.nftsWithIdType(this.nftsToDisplay).filter(Boolean);
    },

    totalNonIgnoredLandsCount(): number {
      let items: Nft[] = [];
      this.displayNfts.forEach((x) => items.push(x));

      if(this.tierFilter && this.isLandTab) {
        items = items.filter((x) => x.tier === +this.tierFilter);
      }

      if(this.chunkIdFilter && this.isLandTab) {
        items = items.filter((x) => x.chunkId === +this.chunkIdFilter);
      }

      return items.length;
    },

    nonIgnoredNfts(): Nft[] {
      let items: Nft[] = [];
      this.displayNfts.forEach((x) => items.push(x));

      const allIgnore: NftIdType[] = [];
      if (!this.showFavoriteNfts) {
        for (const type in Object.keys(this.favorites)) {
          for(const id in Object.keys(this.favorites[type])) {
            allIgnore.push({ type, id });
          }
        }
      }
      items = items.filter((x) => allIgnore.findIndex((y) => y.id === x.id && y.type === x.type) < 0);

      if(this.typeFilter) {
        items = items.filter((x) => x.type?.localeCompare(this.typeFilter, undefined, { sensitivity: 'base' } ) === 0);
      }

      if (this.starFilter) {
        items = items.filter((x) => x.stars === +this.starFilter - 1);
      }

      if (this.elementFilter) {
        items = items.filter((x) => x.element?.includes(this.elementFilter));
      }

      if(this.tierFilter && this.isLandTab) {
        items = items.filter((x) => x.tier === +this.tierFilter);
      }

      if(this.chunkIdFilter && this.isLandTab) {
        items = items.filter((x) => x.chunkId === +this.chunkIdFilter);
      }

      if (this.showLimit > 0 && items.length > this.showLimit) {
        const offset = (this.currentPage-1) * this.showLimit;
        items = items.slice(offset, offset + this.showLimit);
      }

      const favoriteNfts: Nft[] = [];
      for (const key in this.favorites) {
        const i = items.findIndex((y) => y?.id === +key);
        if (i !== -1) {
          favoriteNfts.push(items[i]);
          items.splice(i, 1);
        }
      }

      return favoriteNfts.concat(items);
    },

    ownedChunkIds(): string[] {
      const uniqChunkIds = _.uniq(this.ownedLands.map(x => +x.chunkId)).sort((a, b) => a - b).map(x => x.toString());
      return [''].concat(uniqChunkIds);
    }
  },

  watch: {
    async nftsToDisplay(newNftsToDisplay: NftIdType[]) {
      const shieldIds: string[] = [];
      const trinketIds: string[] = [];
      const junkIds: string[] = [];
      const keyLootboxIds: string[] = [];
      const weaponIds: string[] = [];
      newNftsToDisplay.forEach(nft => {
        switch(nft.type) {
        case('shield'):
          shieldIds.push(nft.id.toString());
          break;
        case('trinket'):
          trinketIds.push(nft.id.toString());
          break;
        case('junk'):
          junkIds.push(nft.id.toString());
          break;
        case('keybox'):
          keyLootboxIds.push(nft.id.toString());
          break;
        case('weapon'):
          weaponIds.push(nft.id.toString());
          break;
        }
      });

      await this.fetchShields(shieldIds);
      await this.fetchJunks(junkIds);
      await this.fetchKeyLootboxes(keyLootboxIds);
      await this.fetchTrinkets(trinketIds);
      await this.fetchWeapons(weaponIds);
    },
  },

  methods: {
    ...(mapActions(['fetchShields', 'fetchJunks', 'fetchTrinkets', 'fetchWeapons', 'fetchKeyLootboxes', 'updateTrinketIds',
      'updateJunkIds', 'updateKeyLootboxIds'
    ]) as StoreMappedActions),
    ...(mapActions('land', ['fetchOwnedLands']) as StoreMappedLandActions),
    ...mapMutations(['setCurrentNft']),

    saveFilters() {
      sessionStorage.setItem('nft-typefilter', this.typeFilter);
      sessionStorage.setItem('nft-starfilter', this.starFilter.toString());
      sessionStorage.setItem('nft-elementfilter', this.elementFilter);
      this.$emit('nft-filters-changed');
    },

    clearFilters() {
      sessionStorage.removeItem('nft-typefilter');
      sessionStorage.removeItem('nft-starfilter');
      sessionStorage.removeItem('nft-elementfilter');

      this.typeFilter = this.typesOptions?.length === 1 ? this.typesOptions[0] : '';
      this.starFilter = this.starsOptions?.length === 1 ? this.starsOptions[0] : '';
      this.elementFilter = '';
      this.priceSort = '';
      this.tierFilter = '';
      this.chunkIdFilter = '';

      this.$emit('nft-filters-changed');
    },

    toggleFavorite(e: Event, type: string, id: number) {
      e.preventDefault();
      if (this.favorites[type] && this.favorites[type][id]) {
        this.$delete(this.favorites[type], id);
      } else {
        if(!this.favorites[type]) {
          this.$set(this.favorites, type, {});
        }
        this.$set(this.favorites[type], id, true);
      }

      localStorage.setItem('favorite-nfts', this.getFavoritesString(this.favorites));

      Events.$emit('nft:newFavorite', { type, id });
    },

    onNftClick(type: string, id: number) {
      this.setCurrentNft({ type, id });
      this.$emit('choose-nft', `${type}.${id}`);
      this.$emit('choosenft', { type, id });
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

    isFavorite(type: string, id: number): boolean {
      return this.favorites && this.favorites[type] && this.favorites[type][id];
    },

    async fetchNfts() {
      await this.updateTrinketIds();
      await this.updateJunkIds();
      await this.updateKeyLootboxIds();
    },

    async getOwnedLands() {
      const results = await this.fetchOwnedLands();
      if(results){
        this.ownedLands = results.map(result => ({tier: result[0], chunkId: result[1], reseller: result[4]}));
      }
    },
  },

  async mounted() {
    this.checkStorageFavorite();

    Events.$on('nft:newFavorite', () => this.checkStorageFavorite());

    if (this.chosenStarsOption !== undefined) {
      this.starFilter = this.chosenStarsOption;
    } else {
      this.typeFilter = sessionStorage.getItem('nft-typefilter') || '';
      this.starFilter = sessionStorage.getItem('nft-starfilter') || '';
      this.elementFilter = sessionStorage.getItem('nft-elementfilter') || '';
    }

    if(this.starsOptions?.length === 1) {
      this.starFilter = this.starsOptions[0];
    }

    if(this.typesOptions?.length === 1) {
      this.typeFilter = this.typesOptions[0];
    }

    if(!this.showGivenNftIdTypes) {
      await this.fetchShields(this.ownedShieldIds);
      await this.fetchNfts();
    }

    await this.getOwnedLands();
    this.checkOwnedLandsInterval = setInterval(await this.getOwnedLands, 3000);
  },

  beforeDestroy() {
    if(this.checkOwnedLandsInterval){
      clearInterval(this.checkOwnedLandsInterval);
    }
  }
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

.nft-options {
  position: absolute;
  right: 0;
  top: 0;
}

.centered-text-div {
  text-align: center;
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

.padding-bottom-100 {
  padding-bottom: 100%;
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

.fix-h24 {
  height: 24px;
}
</style>
