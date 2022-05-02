<template>
  <div>
    <div class="filters pl-4 pr-4" v-if="!newWeapon" @change="saveFilters()">
      <h3 v-if="!noTitle">{{$t('weapons')}} ({{ ownWeapons }})</h3>
      <h3 v-if="noTitle">Selected ({{ ignore.length }})</h3>
      <span class="filter-icon" @click="showFilter"></span>
      <div class="row d-flex align-items-center none-mobile" style="flex-grow:0.6" >
          <div class="col-sm-12 col-md-6 col-lg-4 d-flex none-mobile">
            <div v-if="showFavoriteToggle" class="show-reforged show-favorite none-mobile">
              <b-check class="show-reforged-checkbox" v-model="showFavoriteWeapons" />
              <strong>{{$t('weaponGrid.showFavorite')}}</strong>
            </div>
          </div>
          <div class="col-sm-6 col-md-6 col-lg-3 mb-3 none-mobile">
            <strong>{{$t('weaponGrid.stars')}}</strong>
            <select class="form-control" v-model="starFilter" >
              <option v-for="x in starsOptions" :value="x" :key="x">{{ x || $t('nftList.sorts.any') }}</option>
            </select>
          </div>

          <div class="col-sm-6 col-md-6 col-lg-3 mb-3 none-mobile">
            <strong>{{$t('weaponGrid.element')}}</strong>
            <select class="form-control" v-model="elementFilter" >
              <option v-for="(x, index) in ['', $t('traits.earth'), $t('traits.fire'), $t('traits.lightning'), $t('traits.water')]"
              :value="['', 'Earth', 'Fire', 'Lightning', 'Water'][index]" :key="x">{{ x || $t('nftList.sorts.any') }}</option>
            </select>
          </div>
        <div class="col-sm-12 col-md-6 col-lg-2 none-mobile">
          <b-button
            v-if="!newWeapon"
            variant="primary"
            class="clear-filters-button mb-3"
            @click="clearFilters"
          >
            <span>
              Clear
            </span>
          </b-button>
        </div>
      </div>
    </div>


      <transition-group
        appear @before-enter="beforeEnter" @enter="enter"
        class="weapon-grid" tag="ul" name="list" ref="weapon-grid"
        >
        <li
          class="weapon" :style="setBorderSelected(weapon.id) ? 'border: 2px solid #fff' : ''"
          :class="{ selected: highlight !== null && weapon.id === highlight }"
          v-for="(weapon, i) in nonIgnoredWeapons.slice(((this.activePage*20)-20),((this.activePage*20)))"
          :key="weapon.id" :data-index="i"
          @click="(!checkForDurability || getWeaponDurability(weapon.id) > 0) && onWeaponClick(weapon.id)"
          @contextmenu="canFavorite && toggleFavorite($event, weapon.id)" @dblclick="canFavorite && toggleFavorite($event, weapon.id)">
          <nft-options-dropdown v-if="showNftOptions" :nftType="'weapon'" :nftId="weapon.id" :options="options" :showTransfer="!isMarket" class="nft-options"/>
          <div class="weapon-icon-wrapper">
            <weapon-icon class="weapon-icon" :weapon="weapon" :favorite="isFavorite(weapon.id)"/>
          </div>
          <div class="above-wrapper" v-if="$slots.above || $scopedSlots.above">
            <slot name="above" :weapon="weapon"></slot>
          </div>
          <slot name="sold" :weapon="weapon"></slot>
        </li>
      </transition-group>

    <div class="pagination" v-if="!noPagination">
      <div v-if="startList()" @click="createPagination(1)">1</div>
      <div v-if="startList()" class="more-pagination">...</div>
      <div v-for="page in pageSet" :key="page+1" @click="createPagination(page)"
        :class="page == activePage ? 'active-page' : ''">{{page}}</div>
      <div v-if="endList()" class="more-pagination">...</div>
      <div v-if="endList()" @click="createPagination(noOfPages)">{{noOfPages}}</div>
    </div>


    <b-modal class="centered-modal" ref="weapon-rename-modal"
      @ok="renameWeaponCall()">
      <template #modal-title>
        {{$t('weaponGrid.renameWeapon')}}
      </template>
      <b-form-input type="string"
        class="modal-input" v-model="weaponRename" :placeholder="$t('weaponGrid.renamePlaceholder')" />
      <span v-if="isRenameProfanish">
        {{$t('weaponGrid.isProfanish')}} <em>{{cleanRename}}</em>
      </span>
    </b-modal>

    <b-modal class="centered-modal" ref="weapon-change-skin-modal"
      @ok="changeWeaponSkinCall">
      <template #modal-title>
        {{$t('weaponGrid.changeWeaponSkill')}}
      </template>
      <span >
        {{$t('weaponGrid.pickSkin')}}
      </span>
      <select class="form-control" v-model="targetSkin">
        <option v-for="x in availableSkins" :value="x" :key="x">{{ x }}</option>
      </select>
    </b-modal>
    <b-modal ref="open-filter" id="open-filter" hide-footer hide-header>
       <div class="row d-flex align-items-center modal-filter" style="flex-grow:0.6" >
         <h4>Filter Weapon</h4>
          <div class="col-sm-6 col-md-6 col-lg-3 mb-3">
            <strong>{{$t('weaponGrid.stars')}}</strong>
            <select class="form-control" v-model="starFilter" >
              <option v-for="x in starsOptions" :value="x" :key="x">{{ x || $t('nftList.sorts.any') }}</option>
            </select>
          </div>

          <div class="col-sm-6 col-md-6 col-lg-3 mb-3">
            <strong>{{$t('weaponGrid.element')}}</strong>
            <select class="form-control" v-model="elementFilter" >
              <option v-for="(x, index) in ['', $t('traits.earth'), $t('traits.fire'), $t('traits.lightning'), $t('traits.water')]"
              :value="['', 'Earth', 'Fire', 'Lightning', 'Water'][index]" :key="x">{{ x || $t('nftList.sorts.any') }}</option>
            </select>
          </div>
           <div class="col-sm-12 col-md-6 col-lg-4 d-flex">
            <div v-if="showReforgedToggle" class="show-reforged">
              <b-check class="show-reforged-checkbox" v-model="showReforgedWeapons" />
              <strong>{{$t('weaponGrid.showReforged')}}</strong>
            </div>
            <div v-if="showFavoriteToggle" class="show-reforged show-favorite">
              <b-check class="show-reforged-checkbox" v-model="showFavoriteWeapons" />
              <strong>{{$t('weaponGrid.showFavorite')}}</strong>
            </div>
          </div>
        <div class="col-sm-12 col-md-6 col-lg-2 d-flex">
          <button
            v-if="!newWeapon"
            @click="clearFilters"
            class="forge-btn">
            <span>CLEAR FILTER</span>
          </button>
          <button class="forge-btn" @click="$bvModal.hide('open-filter')">
            <span>DONE</span>
          </button>
        </div>
      </div>
    </b-modal>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import Events from '../../events';
