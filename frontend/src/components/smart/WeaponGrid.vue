<template>
  <div>
    <div class="filters row mt-2 pl-2" v-if="!newWeapon" @change="saveFilters()">
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

      <div v-if="showReforgedToggle" class="show-reforged">
        <b-check class="show-reforged-checkbox" v-model="showReforgedWeapons" />
        <strong>{{$t('weaponGrid.showReforged')}}</strong>
      </div>

      <div v-if="showFavoriteToggle" class="show-reforged show-favorite">
        <b-check class="show-reforged-checkbox" v-model="showFavoriteWeapons" />
        <strong>{{$t('weaponGrid.showFavorite')}}</strong>
      </div>

      <b-button
        v-if="!newWeapon"
        class="clear-filters-button mb-3"
        @click="clearFilters"
      >
        <span>
          {{$t('weaponGrid.clearFilters')}}
        </span>
      </b-button>
    </div>

    <ul class="weapon-grid">
      <li
        class="weapon"
        :class="{ selected: highlight !== null && weapon.id === highlight }"
        v-for="weapon in nonIgnoredWeapons"
        :key="weapon.id"
        @click="(!checkForDurability || getWeaponDurability(weapon.id) > 0) && onWeaponClick(weapon.id)"
        @contextmenu="canFavorite && toggleFavorite($event, weapon.id)" @dblclick="canFavorite && toggleFavorite($event, weapon.id)">
        <nft-options-dropdown v-if="showNftOptions" :nftType="'weapon'" :nftId="weapon.id" :options="options" showTransfer class="nft-options"/>
        <div class="weapon-icon-wrapper">
          <weapon-icon class="weapon-icon" :weapon="weapon" :favorite="isFavorite(weapon.id)" />
        </div>
        <div class="above-wrapper" v-if="$slots.above || $scopedSlots.above">
          <slot name="above" :weapon="weapon"></slot>
        </div>
        <slot name="sold" :weapon="weapon"></slot>
      </li>
    </ul>

    <b-modal centered class="centered-modal" ref="weapon-rename-modal" hide-header hide-footer>
      <h3 class="confirmation-title">{{$t('weaponGrid.renameWeapon')}}</h3>
      <b-form-input type="string"
        class="modal-input" v-model="weaponRename" :placeholder="$t('weaponGrid.renamePlaceholder')" />
      <span v-if="isRenameProfanish">
        {{$t('weaponGrid.isProfanish')}} <em>{{cleanRename}}</em>
      </span>
      <div class="footer-btn mb-4">
        <button class="close-btn"   @click="renameWeaponCall()">{{$t('blacksmith.confirm')}}</button>
      </div>
      <div class="footer-close" @click="$refs['weapon-rename-modal'].hide()">
        <p class="tapAny mt-4">{{$t('tapAnyWhere')}}</p>
        <p class="close-icon"></p>
      </div>
    </b-modal>

    <b-modal centered class="centered-modal" ref="weapon-change-skin-modal" hide-footer hide-header>
      <h3 class="confirmation-title">{{$t('weaponGrid.changeWeaponSkill')}}</h3>
      <span >
        {{$t('weaponGrid.pickSkin')}}
      </span>
      <select class="form-control" v-model="targetSkin">
        <option v-for="skin in availableSkins" :value="skin.id" :key="skin.id">
          {{ skin.name || $t(`cosmetics.weaponCosmetic.${WeaponCosmetic[skin.id]}`) }}
        </option>
      </select>
      <div class="footer-btn mb-4">
        <button class="close-btn"   @click="changeWeaponSkinCall()">{{$t('blacksmith.confirm')}}</button>
      </div>
      <div class="footer-close" @click="$refs['weapon-change-skin-modal'].hide()">
        <p class="tapAny mt-4">{{$t('tapAnyWhere')}}</p>
        <p class="close-icon"></p>
      </div>
    </b-modal>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import Events from '../../events';
import {Accessors, PropType} from 'vue/types/options';
import {mapActions, mapGetters, mapMutations, mapState} from 'vuex';
import {IState, IWeapon} from '../../interfaces';
import WeaponIcon from '../WeaponIcon.vue';
import NftOptionsDropdown, {NftOption} from '../NftOptionsDropdown.vue';
import {BModal} from 'bootstrap-vue';
import {getCleanName, isProfaneIsh} from '../../rename-censor';
import i18n from '@/i18n';
import {WeaponCosmetic} from '@/enums/WeaponCosmetic';
import { ICombatState } from '@/store/combat';

type StoreMappedState = Pick<IState, 'ownedWeaponIds'>;
interface Skin {
  id: number;
  name?: string;
  amount: number;
}
interface StoreMappedGetters {
  weaponsWithIds(weaponIds: (string | number)[]): IWeapon[];
}
interface StoreMappedCombatGetters {
  getWeaponDurability(state: ICombatState): number;
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
    chosenStarsOption: {
      type: [String, Number],
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
      WeaponCosmetic
    } as Data;
  },
  components: {
    WeaponIcon,
    NftOptionsDropdown
  },
  computed: {
    ...(mapState(['ownedWeaponIds']) as Accessors<StoreMappedState>),
    ...(mapGetters(['weaponsWithIds',]) as Accessors<StoreMappedGetters>),
    ...(mapGetters('combat', ['getWeaponDurability']) as Accessors<StoreMappedCombatGetters>),
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
    availableSkins(): Skin[] {
      const availableSkins = [];

      availableSkins.push({
        id: 0,
        name: 'No skin',
        amount: 1
      });

      for(let i = 0; i < 19; i++) {
        if(+this.haveWeaponCosmetics[i] > 0) {
          availableSkins.push({
            id: i + 1,
            amount: +this.haveWeaponCosmetics[i]
          });
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
      if(+this.targetSkin === 0) {
        await this.removeWeaponCosmetic({ id: +this.currentWeaponId });
        await this.loadCosmeticsCount();
      } else {
        await this.changeWeaponCosmetic({ id: +this.currentWeaponId, cosmetic: +this.targetSkin });
        this.haveWeaponCosmetics[+this.targetSkin] = await this.fetchOwnedWeaponCosmetics({cosmetic: +this.targetSkin});
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
  },
  async mounted() {
    this.checkStorageFavorite();
    Events.$on('weapon:newFavorite', () => this.checkStorageFavorite());
    if (this.chosenStarsOption !== undefined) {
      this.starFilter = this.chosenStarsOption;
    } else {
      this.starFilter = sessionStorage.getItem('weapon-starfilter') || '';
      this.elementFilter = sessionStorage.getItem('weapon-elementfilter') || '';
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
  overflow: visible;
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
  height: fit-content;
  display: flex;
  flex-direction: row;
  align-self: flex-end;
  margin:0 15px;
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
    text-align: center;
    justify-content: center;
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
.nft-options {
  position: absolute;
  right: 0;
  top: 0;
}
</style>
