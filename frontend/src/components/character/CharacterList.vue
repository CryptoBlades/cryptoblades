<template>
  <div class="character-list-container pt-4">
    <div class="filters row mt-2 pl-2" v-if="showFilters && !isMobile()" @change="saveFilters()">
      <div>
        <div class="select-wrapper-no" :data-content="$t('characterList.level')">
          <select class="form-control" v-model="levelFilter">
            <option v-for="x in ['', 1, 11, 21, 31, 41, 51, 61, 71, 81, 91]" :value="x" :key="x">
              {{ x ? `${x} - ${x + 9}` : $t('characterList.sorts.any') }}
            </option>
          </select>
        </div>
        <div class="select-wrapper-element" :data-content="$t('characterList.element')">
          <select class="form-control" v-model="elementFilter">
            <option v-for="(x, index) in ['', $t('traits.earth'), $t('traits.fire'), $t('traits.lightning'), $t('traits.water')]"
            :value="['', 'Earth', 'Fire', 'Lightning', 'Water'][index]" :key="x">{{ x || $t('characterList.sorts.any') }}</option>
          </select>
        </div>
      </div>

      <div>
        <button class="clear-filters-button" @click="selectAll">
          <span>
            {{allSelected ? $t('Character.deselectAll') : $t('Character.selectAll')}}
          </span>
        </button>
        <button class="clear-filters-button" @click="clearFilters" >
          <span>
            {{$t('characterList.clearFilters')}}
          </span>
        </button>
      </div>
    </div>
    <div class="mobile-filter" v-if="showFilters && isMobile()" @click="openFilter">
      <span class="filter"></span>
    </div>

    <ul class="character-list">
      <li
        class="character"
        :style="toBurn.includes(c.id.toString()) ? 'border: 1px solid #EDCD90' : 'border: 1px solid '+generateColor(c.traitName)"
        :class="[value === c.id ? 'selected' : '', showCosmetics ? 'character-animation-applied-' + getCharacterCosmetic(c.id) : '']"
        v-for="c in filteredCharacters"
        :key="c.id"
        :id="c.traitName.toLowerCase()"
        @click="$emit('input', c.id)"
      >
      <div class="backdrop-bg"></div>
        <div :class="nftDisplay ? 'above-wrapper-nft-display' : 'above-wrapper'" v-if="$slots.above || $scopedSlots.above">
          <slot name="above" :character="c"></slot>
        </div>
        <slot name="sold" :character="c"></slot>
        <nft-options-dropdown v-if="showNftOptions" :nftType="'character'" :nftId="c.id" :options="options"
          showTransfer class="nft-options"/>
        <div class="art" >
          <div class="animation" />
          <CharacterArt :class="[showCosmetics ? 'character-cosmetic-applied-' + getCharacterCosmetic(c.id) : '']"
            :character="c" :isGarrison="isGarrison" :isSelected="toBurn.includes(c.id.toString())"/>
        </div>
      </li>
    </ul>

    <b-modal class="centered-modal" ref="filter-modal" hide-footer hide-header>
      <div class="row">
        <div class="col-sm-12 filter-title">
          <h4>{{$t('Character.filterCharacter')}}</h4>
        </div>
        <div class="col-sm-6 mt-1 mb-2">
          <div class="select-wrapper-no">
            <span>{{$t('Character.characterLevel')}}}</span>
            <select class="form-control mt-2" v-model="levelFilter">
              <option v-for="x in ['', 1, 11, 21, 31, 41, 51, 61, 71, 81, 91]" :value="x" :key="x">
                {{ x ? `${x} - ${x + 9}` : $t('characterList.sorts.any') }}
              </option>
            </select>
          </div>
        </div>
        <div class="col-sm-6 mt-3 mb-2">
          <div class="select-wrapper-element">
            <span>{{$t('Character.element')}}}</span>
            <select class="form-control mt-2" v-model="elementFilter">
              <option v-for="(x, index) in ['', $t('traits.earth'), $t('traits.fire'), $t('traits.lightning'), $t('traits.water')]"
              :value="['', 'Earth', 'Fire', 'Lightning', 'Water'][index]" :key="x">{{ x || $t('characterList.sorts.any') }}</option>
            </select>
          </div>
        </div>
        <div class="col-sm-6 mt-3 mb-2">
          <button class="clear-filters-button" @click="selectAll">
            <span>
              {{allSelected ? $t('Character.deselectAll') : $t('Character.selectAll')}}
            </span>
          </button>
        </div>
        <div class="col-sm-6 mt-1 mb-2">
          <button class="clear-filters-button" @click="clearFilters" >
            <span>
              {{$t('characterList.clearFilters')}}
            </span>
          </button>
        </div>
      </div>
      <div class="footer-close" @click="$refs['filter-modal'].hide()">
        <p class="tapAny mt-4">{{$t('tapAnyWhere')}}</p>
        <p class="close-icon"></p>
      </div>
    </b-modal>

    <b-modal class="centered-modal" ref="character-rename-modal"
      @ok="renameCharacterCall">
      <template #modal-title>
        {{$t('characterList.renameCharacter')}}
      </template>
      <b-form-input type="string"
        class="modal-input" v-model="characterRename" :placeholder="$t('characterList.newName')" />
      <span v-if="characterRename !== '' && (characterRename.length < 2 || characterRename.length > 24)">
        {{$t('characterList.renameCharacterLengthWarning')}}
      </span>
      <span v-if="isRenameProfanish">
        {{$t('characterList.renameCharacterProfanityWarning')}}
         <em>{{cleanRename}}</em>
      </span>
      <div class="footer-close" @click="$refs['character-rename-modal'].hide()">
        <p class="tapAny mt-4">{{$t('tapAnyWhere')}}</p>
        <p class="close-icon"></p>
      </div>
    </b-modal>

    <b-modal class="centered-modal" ref="character-change-trait-modal"
      @ok="changeCharacterTraitCall">
      <template #modal-title>
        {{$t('characterList.changeCharacterTrait')}}
      </template>
      <span>
        {{$t('characterList.pickTrait')}}
      </span>
      <select class="form-control" v-model="targetTrait">
        <option v-for="x in availableTraits" :value="x" :key="x">{{ x }}</option>
      </select>
      <div class="footer-close" @click="$refs['character-change-trait-modal'].hide()">
        <p class="tapAny mt-4">{{$t('tapAnyWhere')}}</p>
        <p class="close-icon"></p>
      </div>
    </b-modal>

    <b-modal class="centered-modal" ref="character-change-skin-modal"
      hide-header cancel-disabled@ok="changeCharacterSkinCall">
      <h3 class="confirmation-title">   {{$t('characterList.changeCharacterSkin')}}</h3>
      <span >
        {{$t('characterList.pickSkin')}}
      </span>
      <select class="form-control" v-model="targetSkin">
        <option v-for="skin in availableSkins" :value="skin.id" :key="skin.id">
          {{ skin.name || $t(`cosmetics.characterCosmetic.${CharacterCosmetic[skin.id]}`) }}
        </option>
      </select>
      <div class="footer-close" @click="$refs['character-change-skin-modal'].hide()">
        <p class="tapAny mt-4">{{$t('tapAnyWhere')}}</p>
        <p class="close-icon"></p>
      </div>
    </b-modal>
  </div>