import gasp from 'gsap';
import { Accessors, PropType } from 'vue/types/options';
import { mapActions, mapGetters, mapMutations, mapState } from 'vuex';
import { IState, IWeapon } from '../../interfaces';
import WeaponIcon from '../WeaponIconNew.vue';
import { NftOption } from '../NftOptionsDropdown.vue';
import { BModal } from 'bootstrap-vue';
import { getCleanName, isProfaneIsh } from '../../rename-censor';
import NftOptionsDropdown from '../NftOptionsDropdown.vue';
import i18n from '@/i18n';
import { copyNftUrl } from '@/utils/common';
type StoreMappedState = Pick<IState, 'ownedWeaponIds'>;
interface StoreMappedGetters {
  weaponsWithIds(weaponIds: (string | number)[]): IWeapon[];
}
interface StoreMappedActions {
  fetchWeapons(weaponIds: string[]): Promise<void>;
  renameWeapon(arg: {id: number, name: string}): Promise<void>;
  fetchTotalWeaponRenameTags(): Promise<number>;
  fetchOwnedWeaponCosmetics(arg: { cosmetic: number }): Promise<number>;
  changeWeaponCosmetic(arg: { id: number, cosmetic: number }): Promise<void>;
  removeWeaponCosmetic(arg: { id: number }): Promise<void>;
}
interface Data {
  starFilter: string | number;
  elementFilter: string;
  minPriceFilter: string;
  maxPriceFilter: string;
  favorites: Record<number, boolean>;
  priceSort: string;
  showReforgedWeapons: boolean;
  showFavoriteWeapons: boolean;
  options: NftOption[];
  haveRename: number;
  weaponRename: string;
  haveWeaponCosmetics: number[];
  targetSkin: string;
  currentWeaponId: number | string | null;
  weaponCosmeticsNames: string[];
  activePage: number;
  pageSet: number[];
  noOfPages: number;
  noOfItemsPerRow: number;
}
const sorts = [
  { name: i18n.t('weaponGrid.sorts.any'), dir: '' },
  { name: i18n.t('weaponGrid.sorts.lowToHigh'), dir: 1 },
  { name: i18n.t('weaponGrid.sorts.highToLow'), dir: -1 },
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
      default() {
        return [];
      },
    },
    noPagination: {
      type: Boolean,
      default: false,
    },
    showGivenWeaponIds: {
      type: Boolean,
      default: false,
    },
    noTitle: {
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
    showNftOptions: {
      type: Boolean,
      default: false
    },
    ownWeapons:{
      type: Number,
      default: 0
    },
    starsOptions: {
      type: Array as PropType<(string | number)[]>,
      default() {
        return ['', 1, 2, 3, 4, 5];
      },
    },
    chosenStarsOption: {
      type: [String, Number],
    },
  },
  data() {
    return {
      starFilter: this.starsOptions?.length === 1 ? this.starsOptions[0] : '',
      elementFilter: '',
      minPriceFilter:'',
      maxPriceFilter:'',
      favorites: {},
      priceSort: '',
      sorts,
      showReforgedWeapons: this.showReforgedWeaponsDefVal,
      showFavoriteWeapons: this.showFavoriteWeaponsDefVal,
      options: [],
      haveRename: 0,
      weaponRename: '',
      haveWeaponCosmetics: [],
      targetSkin: '',
      currentWeaponId: null,
      noOfItemsPerRow: 0,
      weaponCosmeticsNames: [
        i18n.t('market.nftList.weaponGrayscale'),
        i18n.t('market.nftList.weaponContrast'),
        i18n.t('market.nftList.weaponSepia'),
        i18n.t('market.nftList.weaponInvert'),
        i18n.t('market.nftList.weaponBlur'),
        i18n.t('market.nftList.weaponFireglow'),
        i18n.t('market.nftList.weaponEarthglow'),
        i18n.t('market.nftList.weaponLightningglow'),
        i18n.t('market.nftList.weaponWaterglow'),
        i18n.t('market.nftList.weaponRainbowglow'),
        i18n.t('market.nftList.weaponDarkglow'),
        i18n.t('market.nftList.weaponGhost'),
        i18n.t('market.nftList.weaponPolicelights'),
        i18n.t('market.nftList.weaponNeonborder'),
        i18n.t('market.nftList.weaponRotatingNeonborder'),
        i18n.t('market.nftList.weaponDiamondborder'),
        i18n.t('market.nftList.weaponGoldborder'),
        i18n.t('market.nftList.weaponSilverborder'),
        i18n.t('market.nftList.weaponBronzeborder')
      ],
      // data for paginations
      activePage: 1,
      pageSet: [],
      noOfPages: 0
    } as Data;
  },
  components: {
    WeaponIcon,
    NftOptionsDropdown
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
      if (this.newWeapon) {
        return this.displayWeapons;
      }
      let items: IWeapon[] = [];
      this.displayWeapons.forEach((x) => items.push(x));
      const allIgnore: string[] = [];
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
    isRenameProfanish(): boolean {
      return isProfaneIsh(this.weaponRename);
    },
    cleanRename(): string {
      return getCleanName(this.weaponRename);
    },
    availableSkins(): string[] {
      const availableSkins = [];
      availableSkins.push('No Skin');
      for(let i = 0; i < 19; i++) {
        if(+this.haveWeaponCosmetics[i] > 0) {
          availableSkins.push(this.weaponCosmeticsNames[i]);
        }
      }
      return availableSkins;
    },
    totalCosmeticChanges(): number {
      let count = 0;
      this.haveWeaponCosmetics.forEach(x => count += +x);
      return count;
    },
  },
  watch: {
    async weaponIdsToDisplay(newWeaponIds: string[]) {
      await this.fetchWeapons(newWeaponIds);
      console.log('weapon forged');
      await this.createPagination(this.activePage);
    },
    starFilter(){
      this.createPagination(1);
    },
  },
  methods: {
    ...(mapActions(['fetchWeapons','renameWeapon','fetchTotalWeaponRenameTags',
      'fetchOwnedWeaponCosmetics','changeWeaponCosmetic','removeWeaponCosmetic']) as StoreMappedActions),
    ...(mapMutations(['setCurrentWeapon'])),
    saveFilters() {
      if(this.isMarket) {
        sessionStorage.setItem('market-weapon-starfilter', this.starFilter.toString());
        sessionStorage.setItem('market-weapon-elementfilter', this.elementFilter);
        sessionStorage.setItem('market-weapon-price-order', this.priceSort);
        sessionStorage.setItem('market-weapon-price-minfilter', this.minPriceFilter?''+this.minPriceFilter:'');
        sessionStorage.setItem('market-weapon-price-maxfilter', this.maxPriceFilter?''+this.maxPriceFilter:'');
      } else {
        sessionStorage.setItem('weapon-starfilter', this.starFilter.toString());
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
    setBorderSelected(weaponId: number){
      let bols = false;
      if(this.ignore){
        this.ignore.forEach((x: any) => {
          if(Number(x) === weaponId){
            bols = true;
          }
        });
      }
      return bols;
    },
    clearFilters() {
      if(this.isMarket) {
        sessionStorage.removeItem('market-weapon-starfilter');
        sessionStorage.removeItem('market-weapon-elementfilter');
        sessionStorage.removeItem('market-weapon-price-order');
        sessionStorage.removeItem('market-weapon-price-minfilter');
        sessionStorage.removeItem('market-weapon-price-maxfilter');
      } else {
        sessionStorage.removeItem('weapon-starfilter');
        sessionStorage.removeItem('weapon-elementfilter');
      }
      this.elementFilter = '';
      this.starFilter = this.starsOptions?.length === 1 ? this.starsOptions[0] : '';
      this.priceSort = '';
      this.minPriceFilter= '';
      this.maxPriceFilter= '';
      this.$emit('weapon-filters-changed');
    },
    onWeaponClick(id: number) {
      this.setCurrentWeapon(id);
      this.$emit('chooseweapon', id);
      this.$emit('choose-weapon', id);
    },
    checkStorageFavorite() {
      const favoritesFromStorage = localStorage.getItem('favorites');
      if (favoritesFromStorage) {
        this.favorites = JSON.parse(favoritesFromStorage);
      }
    },
    openRenameWeapon(id: number | string) {
      this.currentWeaponId = id;
      (this.$refs['weapon-rename-modal'] as BModal).show();
    },
    showFilter(){
      (this.$refs['open-filter'] as BModal).show();
    },
    async renameWeaponCall() {
      if(!this.currentWeaponId) return;
      await this.renameWeapon({id: +this.currentWeaponId, name: this.weaponRename});
      this.haveRename = await this.fetchTotalWeaponRenameTags();
      this.updateOptions();
      this.weaponRename = '';
    },
    async loadCosmeticsCount() {
      this.haveWeaponCosmetics = [];
      for(let i = 1; i < 22; i++) {
        this.haveWeaponCosmetics.push(await this.fetchOwnedWeaponCosmetics({cosmetic: i}));
      }
      this.updateOptions();
    },
    openChangeSkin(id: number | string) {
      this.currentWeaponId = id;
      (this.$refs['weapon-change-skin-modal'] as BModal).show();
    },
    async changeWeaponSkinCall() {
      if(!this.currentWeaponId) return;
      // +1 because cosmetics are 1 (not 0) based
      const selectedSkinId = this.weaponCosmeticsNames.findIndex(x => x === this.targetSkin) + 1;
      if(selectedSkinId === 0) {
        await this.removeWeaponCosmetic({ id: +this.currentWeaponId });
        await this.loadCosmeticsCount();
      } else {
        await this.changeWeaponCosmetic({ id: +this.currentWeaponId, cosmetic: selectedSkinId });
        this.haveWeaponCosmetics[selectedSkinId - 1] = await this.fetchOwnedWeaponCosmetics({cosmetic: selectedSkinId});
        await this.loadCosmeticsCount();
      }
      this.updateOptions();
    },
    updateOptions() {
      if(!this.isMarket) {
        this.options = [
          {
            name: i18n.t('characterList.rename').toString(),
            amount: this.haveRename,
            handler: this.openRenameWeapon
          },
          {
            name: i18n.t('characterList.changeSkin').toString(),
            amount: this.totalCosmeticChanges,
            handler: this.openChangeSkin,
            hasDefaultOption: true
          },
        ];
      } else {
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
    createPagination(activePage: number){
      const noOfItems = this.nonIgnoredWeapons.length;
      this.activePage = activePage;
      this.noOfPages = Math.ceil(noOfItems/20);
      this.pageSet = [];
      if(this.noOfPages > 5){
        if(activePage > 3){
          if(this.noOfPages - this.activePage < 3){
            for (let a = 3; a >= 0; a--) {
              this.pageSet.push(this.noOfPages - a);
            }
          }else{
            this.pageSet.push(activePage - 1);
            this.pageSet.push(activePage);
            this.pageSet.push(activePage + 1);
          }
        }else{
          for (let a = 1; a < 5; a++) {
            this.pageSet.push(a);
          }
        }
      }else{
        for (let x = 0; x < this.noOfPages; x++) {
          this.pageSet.push(x+1);
        }
      }
    },
    startList(){
      return ((this.noOfPages > 6 && this.activePage > 3 ) || ((this.noOfPages > 5) && (this.noOfPages - this.activePage < 3)));
    },
    endList(){
      return ((this.noOfPages > 6 && (this.noOfPages - this.activePage > 2)) || (this.noOfPages > 5) && (this.activePage < 4));
    },

    enter(el: any, done: any) {
      gasp.to(el, {
        opacity: 1,
        y: 0,
        duration: 0.5,
        onComplete: done,
        delay: el.dataset.index * 0.1
      });
    },
    beforeEnter(el: any){
      el.style.opacity = 0;
      el.style.transform = 'translateY(100px)';
    }
  },
  async mounted() {
    this.checkStorageFavorite();
    Events.$on('weapon:newFavorite', () => this.checkStorageFavorite());
    if(this.isMarket) {
      this.starFilter = sessionStorage.getItem('market-weapon-starfilter') || '';
      this.elementFilter = sessionStorage.getItem('market-weapon-elementfilter') || '';
      this.priceSort = sessionStorage.getItem('market-weapon-price-order') || '';
      this.minPriceFilter = sessionStorage.getItem('market-weapon-price-minfilter') || '';
      this.maxPriceFilter = sessionStorage.getItem('market-weapon-price-maxfilter') || '';
    } else if (this.chosenStarsOption !== undefined) {
      this.starFilter = this.chosenStarsOption;
    } else {
      this.starFilter = sessionStorage.getItem('weapon-starfilter') || '';
      this.elementFilter = sessionStorage.getItem('weapon-elementfilter') || '';
    }
    this.haveRename = await this.fetchTotalWeaponRenameTags();
    await this.loadCosmeticsCount();
    this.createPagination(this.activePage);
  },
});
</script>

<style scoped>
.filters {
   justify-content: center;
   width: 100%;
   /* max-width: 900px; */
   margin: 0 auto;
   align-items: center;
   border-bottom: 0.2px solid rgba(102, 80, 80, 0.1);
   margin-bottom: 20px;
}

.filters > h3{
  font-family: Trajan;
}

.filters{
  display: flex;
  justify-content: space-between;
}

.weapon-grid {
  list-style-type: none;
  justify-content: center;
  margin: 0;
  padding: 0;
  display: grid;
  padding: 0.5em;
  grid-template-columns: repeat(auto-fit, 13em);
  gap: 3vw;
}
.weapon {
  width: 105%;
  background: rgb(26, 24, 24);
  border-radius: 5px;
  cursor: pointer;
  position: relative;
  overflow: visible;
  margin-bottom: 15px;
}
.weapon.selected {
  outline: solid currentcolor 2px;
}
.weapon-icon-wrapper {
  width: 13.5em;
  height: 18em;
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
  height: fit-content;
  display: flex;
  flex-direction: row;
  align-self: flex-end;
  margin:0 15px;
}

.pagination{
  display: flex;
  justify-content: center;
}

.pagination > div {
  font-family: Roboto;
  color: #fff;
  border: 1px solid rgba(255, 255, 255, 0.39);
  padding: 5px 10px;
  margin-right: 10px;
  border-radius: 5px;
  cursor: pointer;
}

.pagination > div:hover{
  border: 1px solid #fff;
}

.pagination > .active-page{
  border: 1px solid #fff;
}



.pagination > .more-pagination{
  border: none;
  padding-bottom: 0px;
}

@media (max-width: 576px) {
  .weapon-grid {
    justify-content: center;
    margin-top: 10px;
  }

  .weapon-content > div > .weapon-grid{
    padding-left: 0px;
  }

  .show-reforged {
    width: 100%;
    justify-content: center;
    margin-bottom: 15px;
  }

.forge-btn{
  display: flex;
  flex-direction: column;
  border: none;
  width: 200px;
  height: 50px;
  align-items: center;
  vertical-align: middle;
  justify-content: center;
  background-image: url('../../assets/buttonOutline.svg');
  background-color: transparent;
  background-repeat: no-repeat;
  background-size: 100% 100%;
  -o-object-fit: fill;
  object-fit: fill;
  border: none !important;
}

.forge-btn > span{
  font-family: Oswald;
  color:#fff;
}

.modal-filter > h4{
  font-family: Trajan;
  padding: 10px 20px ;
}


  .none-mobile{
    display: none;
  }

  .filters > h3{
    font-size: 5.5vw;
  }

  .pagination{
    margin-top: 2em;
  }

  .pagination > div {
    font-size: 11px;
  }

  .pagination > .more-pagination {
      padding-bottom: 0px;
      padding-right: 0px;
      padding-left: 0px;
  }

  .clear-filters-button {
    width: 100%;
    text-align: center;
    justify-content: center;
  }
  .ml-3 {
    margin-left: 0 !important;
  }

  .filters {
    flex-direction: row;
  }

  .filter-icon{
    content: url('../../assets/blacksmith/filter.svg');
    height: 30px;
    width: 30px;
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
.nft-options {
  position: absolute;
  right: 10px;
  top: 0px !important;
}

.id-number{
  position: absolute;
  right: 10px;
  top: 10px !important;
  font-size: 0.9em;
  color: #fff;
  font-family: Roboto;
}
</style>
