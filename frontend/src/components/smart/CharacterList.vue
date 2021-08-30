<template>
  <div>
    <div class="filters row mt-2 pl-2" v-if="showFilters" @change="saveFilters()">
      <div class="col-sm-6 col-md-6 col-lg-2 mb-3">
        <strong>Level</strong>
        <select class="form-control" v-model="levelFilter">
          <option v-for="x in ['', 1, 11, 21, 31, 41, 51, 61, 71, 81, 91]" :value="x" :key="x">
            {{ x ? `${x} - ${x + 9}` : 'Any' }}
          </option>
        </select>
      </div>

      <div class="col-sm-6 col-md-6 col-lg-2 mb-3">
        <strong>Element</strong>
        <select class="form-control" v-model="elementFilter">
          <option v-for="x in ['', 'Earth', 'Fire', 'Lightning', 'Water']" :value="x" :key="x">{{ x || 'Any' }}</option>
        </select>
      </div>

      <template v-if="isMarket">
        <div class="col-sm-6 col-md-6 col-lg-2 mb-3">
          <strong>Min Price</strong>
          <input class="form-control" type="number" v-model.trim="minPriceFilter" :min="0" placeholder="Min" />
        </div>
        <div class="col-sm-6 col-md-6 col-lg-2 mb-3">
          <strong>Max Price</strong>
          <input class="form-control" type="number" v-model.trim="maxPriceFilter" :min="0" placeholder="Max" />
        </div>
        <div class="col-sm-6 col-md-6 col-lg-2 mb-3">
          <strong>Sort</strong>
          <select class="form-control" v-model="priceSort">
            <option v-for="x in sorts" :value="x.dir" :key="x.dir">{{ x.name || 'Any' }}</option>
          </select>
        </div>
      </template>

      <b-button variant="primary" class="clear-filters-button mb-3" @click="clearFilters" >
          <span>
            Clear Filters
          </span>
        </b-button>
    </div>

    <ul class="character-list">
      <li
        class="character"
        :class="{ selected: value === c.id }"
        v-for="c in filteredCharacters"
        :key="c.id"
        @click="$emit('input', c.id)"
      >
        <div class="above-wrapper" v-if="$slots.above || $scopedSlots.above">
          <slot name="above" :character="c"></slot>
        </div>
        <slot name="sold" :character="c"></slot>
        <nft-options-dropdown :nftId="c.id" :options="options" class="nft-options"/>
        <div class="art">
          <CharacterArt :character="c" :isMarket="isMarket"/>
        </div>
      </li>
    </ul>
    <b-modal class="centered-modal" ref="character-rename-modal"
                  @ok="renameCharacterCall">
                  <template #modal-title>
                    Rename Character
                  </template>
                  <b-form-input type="string"
                    class="modal-input" v-model="characterRename" placeholder="New Name" />
                  <span v-if="characterRename !== '' && (characterRename.length < 2 || characterRename.length > 24)">
                    Name must be 2 - 24 characters long.
                  </span>
                  <span v-if="isRenameProfanish">
                    This name contains profanish words and thus will be displayed as follows: <em>{{cleanRename}}</em>
                  </span>
                </b-modal>
        <b-modal class="centered-modal" ref="character-change-trait-modal"
                  @ok="changeCharacterTraitCall">
                  <template #modal-title>
                    Change Character's Trait
                  </template>
                  <span >
                    Pick a trait to switch to.
                  </span>
                  <select class="form-control" v-model="targetTrait">
                    <option v-for="x in availableTraits" :value="x" :key="x">{{ x }}</option>
                  </select>
                </b-modal>
  </div>
</template>

<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import { getCharacterArt } from '../../character-arts-placeholder';
import CharacterArt from '../CharacterArt.vue';
import NftOptionsDropdown from '../NftOptionsDropdown.vue';
import { getCleanName, isProfaneIsh } from '../../rename-censor';

