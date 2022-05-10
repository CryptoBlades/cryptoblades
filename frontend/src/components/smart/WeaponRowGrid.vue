<template>
  <div class="change-weapon">
    <div class="cw-content">
      <div class="filters row mt-2" v-if="!newWeapon" @change="saveFilters()">
        <div class="col-sm-12 d-flex justify-content-between">
            <h4>{{$t('blacksmith.selectWeapon').toUpperCase()}}</h4>
            <a @click="closeInventory(false)">
              <span class="close-icon"></span>
            </a>
        </div>
        <div class="col-sm-6 col-md-6 col-lg-6 mb-3">
          <strong>{{$t('weaponGrid.stars')}}</strong>
          <select class="form-control" v-model="starFilter" >
            <option v-for="x in starsOptions" :value="x" :key="x">{{ x || $t('nftList.sorts.any') }}</option>
          </select>
        </div>
        <div class="col-sm-6 col-md-6 col-lg-6 mb-3">
          <strong>{{$t('weaponGrid.element')}}</strong>
          <select class="form-control" v-model="elementFilter" >
            <option v-for="(x, index) in ['', $t('traits.earth'), $t('traits.fire'), $t('traits.lightning'), $t('traits.water')]"
            :value="['', 'Earth', 'Fire', 'Lightning', 'Water'][index]" :key="x">{{ x || $t('nftList.sorts.any') }}</option>
          </select>
        </div>

        <!-- Select Box -->
        <div v-if="showReforgedToggle" class="show-reforged col-sm-6 col-md-6 col-lg-6">
          <b-check class="show-reforged-checkbox" v-model="showReforgedWeapons" />
          <strong>{{$t('weaponGrid.showReforged')}}</strong>
        </div>

        <div v-if="showFavoriteToggle" class="show-reforged show-favorite col-sm-6 col-md-6 col-lg-6">
          <b-check class="show-reforged-checkbox" v-model="showFavoriteWeapons" />
          <strong>{{$t('weaponGrid.showFavorite')}}</strong>
        </div>
        <!-------------------------------->
      </div>

      <ul class="weapon-grid">
        <li
          class="weapon"
          :class="{ selected: highlight !== null && weapon.id === highlight }"
          v-for="weapon in nonIgnoredWeapons"
          :key="weapon.id"
          @click="(!checkForDurability || getWeaponDurability(weapon.id) > 0) && onWeaponClick(weapon)"
          @contextmenu="canFavorite && toggleFavorite($event, weapon.id)" @dblclick="canFavorite && toggleFavorite($event, weapon.id)">
          <nft-options-dropdown v-if="showNftOptions" :nftType="'weapon'"
          :nftId="weapon.id" :options="options" :showTransfer="!isMarket" class="nft-options"/>
          <div class="weapon-icon-wrapper">
            <weapon-inventory class="weapon-icon" :id="'weapon-'+weapon.id" :weapon="weapon" :favorite="isFavorite(weapon.id)" :displayType="'inventory'"/>
            <weapon-popover :weapon="weapon"/>
          </div>
          <div class="above-wrapper" v-if="$slots.above || $scopedSlots.above">
            <slot name="above" :weapon="weapon"></slot>
          </div>
          <slot name="sold" :weapon="weapon">
          </slot>
        </li>
      </ul>

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
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import Events from '../../events';
import { Accessors, PropType } from 'vue/types/options';
import { mapActions, mapGetters, mapMutations, mapState } from 'vuex';
import { IState, IWeapon } from '../../interfaces';
import WeaponInventory from '../WeaponInvetory.vue';
import WeaponPopover from '../WeaponPopover.vue';
import { NftOption } from '../NftOptionsDropdown.vue';
import { BModal } from 'bootstrap-vue';
import { getCleanName, isProfaneIsh } from '../../rename-censor';
import NftOptionsDropdown from '../NftOptionsDropdown.vue';
import i18n from '@/i18n';

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
  favorites: Record<number, boolean>;
  showReforgedWeapons: boolean;
  showFavoriteWeapons: boolean;
  options: NftOption[];
  haveRename: number;
  weaponRename: string;
  haveWeaponCosmetics: number[];
  targetSkin: string;
  currentWeaponId: number | string | null;
  weaponCosmeticsNames: string[];
  hoveredWeapon: string [];
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
    starsOptions: {
      type: Array as PropType<(string | number)[]>,
      default() {
        return ['', 1, 2, 3, 4, 5];
      },
    },
  },
  data() {
    return {
      starFilter: this.starsOptions?.length === 1 ? this.starsOptions[0] : '',
      elementFilter: '',
      favorites: {},
      sorts,
      showReforgedWeapons: this.showReforgedWeaponsDefVal,
      showFavoriteWeapons: this.showFavoriteWeaponsDefVal,
      options: [],
      haveRename: 0,
      weaponRename: '',
      haveWeaponCosmetics: [],
      targetSkin: '',
      currentWeaponId: null,
      hoveredWeapon: [],
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
      ]
    } as Data;
  },
  components: {
    // WeaponIcon,
    NftOptionsDropdown,
    WeaponInventory,
    WeaponPopover
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
    },
  },
  methods: {
    ...(mapActions(['fetchWeapons','renameWeapon','fetchTotalWeaponRenameTags',
      'fetchOwnedWeaponCosmetics','changeWeaponCosmetic','removeWeaponCosmetic']) as StoreMappedActions),
    ...(mapMutations(['setCurrentWeapon'])),
    saveFilters() {
      sessionStorage.setItem('weapon-starfilter', this.starFilter.toString());
      sessionStorage.setItem('weapon-elementfilter', this.elementFilter);
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
      sessionStorage.removeItem('weapon-starfilter');
      sessionStorage.removeItem('weapon-elementfilter');
      this.elementFilter = '';
      this.starFilter = this.starsOptions?.length === 1 ? this.starsOptions[0] : '';
      this.$emit('weapon-filters-changed');
    },
    onWeaponClick(weapon: any) {
      this.setCurrentWeapon(weapon.id);
      Events.$emit('chooseweapon', weapon.id);
      this.$emit('choose-weapon', weapon.id);
      Events.$emit('weapon-inventory', false);
      Events.$emit('setActiveWeapon', weapon);
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
    },
    closeInventory(bol: any){
      Events.$emit('weapon-inventory', bol);
    }
  },
  async mounted() {
    this.checkStorageFavorite();
    Events.$on('weapon:newFavorite', () => this.checkStorageFavorite());
    this.starFilter = sessionStorage.getItem('weapon-starfilter') || '';
    this.elementFilter = sessionStorage.getItem('weapon-elementfilter') || '';
    if(this.starsOptions?.length === 1) {
      this.starFilter = this.starsOptions[0];
    }
    this.haveRename = await this.fetchTotalWeaponRenameTags();
    await this.loadCosmeticsCount();
  },
});
</script>