</template>

<script>
import {mapActions, mapGetters, mapState} from 'vuex';
import {getCharacterArt} from '@/character-arts-placeholder';
import CharacterArt from '../CharacterArt.vue';
import NftOptionsDropdown from '../NftOptionsDropdown.vue';
import {getCleanName, isProfaneIsh} from '@/rename-censor';
import Events from '@/events';
import i18n from '@/i18n';
import {CharacterCosmetic} from '@/enums/CharacterCosmetic';

const sorts = [
  { name: i18n.t('characterList.sorts.any'), dir: '' },
  { name: i18n.t('characterList.sorts.lowToHigh'), dir: 1 },
  { name: i18n.t('characterList.sorts.highToLow'), dir: -1 },
];

export default {
  props: {
    value: {},
    showGivenCharacterIds: {
      type: Boolean,
      default: false
    },
    showFilters: {
      type: Boolean,
      default: false
    },
    characterIds: {
      type: Array,
      default() { return []; }
    },
    showLimit: {
      type: Number,
      default: 0
    },
    nftDisplay: {
      type: Boolean,
      default: false
    },
    toBurn:{
      type: Array,
      default() { return []; }
    },
    showNftOptions: {
      type: Boolean,
      default: false
    },
    isGarrison: {
      type: Boolean,
      default: false
    },
  },

  data() {
    return {
      levelFilter: '',
      elementFilter: '',
      sorts,
      haveRename: 0,
      characterRename: '',
      haveChangeTraitFire: 0,
      haveChangeTraitEarth: 0,
      haveChangeTraitWater: 0,
      haveChangeTraitLightning: 0,
      targetTrait: '',
      currentCharacterId: null,
      options: [],
      haveCharacterCosmetic1: 0,
      haveCharacterCosmetic2: 0,
      haveCharacterCosmetics: [],
      targetSkin: '',
      showCosmetics: true,
      allSelected: false,
      CharacterCosmetic,
    };
  },

  computed: {
    ...mapState(['maxStamina', 'ownedCharacterIds', 'ownedGarrisonCharacterIds']),
    ...mapGetters(['getCharacterName', 'allStaminas', 'charactersWithIds', 'garrisonCharactersWithIds', 'getCharacterCosmetic']),

    characterIdsToDisplay() {
      if(this.showGivenCharacterIds) {
        return this.characterIds;
      }

      return this.isGarrison ? this.ownedGarrisonCharacterIds : this.ownedCharacterIds;
    },

    displayCharacters() {
      return this.isGarrison
        ? this.garrisonCharactersWithIds(this.characterIdsToDisplay).filter(Boolean)
        : this.charactersWithIds(this.characterIdsToDisplay).filter(Boolean);
    },

    filteredCharacters() {
      let items = this.displayCharacters;

      if(this.showFilters) {
        if(this.elementFilter) {
          items = items.filter(x => x.traitName.includes(this.elementFilter));
        }

        if(this.levelFilter) {
          items = items.filter(x => x.level >= this.levelFilter - 1 && x.level <= this.levelFilter + 8);
        }

        if(this.showLimit > 0 && items.length > this.showLimit) {
          items = items.slice(0, this.showLimit);
        }
      }

      return items;
    },

    totalTraitChanges() {
      return +this.haveChangeTraitFire + +this.haveChangeTraitEarth + +this.haveChangeTraitLightning + +this.haveChangeTraitWater;
    },

    totalCosmeticChanges() {
      let count = 0;
      this.haveCharacterCosmetics.forEach(x => count += +x);
      return count;
    },

    isRenameProfanish() {
      return isProfaneIsh(this.characterRename);
    },

    cleanRename() {
      return getCleanName(this.characterRename);
    },

    availableTraits() {
      const availableTraits = [];
      if(this.haveChangeTraitFire > 0) {
        availableTraits.push('Fire');
      }
      if(this.haveChangeTraitEarth > 0) {
        availableTraits.push('Earth');
      }
      if(this.haveChangeTraitWater > 0) {
        availableTraits.push('Water');
      }
      if(this.haveChangeTraitLightning > 0) {
        availableTraits.push('Lightning');
      }

      return availableTraits;
    },

    availableSkins() {
      const availableSkins = [];

      availableSkins.push({
        id: 0,
        name: 'No skin',
        amount: 1
      });

      for(let i = 0; i < 19; i++) {
        if(+this.haveCharacterCosmetics[i] > 0) {
          availableSkins.push({
            id: i + 1,
          });
        }
      }

      return availableSkins;
    }
  },

  watch: {
    async characterIdsToDisplay(characterIds) {
      await this.fetchCharacters(characterIds);
    },
    filteredCharacters(){
      this.filteredCharacters.every(filteredCharacter => {
        // convert id string to integer
        const idToBurn = this.toBurn.map(id => Number(id));
        if(!idToBurn.includes(filteredCharacter.id)){
          this.allSelected = false;
          return false;
        }
        if(this.characterIds.length === this.toBurn.length){
          this.allSelected = true;
        }

        return true;
      });
    },
    toBurn(){
      this.filteredCharacters.every(filteredCharacter => {
        // convert id string to integer
        const idToBurn = this.toBurn.map(id => Number(id));
        if(!idToBurn.includes(filteredCharacter.id)){
          this.allSelected = false;
          return false;
        }
        if(this.characterIds.length === this.toBurn.length){
          this.allSelected = true;
        }

        return true;
      });
    }
  },

  methods: {
    ...mapActions(['fetchCharacters','fetchTotalRenameTags','renameCharacter','changeCharacterTraitLightning',
      'changeCharacterTraitEarth', 'changeCharacterTraitFire', 'changeCharacterTraitWater',
      'fetchTotalCharacterFireTraitChanges','fetchTotalCharacterEarthTraitChanges',
      'fetchTotalCharacterWaterTraitChanges', 'fetchTotalCharacterLightningTraitChanges',
      'fetchOwnedCharacterCosmetics','changeCharacterCosmetic','removeCharacterCosmetic','restoreFromGarrison', 'sendToGarrison']),

    getCharacterArt,

    saveFilters() {
      sessionStorage.setItem('character-levelfilter', this.levelFilter);
      sessionStorage.setItem('character-elementfilter', this.elementFilter);

      this.$emit('character-filters-changed');
    },

    selectAll(){
      this.allSelected = !this.allSelected;
      if(this.allSelected) Events.$emit('select-all', this.filteredCharacters);
      else Events.$emit('deselect-all', this.filteredCharacters);
    },
    openFilter(){
      (this.$refs['filter-modal']).show();
    },

    clearFilters() {
      sessionStorage.removeItem('character-levelfilter');
      sessionStorage.removeItem('character-elementfilter');

      this.elementFilter = '';
      this.levelFilter = '';

      this.$emit('character-filters-changed');
    },

    generateColor(trait){
      const el = trait.toLowerCase();
      if(el === 'water') return '#3997F5';
      if(el === 'fire') return '#DB0000';
      if(el === 'earth') return '#24A24B';
      if(el === 'lightning') return '#FEE200';
    },

    async loadConsumablesCount() {
      this.haveRename = await this.fetchTotalRenameTags();
      this.haveChangeTraitFire = await this.fetchTotalCharacterFireTraitChanges();
      this.haveChangeTraitEarth = await this.fetchTotalCharacterEarthTraitChanges();
      this.haveChangeTraitWater = await this.fetchTotalCharacterWaterTraitChanges();
      this.haveChangeTraitLightning = await this.fetchTotalCharacterLightningTraitChanges();
      this.updateOptions();
    },

    updateOptions() {
      if(this.isGarrison) {
        this.options = [
          {
            name: this.$t('characterList.restoreToPlaza'),
            amount: 0,
            handler: this.onRestoreToPlaza,
            hasDefaultOption: true,
            noAmount: true
          },
        ];
      } else {
        this.options = [
          {
            name: this.$t('characterList.rename'),
            amount: this.haveRename,
            handler: this.openRenameCharacter
          },
          {
            name: this.$t('characterList.changeTrait'),
            amount: this.totalTraitChanges,
            handler: this.openChangeTrait
          },
          {
            name: this.$t('characterList.changeSkin'),
            amount: this.totalCosmeticChanges,
            handler: this.openChangeSkin,
            hasDefaultOption: true,
          },
          {
            name: this.$t('characterList.sendToGarrison'),
            amount: 0,
            handler: this.onSendToGarrison,
            hasDefaultOption: true,
            noAmount: true
          },
        ];
      }
    },

    async onRestoreToPlaza(id) {
      if(this.ownedCharacterIds.length < 4) {
        await this.restoreFromGarrison(id);
      } else {
        this.$dialog.notify.error(this.$t('characterList.plazaFull'));
      }
    },

    async onSendToGarrison(id) {
      await this.sendToGarrison(id);
    },

    openRenameCharacter(id) {
      this.currentCharacterId = id;
      (this.$refs['character-rename-modal']).show();
    },
    async renameCharacterCall(bvModalEvt) {
      if(this.characterRename.length < 2 || this.characterRename.length > 24){
        bvModalEvt.preventDefault();
        return;
      }

      await this.renameCharacter({id: this.currentCharacterId, name: this.characterRename.trim()});
      this.haveRename = await this.fetchTotalRenameTags();
      this.updateOptions();
    },

    openChangeTrait(id) {
      this.currentCharacterId = id;
      (this.$refs['character-change-trait-modal']).show();
    },
    async changeCharacterTraitCall(bvModalEvt) {
      if(!this.targetTrait) {
        bvModalEvt.preventDefault();
      }
      switch(this.targetTrait) {
      case 'Fire':
        await this.changeCharacterTraitFire({ id: this.currentCharacterId });
        this.haveChangeTraitFire = await this.fetchTotalCharacterFireTraitChanges();
        break;
      case 'Earth' :
        await this.changeCharacterTraitEarth({ id: this.currentCharacterId });
        this.haveChangeTraitEarth = await this.fetchTotalCharacterEarthTraitChanges();
        break;
      case 'Water':
        await this.changeCharacterTraitWater({ id: this.currentCharacterId });
        this.haveChangeTraitWater = await this.fetchTotalCharacterWaterTraitChanges();
        break;
      case 'Lightning':
        await this.changeCharacterTraitLightning({ id: this.currentCharacterId });
        this.haveChangeTraitLightning = await this.fetchTotalCharacterLightningTraitChanges();
        break;
      }
      this.updateOptions();
    },

    async loadCosmeticsCount() {
      this.haveCharacterCosmetics = [];
      for(let i = 1; i < 21; i++) {
        this.haveCharacterCosmetics.push(await this.fetchOwnedCharacterCosmetics({cosmetic: i}));
      }
      this.updateOptions();
    },

    openChangeSkin(id) {
      this.currentCharacterId = id;
      (this.$refs['character-change-skin-modal']).show();
    },
    async changeCharacterSkinCall() {
      if(!this.currentCharacterId) return;
      if(+this.targetSkin === 0) {
        await this.removeCharacterCosmetic({ id: +this.currentCharacterId });
        await this.loadCosmeticsCount();
      } else {
        await this.changeCharacterCosmetic({ id: +this.currentCharacterId, cosmetic: this.targetSkin });
        await this.loadCosmeticsCount();
      }

      this.updateOptions();
    },

    checkStorage() {
      this.showCosmetics = localStorage.getItem('showCosmetics') !== 'false';
    },
  },

  components: {
    CharacterArt,
    NftOptionsDropdown,
  },

  async mounted() {
    this.levelFilter = sessionStorage.getItem('character-levelfilter') || '';
    this.elementFilter = sessionStorage.getItem('character-elementfilter') || '';

    this.checkStorage();
    Events.$on('setting:showCosmetics', () => this.checkStorage());

    await this.loadConsumablesCount();
    await this.loadCosmeticsCount();
  },
};
</script>