const sorts = [
  { name: 'Any', dir: '' },
  { name: 'Price: Low -> High', dir: 1 },
  { name: 'Price: High -> Low', dir: -1 },
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
    isMarket: {
      type: Boolean,
      default: false
    }
  },

  data() {
    return {
      levelFilter: '',
      elementFilter: '',
      minPriceFilter:'',
      maxPriceFilter:'',
      priceSort: '',
      sorts,
      haveRename: 0,
      characterRename: '',
      haveChangeTraitFire: 0,
      haveChangeTraitEarth: 0,
      haveChangeTraitWater: 0,
      haveChangeTraitLightning: 0,
      targetTrait: '',
      currentCharacterId: null,
      options: []
    };
  },

  computed: {
    ...mapState(['maxStamina', 'ownedCharacterIds']),
    ...mapGetters(['getCharacterName', 'allStaminas', 'charactersWithIds']),

    characterIdsToDisplay() {
      if(this.showGivenCharacterIds) {
        return this.characterIds;
      }

      return this.ownedCharacterIds;
    },

    displayCharacters() {
      return this.charactersWithIds(this.characterIdsToDisplay).filter(Boolean);
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
  },

  watch: {
    async characterIdsToDisplay(characterIds) {
      await this.fetchCharacters(characterIds);
    }
  },

  methods: {
    ...mapActions(['fetchCharacters','fetchTotalRenameTags','renameCharacter','changeCharacterTraitLightning',
      'changeCharacterTraitEarth', 'changeCharacterTraitFire', 'changeCharacterTraitWater',
      'fetchTotalCharacterFireTraitChanges','fetchTotalCharacterEarthTraitChanges',
      'fetchTotalCharacterWaterTraitChanges', 'fetchTotalCharacterLightningTraitChanges']),

    getCharacterArt,

    saveFilters() {
      sessionStorage.setItem('character-levelfilter', this.levelFilter);
      sessionStorage.setItem('character-elementfilter', this.elementFilter);

      if(this.isMarket) {
        sessionStorage.setItem('character-price-order', this.priceSort);
        sessionStorage.setItem('character-price-minfilter', this.minPriceFilter);
        sessionStorage.setItem('character-price-maxfilter', this.maxPriceFilter);
      }
      this.$emit('character-filters-changed');
    },

    clearFilters() {
      sessionStorage.removeItem('character-levelfilter');
      sessionStorage.removeItem('character-elementfilter');
      if(this.isMarket) {
        sessionStorage.removeItem('character-price-order');
        sessionStorage.removeItem('character-price-minfilter');
        sessionStorage.removeItem('character-price-maxfilter');
      }

      this.elementFilter = '';
      this.levelFilter = '';
      this.priceSort = '';
      this.minPriceFilter = '';
      this.maxPriceFilter = '';

      this.$emit('character-filters-changed');
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
      this.options = [
        {
          name: 'Rename',
          amount: this.haveRename,
          handler: this.openRenameCharacter
        },
        {
          name: 'Change Trait',
          amount: this.totalTraitChanges,
          handler: this.openChangeTrait
        },
      ];
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
  },

  components: {
    CharacterArt,
    NftOptionsDropdown,
  },

  async mounted() {
    this.levelFilter = localStorage.getItem('character-levelfilter') || '';
    this.elementFilter = localStorage.getItem('character-elementfilter') || '';
    if(this.isMarket) {
      this.priceSort = sessionStorage.getItem('character-price-order') || '';
      this.minPriceFilter = sessionStorage.getItem('character-price-minfilter') || '';
      this.maxPriceFilter = sessionStorage.getItem('character-price-maxfilter') || '';
    }
    await this.loadConsumablesCount();
  }
};
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

.character-list {
  list-style-type: none;
  margin: 0;
  padding: 0;
  display: grid;
  padding: 0.5em;
  grid-template-columns: repeat(auto-fit, 14em);
  gap: 1.5em;
}

.character {
  position: relative;
  width: 14em;
  height: 25em;
  background-position: center;
  background-repeat: no-repeat;
  background-size: 115%;
  background-color: #2e2e30cc;
  background-image: url('../../assets/cardCharacterFrame.png');
  border: 1px solid #a28d54;
  border-radius: 15px;
  padding: 0.5rem;
  cursor: pointer;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  overflow: hidden;
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

.above-wrapper {
  position: absolute;
  top: 270px;
  left: 0;
  right: 0;
  z-index: 100;
  text-shadow: 0 0 5px #333, 0 0 10px #333, 0 0 15px #333, 0 0 10px #333;
}

.clear-filters-button {
  height: fit-content;
  display: flex;
  flex-direction: row;
  align-self: flex-end;
  margin:0 15px;
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
