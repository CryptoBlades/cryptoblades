<template>
  <div>
    <div class="filters row mt-2 pl-2" v-if="showFilters">
      <div class="col-2">
        <strong>Level</strong>
        <select class="form-control" v-model="levelFilter" @change="saveFilters()">
          <option v-for="x in ['', 1, 11, 21, 31, 41]" :value="x" :key="x">
            {{ x ? `${x} - ${x + 9}` : 'Any' }}
          </option>
        </select>
      </div>

      <div class="col-2">
        <strong>Element</strong>
        <select class="form-control" v-model="elementFilter" @change="saveFilters()">
          <option v-for="x in ['', 'Earth', 'Fire', 'Lightning', 'Water']" :value="x" :key="x">{{ x || 'Any' }}</option>
        </select>
      </div>
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
        <div class="art">
          <CharacterArt :character="c" />
        </div>
      </li>
    </ul>
  </div>
</template>

<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import Vue from 'vue';
import { getCharacterArt } from '../../character-arts-placeholder';
import CharacterArt from '../CharacterArt.vue';

Vue.directive('visible', (el, bind) => {
  el.style.visibility=(bind.value) ? 'visible' : 'hidden';});

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
    }
  },

  data() {
    return {
      levelFilter: '',
      elementFilter: ''
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
          items = items.filter(x => x.level >= this.levelFilter - 1 && x.level <= this.levelFilter + 9);
        }

        if(this.showLimit > 0 && items.length > this.showLimit) {
          items = items.slice(0, this.showLimit);
        }
      }

      return items;
    }
  },

  watch: {
    async characterIdsToDisplay(characterIds) {
      await this.fetchCharacters(characterIds);
    }
  },

  methods: {
    ...mapActions(['fetchCharacters']),

    getCharacterArt,

    getStaminaPoints(timestamp_str) {
      // super temporary function, just to make it work for now. sorry
      const timestamp = parseInt(timestamp_str, 10);
      const now = Date.now();
      if(timestamp  > now)
        return 0;

      let points = (now - timestamp) / 300;
      if(points > 200) {
        points = 200;
      }
      return points;
    },

    saveFilters() {
      localStorage.setItem('character-levelfilter', this.levelFilter);
      localStorage.setItem('character-elementfilter', this.elementFilter);
      this.$emit('character-filters-changed');
    }
  },

  components: {
    CharacterArt,
  },

  mounted() {
    this.levelFilter = localStorage.getItem('character-levelfilter') || '';
    this.elementFilter = localStorage.getItem('character-elementfilter') || '';
  }
};
</script>

<style scoped>
.character-list {
  list-style-type: none;
  margin: 0;
  padding: 0;
  display: grid;
  padding: 0.5em;
  grid-template-columns: repeat(auto-fit, 14em);
  gap: 0.5em;
}

.character {
  width: 12em;
  /* height: 20em; */
  background: rgba(255, 255, 255, 0.1);
  box-shadow: 0 2px 4px #ffffff38;
  border-radius: 5px;
  padding: 0.5rem;
  cursor: pointer;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
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
  outline: solid currentcolor 2px;
}

.above-wrapper {
  padding-bottom: 0.5rem;
}
</style>