<style scoped>
@import '../../styles/character-cosmetics.css';
.filters {
   justify-content: space-between;
   width: 100%;
   margin: 0 auto;
   align-content: center;
   border-bottom: 0.2px solid rgba(102, 80, 80, 0.1);
   margin-bottom: 20px;
}

.character-list {
  list-style-type: none;
  margin: 0;
  padding: 0;
  display: grid;
  padding: 0.5em;
  grid-template-columns: repeat(auto-fit, 16em);
  gap: 2.5em;
  padding-left: 2em;
  padding-right: 2em;
  justify-content: center;
  padding-bottom: 2em;
}

.character-list-container{
  border: 1px solid #333;
  border-radius: 10px;
}

.character-list-container > .filters{
  border-bottom: 1px solid #333;
}

.character-list-container > .row.filters{
  max-width: 100%;
}

.filters > div {
  display: flex;
  gap: 2em;
  padding:1em;
}

.filters > div:nth-child(2){
  gap: 0em;
  justify-content: flex-end;
}

.select-wrapper-no > select.form-control,
.select-wrapper-element > select.form-control{
  background-color: rgba(0, 0, 0, 0);
  width: 200px;
  font-family: Roboto;
  color: rgb(128, 128, 128);
}

.select-wrapper-no:after {
  content: attr(data-content);
  width: 0;
  height: 0;
  border-top: 6px solid #666;
  position: absolute;
  left: 55px;
  top: 50px;
  font-family: Roboto;
  color: rgba(255, 255, 255, 0.541);
}