<style scoped>

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
  overflow-y: auto;
  height: 80vh;
  list-style-type: none;
  justify-content: left;
  margin: 0;
  padding: 0;
  display: grid;
  padding: 0.5em;
  grid-template-columns: repeat(auto-fit, 14em);
  gap: 0.5em;
}

.scroll-weapon{
  overflow-x:auto;
  height: 80vh;
}

.weapon {
  width: 23.2em;
  border-radius: 5px;
  margin-bottom: 15px;
  cursor: pointer;
  position: relative;
  overflow: visible;
}
.weapon.selected {
  outline: solid currentcolor 2px;
}
.above-wrapper {
  padding: 0.1rem;
}
.toggle-button {
  align-self: stretch;
}

.cw-content{
  border: 1px solid #ffffff52;
}

.close-icon{
  content: url('../../assets/close-btn.png');
  height: 30px;
  width: 30px;
  cursor: pointer;
}

.show-reforged {
  display: flex;
  flex-direction: row;
  align-self: center;
}
.show-favorite {
    margin-left: 0px !important;
}

.change-weapon{
  animation: fadeInLeft 0.5s ease-in-out;
}

@keyframes fadeInLeft {
    0%{
      right: -200px;
      opacity: 0;
    }
    100%{
      right: 0;
      opacity: 1;
    }
  }


.clear-filters-button {
  height: fit-content;
  display: flex;
  flex-direction: row;
  align-self: flex-end;
  margin:0 15px;
}
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
  right: 0;
  top: 0;
}

/* for change weapon compnent */
.change-weapon{
  position: fixed;
  right: 0;
  top: 0;
  height: 100vh;
  width: 450px;
  z-index: 5;
  background-color: rgb(27, 29, 24);
}

.cw-content h4{
  font-family: 'Trajan', serif;
  text-transform: capitalize;
}

.cw-content{
  padding: 20px 30px;
}
/* --------------------------------- */

.weapon-grid{
  padding-left: 0px;
}

@media all and (max-width: 600px) {
  .change-weapon{
    width: 100%;
  }

  .weapon-grid .weapon{
    width: 100%;
  }

  .weapon-grid{
    grid-template-columns:none;
    gap: 2em;
    height: calc(100vh - 300px);
    overflow-x: auto;
  }

}
</style>
