<template>
  <div>
    <div v-if="isShop">
      <div class="centered-text-div" v-if="(!nftIdTypes || nftIdTypes.length === 0)">
        <span>Nothing to buy at this time</span>
      </div>
      <ul class="nft-grid">
        <li class="nft"
        v-for="nft in nftIdTypes" :key="`${nft.type}.${nft.id}`">
          <nft-icon :nft="nft" :isShop="isShop" :favorite="isFavorite(nft.typeId, nft.id)"
            v-tooltip.top="{ content: itemDescriptionHtml(nft) , trigger: (isMobile() ? 'click' : 'hover') }"
                      @mouseover="hover = !isMobile() || true"
                      @mouseleave="hover = !isMobile()" />
          <b-button
            variant="primary"
            class="shop-button"
            @click="buyItem(nft)">
            <span class="gtag-link-others">
              Buy ({{ nft.nftPrice }} SKILL)
            </span>
          </b-button>
        </li>
      </ul>
    </div>

    <div v-if="!isShop">
      <div class="filters row mt-2" v-if="!isReward">
        <div v-if="!isMarket" class="col-sm-6 col-md-4 dropdown-elem">
          <strong>Nft Type</strong>
          <select class="form-control" v-model="typeFilter" @change="saveFilters()">
            <option v-for="x in ['', 'Shield', 'Trinket', 'Junk', 'Keybox']" :value="x" :key="x">{{ x || 'Any' }}</option>
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
      <div class="centered-text-div" v-if="isReward && nftIdTypes.length === 0">
        Nothing dropped for you this time.
      </div>
      <ul class="nft-grid">
        <li class="nft" v-for="nft in nonIgnoredNfts" :key="`${nft.type}.${nft.id}`"
          :class="{ selected: highlight !== null && `${nft.type}.${nft.id}` === highlight }"
          @click="onNftClick(nft.type, nft.id)"
          @contextmenu="canFavorite && toggleFavorite($event, nft.type, nft.id)"
        >
          <nft-icon :favorite="isFavorite(nft.type, nft.id)" :nft="nft" :isShop="isShop"/>
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
import {Nft as nftItem} from '../../interfaces/Nft';
import { SkillShopListing } from '../../interfaces/SkillShopListing';
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
  purchaseShield(): Promise<void>;
  fetchShields(shieldIds: (string | number)[]): Promise<void>;
  fetchJunks(junkIds: (string | number)[]): Promise<void>;
  fetchTrinkets(trinketIds: (string | number)[]): Promise<void>;
  fetchWeapons(weaponIds: (string | number)[]): Promise<void>;
  fetchKeyLootboxes(keyLootboxIds: (string | number)[]): Promise<void>;
  updateTrinketIds(): Promise<void>;
  updateJunkIds(): Promise<void>;
  updateKeyLootboxIds(): Promise<void>;
  purchaseRenameTag(): Promise<void>;
  purchaseRenameTagDeal(): Promise<void>;
  purchaseWeaponRenameTag(): Promise<void>;
  purchaseWeaponRenameTagDeal(): Promise<void>;
  purchaseCharacterFireTraitChange(): Promise<void>;
  purchaseCharacterEarthTraitChange(): Promise<void>;
  purchaseCharacterWaterTraitChange(): Promise<void>;
  purchaseCharacterLightningTraitChange(): Promise<void>;
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
    isReward: {
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

      if(this.isMarket && this.showGivenNftIdTypes) {
        const type = this.nftIdTypes && this.nftIdTypes[0]?.type;
        switch(type) {
        case('shield'):
          return this.shieldsWithIds(this.nftsToDisplay.map(x => x.id.toString())).filter(Boolean);
        default:
          return [];
        }
      }

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

      return this.nftsWithIdType(this.nftsToDisplay).filter(Boolean);
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

      if (this.showLimit > 0 && items.length > this.showLimit) {
        items = items.slice(0, this.showLimit);
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
    ...(mapActions(['purchaseShield', 'fetchShields', 'fetchJunks', 'fetchTrinkets', 'fetchWeapons', 'fetchKeyLootboxes', 'updateTrinketIds',
      'updateJunkIds', 'updateKeyLootboxIds', 'purchaseRenameTag', 'purchaseWeaponRenameTag',
      'purchaseRenameTagDeal', 'purchaseWeaponRenameTagDeal',
      'purchaseCharacterFireTraitChange', 'purchaseCharacterEarthTraitChange',
      'purchaseCharacterWaterTraitChange', 'purchaseCharacterLightningTraitChange'
    ]) as StoreMappedActions),
    ...mapMutations(['setCurrentNft']),

    async onShieldBuy() {
      await this.purchaseShield();
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

    async buyItem(item: nftItem) {
      if(item.type === 'shield'){
        await this.purchaseShield();
      }

      if(item.type === 'CharacterRenameTag'){
        await this.purchaseRenameTag();
      }
      if(item.type === 'CharacterRenameTagDeal'){
        await this.purchaseRenameTagDeal();
      }

      if(item.type === 'WeaponRenameTag'){
        await this.purchaseWeaponRenameTag();
      }
      if(item.type === 'WeaponRenameTagDeal'){
        await this.purchaseWeaponRenameTagDeal();
      }

      if(item.type === 'CharacterFireTraitChange'){
        await this.purchaseCharacterFireTraitChange();
      }
      if(item.type === 'CharacterEarthTraitChange'){
        await this.purchaseCharacterEarthTraitChange();
      }
      if(item.type === 'CharacterWaterTraitChange'){
        await this.purchaseCharacterWaterTraitChange();
      }
      if(item.type === 'CharacterLightningTraitChange'){
        await this.purchaseCharacterLightningTraitChange();
      }
    },
    itemDescriptionHtml(item: SkillShopListing): string {
      return item.name + '<br>' + item.description;
    }
  },

  async mounted() {
    this.checkStorageFavorite();

    if(!this.showGivenNftIdTypes) {
      await this.fetchShields(this.ownedShieldIds);
      await this.updateTrinketIds();
      await this.updateJunkIds();
      await this.updateKeyLootboxIds();
    }

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