.select-wrapper-element:after {
  content: attr(data-content);
  width: 0;
  height: 0;
  border-top: 6px solid #666;
  position: absolute;
  margin-left: 10px;
  top: 50px;
  font-family: Roboto;
  color: rgba(255, 255, 255, 0.541);
}

.select-wrapper-no > select.form-control option,
.select-wrapper-element > select.form-control option{
  background-color: #171617;
  padding: 1px;
  color: #fff;
  font-family: Roboto;
  text-align: right;
}

.select-wrapper-no > select.form-control, .select-wrapper-element > select.form-control {
  text-align: right;
}

.mobile-filter{
  display: flex;
  align-items: center;
  text-align: center;
  justify-content: center;
}

.mobile-filter > span.filter{
  content: url('../../assets/filter-circle.svg');
  height: 2em;
  width: 2em;
  margin-top: 1em;
}

.character {
  position: relative;
  width: 17em;
  height: 23em;
  background-position: center;
  background-repeat: no-repeat;
  background-size: 115%;
  /* background-color: #2e2e30cc; */
  background-image: url('../../assets/background/earth-bg.png');
  border: 1px solid #a28d54;
  border-radius: 10px;
  cursor: pointer;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  overflow: hidden;
}

.backdrop-bg{
  /* background-image: linear-gradient(to bottom, rgba(0, 0, 0, 0.082),  rgba(0, 0, 0, 0.466), rgba(0, 0, 0, 0.466)); */
  background-color: rgba(0, 0, 0, 0.267);
  position: absolute;
  left: 0;
  top: 0;
  height: 100%;
  width: 100%;
}

