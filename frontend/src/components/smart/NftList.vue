<template>
  <div>
    <div v-if="isShop">
      <div class="centered-text-div" v-if="(!nftIdTypes || nftIdTypes.length === 0)">
        <span>{{$t('nftList.nothing')}}</span>
      </div>
      <div class="centered-text-div" v-if="isSpecials && !canPurchaseLand && purchase">
        <span>{{$t('nftList.onlyOne')}}</span><br/>
        <span>{{$t('nftList.tier')}}: {{purchase.tier}}</span><br/>
        <span v-if="purchase.tier !== '1'">{{$t('nftList.chunkID')}}: {{purchase.chunkId}}</span>
      </div>
      <div class="centered-text-div" v-if="isSpecials">
        <b-button
          variant="primary"
          class="shop-button"
          @click="showMapModal()">
            <span class="gtag-link-others">
              {{$t('nftList.showMap')}}
            </span>
        </b-button>
      </div>
      <div class="centered-text-div mt-2" v-if="isSpecials && landSaleAllowed && canPurchaseLand">
        <h4>{{$t('nftList.currencyToBuy')}}</h4>
        <b-form-select v-model="selectedCurrency" @change="onCurrencyChange()" class="mb-2">
          <b-form-select-option :value="null" disabled>{{$t('nftList.select')}}</b-form-select-option>
          <b-form-select-option :value="0">SKILL</b-form-select-option>
          <b-form-select-option :value="1">KING</b-form-select-option>
        </b-form-select>
      </div>
      <ul class="nft-grid">
        <li class="nft"
            v-for="nft in nftIdTypes" :key="`${nft.type}.${nft.id}`"
            :style="(nft.type === 'claimT2Land' && !userHasReservationsForTier(2)) ||
                (nft.type === 'claimT3Land' && !userHasReservationsForTier(3)) ? 'display: none' : null">
          <nft-icon :nft="nft" :isShop="isShop" :favorite="isFavorite(nft.typeId, nft.id)"
            v-tooltip.top="{ content: itemDescriptionHtml(nft) , trigger: (isMobile() ? 'click' : 'hover') }"
                      @mouseover="hover = !isMobile() || true"
                      @mouseleave="hover = !isMobile()" />
          <b-button
            :disabled="buyButtonDisabled(nft.type)"
            variant="primary"
            class="shop-button"
            @click="buyItem(nft)">
            <span class="gtag-link-others" v-if="nft.type !== 't1land' && nft.type !== 't2land' && nft.type !== 't3land'
              && nft.type !== 'claimT2Land' && nft.type !== 'claimT3Land'">
              {{$t('nftList.buy')}} ({{ nft.nftPrice }} SKILL)
            </span>
            <span class="gtag-link-others" v-else-if="nft.type === 't1land'"
                  v-tooltip.top="{ content: maxPrecisionSkill(t1LandPrice) , trigger: (isMobile() ? 'click' : 'hover') }"
                  @mouseover="hover = !isMobile() || true"
                  @mouseleave="hover = !isMobile()">
              {{$t('nftList.buy')}} (<CurrencyConverter :king="convertFromWeiEther(t1LandPrice)" :skill="convertFromWeiEther(t1LandPrice)"
                                      :show-value-in-skill-only="selectedCurrency === 0"
                                      :show-value-in-king-only="selectedCurrency === 1"
                                      :max-decimals="2"/>)
            </span>
            <span class="gtag-link-others" v-else-if="nft.type === 't2land'"
                  v-tooltip.top="{ content: maxPrecisionSkill(t2LandPrice) , trigger: (isMobile() ? 'click' : 'hover') }"
                  @mouseover="hover = !isMobile() || true"
                  @mouseleave="hover = !isMobile()">
              {{$t('nftList.buy')}} (<CurrencyConverter :king="convertFromWeiEther(t2LandPrice)" :skill="convertFromWeiEther(t2LandPrice)"
                                      :show-value-in-skill-only="selectedCurrency === 0"
                                      :show-value-in-king-only="selectedCurrency === 1"
                                      :max-decimals="2"/>)
            </span>
            <span class="gtag-link-others" v-else-if="nft.type === 't3land'"
                  v-tooltip.top="{ content: maxPrecisionSkill(t3LandPrice) , trigger: (isMobile() ? 'click' : 'hover') }"
                  @mouseover="hover = !isMobile() || true"
                  @mouseleave="hover = !isMobile()">
              {{$t('nftList.buy')}} (<CurrencyConverter :king="convertFromWeiEther(t3LandPrice)" :skill="convertFromWeiEther(t3LandPrice)"
                                      :show-value-in-skill-only="selectedCurrency === 0"
                                      :show-value-in-king-only="selectedCurrency === 1"
                                      :max-decimals="2"/>)
            </span>
            <span class="gtag-link-others" v-else-if="nft.type === 'claimT2Land'">
              {{$t('nftList.claim2')}}
            </span>
            <span class="gtag-link-others" v-else-if="nft.type === 'claimT3Land'">
              {{$t('nftList.claim3')}}
            </span>
          </b-button>
        </li>
      </ul>
      <div class="centered-text-div mt-3" v-if="isSpecials && ownedLands.length !== 0">
        <h4>{{$t('nftList.owned')}} {{ownedLands.length > 1 ? "lands" : 'land'}}:</h4>
        <ul class="list-group raid-details mb-4" v-for="(land, index) in ownedLands" :key="index">
          <li class="list-group-item d-flex justify-content-between align-items-center details-text">
            {{$t('nftList.tier')}}
            <span class="badge badge-primary badge-pill">{{ land.tier }}</span>
          </li>
          <li v-if="land.chunkId !== '0'" class="list-group-item d-flex justify-content-between align-items-center details-text">
            {{$t('nftList.chunkID')}}
            <span class="badge badge-primary badge-pill">{{ land.chunkId }}</span>
          </li>
        </ul>
      </div>
    </div>

    <b-modal class="map-modal" :title="$t('nftList.chooseZone')" ref="map-modal" size="xl" hide-footer
             @hide="clearMapSelections()">
      <div class="w-100 padding-bottom-100">
        <div class="map-grid">
          <div class="zone" v-for="zoneId in zonesIds" :key="zoneId" @click="showZoneModal(zoneId)">
            <span>{{zonesPopulation[zoneId]}}/{{maxZonePopulation.toLocaleString()}}</span>
          </div>
        </div>
      </div>
    </b-modal>

    <b-modal class="map-modal" :title="$t('nftList.chooseZone')" ref="t2-claim-map-modal" size="xl" hide-footer
             @hide="clearMapSelections()">
      <div class="w-100 padding-bottom-100">
        <div class="map-grid">
          <div class="zone" :class="[reservationsIncludeZoneIdForTier(zoneId, 2) ? 'available' : null ]"
               v-for="zoneId in zonesIds" :key="zoneId"
               @click="reservationsIncludeZoneIdForTier(zoneId, 2) && showT2ZoneModal(zoneId)">
            <span v-if="reservationsIncludeZoneIdForTier(zoneId, 2)">{{$t('nftList.available')}}</span>
            <span>{{zonesPopulation[zoneId]}}/{{maxZonePopulation.toLocaleString()}}</span>
          </div>
        </div>
      </div>
    </b-modal>

    <b-modal class="map-modal" :title="$t('nftList.chooseZone')" ref="t3-claim-map-modal" size="xl" hide-footer
             @hide="clearMapSelections()">
      <div class="w-100 padding-bottom-100">
        <div class="map-grid">
          <div class="zone" :class="[reservationsIncludeZoneIdForTier(zoneId, 3) ? 'available' : null ]"
               v-for="zoneId in zonesIds" :key="zoneId"
               @click="reservationsIncludeZoneIdForTier(zoneId, 3) && showT3ZoneModal(zoneId)">
            <span v-if="reservationsIncludeZoneIdForTier(zoneId, 3)">{{$t('nftList.available')}}</span>
          </div>
        </div>
      </div>
    </b-modal>

    <b-modal ref="zone-modal" :title="$t('nftList.chooseChunk')" size="lg"
             @hide="selectedChunk = undefined" :hide-footer="!selectedTier">
      <div class="w-100 padding-bottom-100">
        <div v-if="selectedZone !== undefined" class="zone-grid"
             :style="{ backgroundImage: `url(${require(`@/assets/map-pieces/${selectedZone}.png`)})` }">
          <div class="chunk"
               :class="[reservedChunks.includes(chunkId.toString())
                    || (selectedTier === 3 && takenT3Chunks.includes(chunkId.toString())) ? 'reserved' : null ]"
               v-for="(chunkId, index) in chunksIds" :key="chunkId"
               @click="selectChunk(chunkId, index)"
               :style="[ selectedChunk === chunkId ? {backgroundColor: 'greenyellow'} : null ]">
            <span>ID: {{chunkId}}</span>
            <span>{{chunksPopulation[index]}}/{{maxChunkPopulation.toLocaleString()}}</span>
            <span v-if="selectedTier === 3 && takenT3Chunks.includes(chunkId.toString())">{{$t('nftList.taken')}}</span>
            <span v-else-if="reservedChunks.includes(chunkId.toString())">{{$t('nftList.reserved')}}</span>
          </div>
        </div>
      </div>
      <template #modal-footer>
        <b-button class="mt-3" block @click="purchaseLand(selectedChunk)"
                  :disabled="selectedChunk === undefined || !selectedChunkAvailable">{{$t('nftList.buyLand')}}</b-button>
      </template>
    </b-modal>

    <b-modal ref="t2-claim-zone-modal" :title="$t('nftList.chooseChunk')" size="lg"
             @hide="selectedChunk = undefined">
      <div class="w-100 padding-bottom-100">
        <div v-if="selectedZone !== undefined" class="zone-grid"
             :style="{ backgroundImage: `url(${require(`@/assets/map-pieces/${selectedZone}.png`)})` }">
          <div class="chunk" :class="[reservationsIncludeChunkIdForTier(chunkId, 2) ? 'available' : null ]"
               v-for="(chunkId, index) in chunksIds" :key="chunkId"
               @click="reservationsIncludeChunkIdForTier(chunkId, 2) && selectAvailableChunk(chunkId, index)"
               :style="[ selectedChunk === chunkId ? {opacity: '1'} : null ]">
            <span>ID: {{chunkId}}</span>
            <span>{{chunksPopulation[index]}}/{{maxChunkPopulation.toLocaleString()}}</span>
            <span v-if="reservationsIncludeChunkIdForTier(chunkId, 2)">{{$t('nftList.available2')}}</span>
          </div>
        </div>
      </div>
      <template #modal-footer>
        <b-button class="mt-3" block @click="claimLand(selectedChunk)"
                  :disabled="selectedChunk === undefined || !selectedChunkAvailable">{{$t('nftList.claimLand')}}</b-button>
      </template>
    </b-modal>

    <b-modal ref="t3-claim-zone-modal" :title="$t('nftList.chooseChunk')" size="lg"
             @hide="selectedChunk = undefined">
      <div class="w-100 padding-bottom-100">
        <div v-if="selectedZone !== undefined" class="zone-grid"
             :style="{ backgroundImage: `url(${require(`@/assets/map-pieces/${selectedZone}.png`)})` }">
          <div class="chunk" :class="[reservationsIncludeChunkIdForTier(chunkId, 3) ? 'available' : null ]"
               v-for="(chunkId, index) in chunksIds" :key="chunkId"
               @click="reservationsIncludeChunkIdForTier(chunkId,3) && selectAvailableChunk(chunkId, index)"
               :style="[ selectedChunk === chunkId ? {opacity: '1'} : null ]">
            <span>ID: {{chunkId}}</span>
            <span>{{chunksPopulation[index]}}/{{maxChunkPopulation.toLocaleString()}}</span>
            <span v-if="reservationsIncludeChunkIdForTier(chunkId, 3)">{{$t('nftList.available2')}}</span>
          </div>
        </div>
      </div>
      <template #modal-footer>
        <b-button class="mt-3" block @click="claimLand(selectedChunk)"
                  :disabled="selectedChunk === undefined || !selectedChunkAvailable">{{$t('nftList.claimLand')}}</b-button>
      </template>
    </b-modal>

    <div v-if="!isShop">
      <div>
        <h1 v-if="isLandTab">{{$t('nftList.lands')}} ({{totalNonIgnoredLandsCount}})</h1>
      </div>
      <div class="filters row mt-2" v-if="!isReward && !isBridge">
        <div v-if="!isMarket && !isLandTab" class="col-sm-6 col-md-4 dropdown-elem">
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

        <div class="col-sm-6 col-md-4 dropdown-elem" v-if="isMarket">
          <strong>{{$t('nftList.sort')}}</strong>
          <select class="form-control" v-model="priceSort" @change="saveFilters()">
            <option v-for="x in sorts" :value="x.dir" :key="x.dir">{{ x.name || $t('nftList.sorts.any') }}</option>
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
          <nft-options-dropdown v-if="showNftOptions" :nftType="nft.type" :nftId="nft.id" :options="options" :showTransfer="!isMarket" class="nft-options"/>
          <nft-icon :favorite="isFavorite(nft.type, nft.id)" :nft="nft" :isShop="isShop"/>
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
  </div>
</template>

<script lang="ts">
import {mapActions, mapGetters, mapMutations, mapState} from 'vuex';
import Events from '../../events';
import {Nft as nftItem} from '../../interfaces/Nft';
import {SkillShopListing} from '../../interfaces/SkillShopListing';
import NftIcon from '../NftIcon.vue';
import {Nft} from '@/interfaces/Nft';
import Vue from 'vue';
import { Accessors, PropType } from 'vue/types/options';
import { IState } from '@/interfaces';
import { BModal } from 'bootstrap-vue';
import {copyNftUrl, fromWeiEther} from '@/utils/common';
import _ from 'lodash';
import CurrencyConverter from '@/components/CurrencyConverter.vue';
import BigNumber from 'bignumber.js';
import i18n from '@/i18n';
import { NftOption } from '../NftOptionsDropdown.vue';
import NftOptionsDropdown from '../NftOptionsDropdown.vue';

interface Land {
  tier: string,
  chunkId: string,
  reseller?: string,
}

interface Reservation {
  id: number,
  tier: number,
  chunks: number[],
  zones: number[],
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
  landSaleAllowed: boolean;
  canPurchaseLand: boolean;
  purchase: Land | undefined;
  selectedTier: number;
  selectedCurrency: number;
  selectedZone: number | undefined;
  selectedChunk: number | undefined;
  selectedChunkAvailable: boolean;
  selectedChunkPopulation: number | undefined;
  selectedReservation: Reservation | undefined;
  maxZonePopulation: number;
  maxChunkPopulation: number;
  zonesIds: number[];
  zonesPopulation: number[];
  chunksIds: number[];
  takenT3Chunks: number[],
  chunksPopulation: number[];
  reservedChunks: string[];
  t1LandAvailable: boolean;
  t2LandAvailable: boolean;
  t3LandAvailable: boolean;
  checkIfCanPurchaseLandInterval: ReturnType<typeof setInterval> | null;
  checkOwnedLandsInterval: ReturnType<typeof setInterval> | null;
  checkPlayerReservedLandInterval: ReturnType<typeof setInterval> | null;
  t1LandPrice: string;
  t2LandPrice: string;
  t3LandPrice: string;
  reservations: Reservation[];
  ownedLands: Land[];
  tierFilter: string;
  chunkIdFilter: string;
  currentPage: number;
  totalItemsCount: number;
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
  purchaseShield(): Promise<void>;
  fetchShields(shieldIds: (string | number)[]): Promise<void>;
  fetchJunks(junkIds: (string | number)[]): Promise<void>;
  fetchTrinkets(trinketIds: (string | number)[]): Promise<void>;
  fetchWeapons(weaponIds: (string | number)[]): Promise<void>;
  fetchKeyLootboxes(keyLootboxIds: (string | number)[]): Promise<void>;
  updateTrinketIds(): Promise<void>;
  updateJunkIds(): Promise<void>;
  updateKeyLootboxIds(): Promise<void>;
  purchaseRenameTag(obj: {price: number}): Promise<void>;
  purchaseRenameTagDeal(obj: {price: number}): Promise<void>;
  purchaseWeaponRenameTag(obj: {price: number}): Promise<void>;
  purchaseWeaponRenameTagDeal(obj: {price: number}): Promise<void>;
  purchaseCharacterFireTraitChange(obj: {price: number}): Promise<void>;
  purchaseCharacterEarthTraitChange(obj: {price: number}): Promise<void>;
  purchaseCharacterWaterTraitChange(obj: {price: number}): Promise<void>;
  purchaseCharacterLightningTraitChange(obj: {price: number}): Promise<void>;
  purchaseWeaponCosmetic(obj: {cosmetic: number, price: number}): Promise<void>;
  purchaseCharacterCosmetic(obj: {cosmetic: number, price: number}): Promise<void>;
  getAllZonesPopulation(): Promise<number[]>;
  checkIfChunkAvailable(payload: { tier: number, chunkId: number }): Promise<boolean>;
  getZoneChunkPopulation(payload: {zoneId: string}): Promise<number[]>;
  getChunkPopulation(payload: {chunkIds: number[]}): Promise<number[]>;
  getPurchase(): Promise<{tier: string, chunkId: string}>;
  purchaseT1CBKLand(payload: {price: string, currency: number}): Promise<void>;
  purchaseT2CBKLand(payload: {price: string, chunkId: number, currency: number}): Promise<void>;
  purchaseT3CBKLand(payload: {price: string, chunkId: number, currency: number}): Promise<void>;
  getCBKLandPrice(payload: {tier: number, currency: number}): Promise<string>;
  getReservedChunksIds(): Promise<string[]>;
  getAvailableLand(): Promise<{t1Land: string, t2Land: string, t3Land: string}>;
  fetchIsLandSaleAllowed(): Promise<boolean>;
  getPlayerReservedLand(): Promise<{t2Reservations: number[], t3Reservations: number[]}>;
  getChunksOfReservation(payload: {reservationId: number}): Promise<number[]>;
  claimPlayerReservedLand(payload: {reservationId: number, chunkId: number, tier: number}): Promise<void>;
  getOwnedLands(): Promise<{ 0: string, 1: string, 2: string, 3: string, 4: string }[]>;
  getTakenT3Chunks(): Promise<number[]>;
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
      landSaleAllowed: false,
      canPurchaseLand: false,
      purchase: undefined,
      selectedTier: 0,
      selectedCurrency: 0,
      selectedZone: undefined,
      selectedChunk: undefined,
      selectedChunkAvailable: false,
      selectedChunkPopulation: 0,
      selectedReservation: undefined,
      maxZonePopulation: 10000,
      maxChunkPopulation: 100,
      zonesIds: Array.from({length: 100}, (x, i) => i),
      zonesPopulation: [],
      chunksIds: Array.from({length: 100}, (x, i) => i),
      takenT3Chunks: [],
      chunksPopulation: [],
      reservedChunks: [],
      t1LandAvailable: false,
      t2LandAvailable: false,
      t3LandAvailable: false,
      checkIfCanPurchaseLandInterval: null,
      checkOwnedLandsInterval: null,
      checkPlayerReservedLandInterval: null,
      t1LandPrice: '',
      t2LandPrice: '',
      t3LandPrice: '',
      reservations: [],
      ownedLands: [],
      tierFilter: '',
      chunkIdFilter: '',
      currentPage: 1,
      totalItemsCount: 0,
      options: []
    } as Data;
  },

  components: {
    CurrencyConverter,
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
    ...(mapActions(['purchaseShield', 'fetchShields', 'fetchJunks', 'fetchTrinkets', 'fetchWeapons', 'fetchKeyLootboxes', 'updateTrinketIds',
      'updateJunkIds', 'updateKeyLootboxIds', 'purchaseRenameTag', 'purchaseWeaponRenameTag',
      'purchaseRenameTagDeal', 'purchaseWeaponRenameTagDeal',
      'purchaseCharacterFireTraitChange', 'purchaseCharacterEarthTraitChange',
      'purchaseCharacterWaterTraitChange', 'purchaseCharacterLightningTraitChange',
      'purchaseWeaponCosmetic', 'purchaseCharacterCosmetic', 'getAllZonesPopulation', 'checkIfChunkAvailable',
      'getZoneChunkPopulation', 'getChunkPopulation', 'purchaseT1CBKLand', 'purchaseT2CBKLand', 'purchaseT3CBKLand', 'getCBKLandPrice',
      'getPurchase', 'getReservedChunksIds', 'getAvailableLand', 'fetchIsLandSaleAllowed', 'getPlayerReservedLand',
      'getChunksOfReservation', 'claimPlayerReservedLand', 'getOwnedLands', 'getTakenT3Chunks',
    ]) as StoreMappedActions),
    ...mapMutations(['setCurrentNft']),

    async onShieldBuy() {
      await this.purchaseShield();
    },

    saveFilters() {
      if(this.isMarket) {
        sessionStorage.setItem('market-nft-typefilter', this.typeFilter);
        sessionStorage.setItem('market-nft-starfilter', this.starFilter.toString());
        sessionStorage.setItem('market-nft-elementfilter', this.elementFilter);
        sessionStorage.setItem('market-nft-price-order', this.priceSort);
      } else {
        sessionStorage.setItem('nft-typefilter', this.typeFilter);
        sessionStorage.setItem('nft-starfilter', this.starFilter.toString());
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

    async checkIfCanPurchaseLand() {
      const purchase = await this.getPurchase();
      if(purchase) {
        this.purchase = purchase;
        this.canPurchaseLand = purchase.tier === '0';
      }
    },

    isFavorite(type: string, id: number): boolean {
      return this.favorites && this.favorites[type] && this.favorites[type][id];
    },

    async showMapModal() {
      this.zonesPopulation = await this.getAllZonesPopulation();
      (this.$refs['map-modal'] as BModal).show();
    },

    async showT2MapModal() {
      this.zonesPopulation = await this.getAllZonesPopulation();
      (this.$refs['t2-claim-map-modal'] as BModal).show();
    },

    async showT3MapModal() {
      this.zonesPopulation = await this.getAllZonesPopulation();
      (this.$refs['t3-claim-map-modal'] as BModal).show();
    },

    async showZoneModal(zoneId: number) {
      this.selectedZone = zoneId;
      await this.updateChunksPopulation(zoneId);
      (this.$refs['zone-modal'] as BModal).show();
    },

    async showT2ZoneModal(zoneId: number) {
      this.selectedZone = zoneId;
      await this.updateChunksPopulation(zoneId);
      (this.$refs['t2-claim-zone-modal'] as BModal).show();
    },

    async showT3ZoneModal(zoneId: number) {
      this.selectedZone = zoneId;
      await this.updateChunksPopulation(zoneId);
      (this.$refs['t3-claim-zone-modal'] as BModal).show();
    },

    async selectChunk(chunkId: number, index: number) {
      if(this.reservedChunks.includes(chunkId.toString())) {
        this.selectedChunk = undefined;
        return;
      }
      this.selectedChunk = chunkId;
      this.selectedChunkPopulation = this.chunksPopulation[index];
      if(this.selectedTier){
        this.selectedChunkAvailable = await this.checkIfChunkAvailable({tier: this.selectedTier, chunkId});
      }
    },

    selectAvailableChunk(chunkId: number, index: number) {
      this.selectedChunk = chunkId;
      this.selectedChunkPopulation = this.chunksPopulation[index];
      this.selectedReservation = this.reservations.find(reservation => reservation.chunks.includes(chunkId));
      this.selectedChunkAvailable = true;
    },

    clearMapSelections() {
      this.selectedZone = undefined;
      this.selectedTier = 0;
    },

    calculateChunksIds(zoneId: number) {
      const chunksIds = [] as number[];
      for (let i = 0; i < 10; i++) {
        for (let j = 0; j < 10; j++) {
          let chunkId = 0;
          if(+zoneId < 10) {
            chunkId = i * 100 + j + +zoneId * 10;
          }
          else if (+zoneId >= 10 && +zoneId < 100) {
            const zoneIdNumbers = this.splitNum(+zoneId);
            chunkId = i * 100 + j + zoneIdNumbers[0] * 1000 + zoneIdNumbers[1] * 10;
          }
          chunksIds.push(chunkId);
        }
      }
      this.chunksIds = chunksIds;
    },

    splitNum(num: number) {
      return String(num).split('').map(Number);
    },

    convertFromWeiEther(value: string|BigNumber): string | undefined {
      if(!value) {
        return;
      }
      return fromWeiEther(value);
    },

    maxPrecisionSkill(listedPrice: string): string {
      return this.convertStringToDecimal(fromWeiEther(listedPrice), 8);
    },

    convertStringToDecimal(val: string, maxDecimals: number) {
      return new BigNumber(val).toFixed(maxDecimals);
    },

    calculateZoneId(chunkId: number) {
      const chunkIdNumbers = this.splitNum(chunkId);
      if(chunkId < 100) {
        return Math.floor(chunkId / 10);
      } else if (chunkId >= 100 && chunkId < 1000) {
        return chunkIdNumbers[1];
      } else {
        return Math.floor(+(chunkIdNumbers[0].toString() + chunkIdNumbers[2].toString()));
      }
    },

    async onCurrencyChange() {
      await this.refreshLandPrices();
    },

    async fetchNfts() {
      await this.updateTrinketIds();
      await this.updateJunkIds();
      await this.updateKeyLootboxIds();
    },

    async refreshLandPrices() {
      this.t1LandPrice = await this.getCBKLandPrice({tier: 1, currency: this.selectedCurrency});
      this.t2LandPrice = await this.getCBKLandPrice({tier: 2, currency: this.selectedCurrency});
      this.t3LandPrice = await this.getCBKLandPrice({tier: 3, currency: this.selectedCurrency});
    },

    async updateChunksPopulation(zoneId: number) {
      this.calculateChunksIds(zoneId);
      this.chunksPopulation = await this.getChunkPopulation({chunkIds: this.chunksIds});
    },

    async purchaseLand(chunkId: number) {
      const chunkAvailable = await this.checkIfChunkAvailable({tier: this.selectedTier, chunkId});
      if (!chunkAvailable) {
        console.error('Chunk not available');
        return;
      }
      const price = await this.getCBKLandPrice({tier: this.selectedTier, currency: this.selectedCurrency});
      if(this.selectedTier === 2) {
        await this.purchaseT2CBKLand({price, chunkId, currency: this.selectedCurrency}).then(() => {
          if(this.selectedZone !== undefined) {
            this.updateChunksPopulation(this.selectedZone);
          }
          (this.$refs['zone-modal'] as BModal).hide();
          (this.$refs['map-modal'] as BModal).hide();
        });
      }
      if(this.selectedTier === 3) {
        await this.purchaseT3CBKLand({price, chunkId, currency: this.selectedCurrency}).then(() => {
          if(this.selectedZone !== undefined) {
            this.updateChunksPopulation(this.selectedZone);
          }
          (this.$refs['zone-modal'] as BModal).hide();
          (this.$refs['map-modal'] as BModal).hide();
        });
      }
      await this.checkIfCanPurchaseLand();
    },

    async claimLand(chunkId: number) {
      if (!this.selectedReservation) {
        return;
      }

      await this.claimPlayerReservedLand({
        reservationId: this.selectedReservation.id,
        chunkId,
        tier: this.selectedReservation.tier
      });
      if (this.selectedZone !== undefined) {
        await this.updateChunksPopulation(this.selectedZone);
      }
      (this.$refs['t2-claim-zone-modal'] as BModal).hide();
      (this.$refs['t2-claim-map-modal'] as BModal).hide();
      (this.$refs['t3-claim-zone-modal'] as BModal).hide();
      (this.$refs['t3-claim-map-modal'] as BModal).hide();
      await this.fetchOwnedLands();
      await this.checkIfCanPurchaseLand();
    },

    userHasReservationsForTier(tier: number) {
      return this.reservations.filter(reservation => reservation.tier === tier).flatMap(reservation => reservation.chunks).length !== 0;
    },

    reservationsIncludeChunkIdForTier(chunkId: number, tier: number) {
      return this.reservations.filter(reservation => reservation.tier === tier).flatMap(reservation => reservation.chunks).includes(chunkId);
    },

    reservationsIncludeZoneIdForTier(zoneId: number, tier: number) {
      return this.reservations.filter(reservation => reservation.tier === tier).flatMap(reservation => reservation.zones).includes(zoneId);
    },

    async fetchReservations() {
      const playerReservedLand = await this.getPlayerReservedLand();
      if (playerReservedLand) {
        this.takenT3Chunks = await this.getTakenT3Chunks();
        const t2Reservations = await Promise.all(playerReservedLand.t2Reservations.map(async (reservationId) => {
          return await this.mapToReservation(reservationId, 2);
        }));

        const t3Reservations = await Promise.all(playerReservedLand.t3Reservations.map(async (reservationId) => {
          return await this.mapToReservation(reservationId, 3);
        }));
        this.reservations = [...t2Reservations, ...t3Reservations];
      }
    },

    async mapToReservation(id: number, tier: number) {
      let chunks = await this.getChunksOfReservation({reservationId: id});
      if(tier === 3 ) {
        chunks = _.without(chunks.flat(), ...this.takenT3Chunks);
      }
      const zones = [...new Set(chunks.map(chunkId => this.calculateZoneId(chunkId)))];
      chunks = chunks.map(Number);
      return {id, tier, chunks, zones,} as Reservation;
    },

    async fetchOwnedLands() {
      const results = await this.getOwnedLands();
      if(results){
        this.ownedLands = results.map(result => ({tier: result[0], chunkId: result[1], reseller: result[4]}));
      }
    },

    buyButtonDisabled(type: string) {
      if (type === 'shield') {
        return false;
      }
      if((type === 't1land' || type === 't2land' || type === 't3land' ) && !this.canPurchaseLand){
        return true;
      }
      if(type === 't1land' && !this.t1LandAvailable) {
        return true;
      }
      if(type === 't2land' && !this.t2LandAvailable) {
        return true;
      }
      return type === 't3land' && !this.t3LandAvailable;
    },

    async buyItem(item: nftItem) {
      if(item.type === 'shield'){
        await this.purchaseShield();
      }

      if(item.type === 'CharacterRenameTag'){
        await this.purchaseRenameTag({price: item.nftPrice || 0});
      }
      if(item.type === 'CharacterRenameTagDeal'){
        await this.purchaseRenameTagDeal({price: item.nftPrice || 0});
      }
      if(item.type === 'WeaponRenameTag'){
        await this.purchaseWeaponRenameTag({price: item.nftPrice || 0});
      }
      if(item.type === 'WeaponRenameTagDeal'){
        await this.purchaseWeaponRenameTagDeal({price: item.nftPrice || 0});
      }
      if(item.type === 'CharacterFireTraitChange'){
        await this.purchaseCharacterFireTraitChange({price: item.nftPrice || 0});
      }
      if(item.type === 'CharacterEarthTraitChange'){
        await this.purchaseCharacterEarthTraitChange({price: item.nftPrice || 0});
      }
      if(item.type === 'CharacterWaterTraitChange'){
        await this.purchaseCharacterWaterTraitChange({price: item.nftPrice || 0});
      }
      if(item.type === 'CharacterLightningTraitChange'){
        await this.purchaseCharacterLightningTraitChange({price: item.nftPrice || 0});
      }
      if(item.type === 'WeaponCosmetic'){
        await this.purchaseWeaponCosmetic({cosmetic: +item.id, price: item.nftPrice || 0});
      }
      if(item.type === 'CharacterCosmetic'){
        await this.purchaseCharacterCosmetic({cosmetic: +item.id, price: item.nftPrice || 0});
      }
      if(item.type === 't1land'){
        const price = await this.getCBKLandPrice({tier: 1, currency: this.selectedCurrency});
        await this.purchaseT1CBKLand({price, currency: this.selectedCurrency});
        await this.checkIfCanPurchaseLand();
      }
      if(item.type === 't2land'){
        this.selectedTier = 2;
        this.showMapModal();
      }
      if(item.type === 't3land'){
        this.selectedTier = 3;
        this.showMapModal();
      }
      if(item.type === 'claimT2Land'){
        this.selectedTier = 2;
        this.showT2MapModal();
      }
      if(item.type === 'claimT3Land'){
        this.selectedTier = 3;
        this.showT3MapModal();
      }
    },
    itemDescriptionHtml(item: SkillShopListing): string {
      return item.name + '<br>' + item.description;
    },

    updateOptions() {
      if (this.isMarket) {
        this.options = [
          {
            name: i18n.t('copyLink').toString(),
            amount: 0,
            handler: copyNftUrl,
            hasDefaultOption: true,
            noAmount: true
          },
        ];
      }
    },
  },

  async mounted() {
    this.checkStorageFavorite();
    this.updateOptions();

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

    this.landSaleAllowed = await this.fetchIsLandSaleAllowed();

    await this.checkIfCanPurchaseLand();
    this.checkIfCanPurchaseLandInterval = setInterval(await this.checkIfCanPurchaseLand,3000);

    await this.fetchOwnedLands();
    this.checkOwnedLandsInterval = setInterval(await this.fetchOwnedLands, 3000);

    this.reservedChunks = await this.getReservedChunksIds();
    const {t1Land, t2Land, t3Land} = await this.getAvailableLand();
    this.t1LandAvailable = t1Land !== '0';
    this.t2LandAvailable = t2Land !== '0';
    this.t3LandAvailable = t3Land !== '0';
    await this.refreshLandPrices();
    await this.onCurrencyChange();

    await this.fetchReservations();
    this.checkPlayerReservedLandInterval = setInterval(await this.fetchReservations, 3000);
  },

  beforeDestroy() {
    if(this.checkIfCanPurchaseLandInterval){
      clearInterval(this.checkIfCanPurchaseLandInterval);
    }
    if(this.checkPlayerReservedLandInterval){
      clearInterval(this.checkPlayerReservedLandInterval);
    }
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

.map-modal {
  max-width: 100%;
  margin: 0.5rem;
}

.padding-bottom-100 {
  padding-bottom: 100%;
}

.map-grid,
.zone-grid {
  background-size: cover;
  display: grid;
  grid-template-columns: repeat(10, 1fr);
  grid-template-rows: repeat(10, 1fr);
  float: left;
  position: absolute;
  left: 0px;
  top: 0px;
  z-index: 1000;
  width: 100%;
  height: 100%;
}

.map-grid {
  background-image: url(../../assets/map.png);
}

.zone,
.chunk {
  opacity: 1;
  transition: 0.3s;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  text-shadow: 0px 2px 1px rgb(0 0 0), 0px 4px 7px rgb(0 0 0 / 40%), 0px 9px 12px rgb(0 0 0 / 10%);
  font-weight: bolder;
}

.zone:hover,
.chunk:hover {
  background-color: greenyellow;
  transform: scale(1.1);
}

.available {
  background-color: greenyellow;
  opacity: 0.5;
}

.reserved {
  background-color: black;
  opacity: 0.5;
}

.reserved:hover {
  background-color: black;
}

.details-text {
  font-size: 1.2em;
  color: #ccae4f;
}

.details-text > span {
  background-color: #ccae4f;
}

@media (max-width: 576px) {
  .weapon-grid {
    justify-content: center;
    margin-top: 10px;
  }

  .zone,
  .chunk {
    font-size: 0.5rem;
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