#earth{
  background-image: url('../../assets/background/earth-bg.png');
}
#water{
  background-image: url('../../assets/background/water-bg.png');
}
#lightning{
  background-image: url('../../assets/background/lightning-bg.png');
}
#fire{
  background-image: url('../../assets/background/fire-bg.png');
}

.character .art {
  width: 100%;
  min-height: 0;
  height: 18rem;
  background-position: center;
  background-repeat: no-repeat;
  background-size: contain;
}

.valign-middle {
  vertical-align: middle;
}

.character img {
  object-fit: contain;
}

.character.selected {
  box-shadow: 0 0 8px #ffd400;
}

.above-wrapper-nft-display,
.above-wrapper {
  position: absolute;
  top: 270px;
  left: 0;
  right: 0;
  z-index: 100;
  text-shadow: 0 0 5px #333, 0 0 10px #333, 0 0 15px #333, 0 0 10px #333;
}

.above-wrapper-nft-display {
  top: 220px;
}

@media (max-width: 576px) {
  .character-list {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
  }

  .clear-filters-button {
    width: 100%;
    text-align: center;
    justify-content: center;
    margin: 0px;
    padding: 8px 20px;
  }

  .clear-filters-button > span{
    font-family: Roboto;
  }

  .select-wrapper-no > select.form-control, .select-wrapper-element > select.form-control {
    background-color: rgba(0, 0, 0, 0);
    width: 100%;
    font-family: Roboto;
    color: rgb(128, 128, 128);
  }

  .filter-title > h4{
    font-family: Trajan;
    color: #EDCD90;
    text-align: center;
  }

  .select-wrapper-no > span,.select-wrapper-element > span{
    font-size: 0.9em;
    font-family: Roboto;
    color: #fff;
    margin-bottom: 10px;
  }
}

.sold {
  height: 40px;
  width: 300px;
  background-color: rgb(187, 33, 0);
  transform: rotate(30deg);
  left: -40px;
  position: absolute;
  top: 150px;
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
