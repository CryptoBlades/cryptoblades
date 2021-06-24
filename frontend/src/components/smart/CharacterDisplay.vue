<template>
  <div class="root main-font">
    <div
      class="character-portrait"
    >
      <!--img
        v-if="!isLoadingCharacter"
        :src="getCharacterArt(currentCharacter)"
        alt="Placeholder character"
      /-->
      <CharacterArt
        v-if="!isLoadingCharacter"
        :character="currentCharacter"
        :portrait="true" />
      <span v-if="isLoadingCharacter" style="position: relative">
        <div class="loading-container">
          <i class="fas fa-spinner fa-spin"></i>
        </div>
      </span>
    </div>

    <div class="character-data-column dark-bg-text">
      <span v-if="!isLoadingCharacter" class="name bold"><span :class="traits[currentCharacter.trait].toLowerCase() + '-icon'"></span> {{
        getCharacterName(currentCharacterId)
      }}</span>
      <span v-if="isLoadingCharacter" class="name bold">Loading...</span>
      <span v-if="!isLoadingCharacter" class="subtext">
        Level {{ currentCharacter.level + 1 }} ({{ currentCharacter.xp }} / {{RequiredXp(currentCharacter.level)}} XP)
      </span>
      <span v-if="!isLoadingCharacter" class="subtext">
        Power: {{CharacterPower(currentCharacter.level)}}
        <Hint class="power-hint" text="Power increases by 10 every level up,
          <br>and multiplied every 10 level ups
          <br>Level 1: 1000
          <br>Level 10: 1090
          <br>Level 11: 2200
          <br>Level 20: 2380
          <br>Level 21: 3600" />
      </span>
      <small-bar
        v-if="!isLoadingCharacter"
        class="bar stamina"
        :current="currentCharacterStamina"
        :max="maxStamina"
        v-tooltip="'Regenerates 1 point every 5 minutes'"
        faIcon="fa-bolt"
        primaryColor="#ec4b4b"
        altText="Stamina"
      />
    </div>
	<div class="character-list">
    <ul class="character-list">
<!--:class="{ selected: value === c.id }"-->
      <li
        class="character"
        v-for="c in filteredCharactersForList"
        :key="c.id"
        @click="setCurrentCharacter(c.id)"
      >
      <div class="name-list"
      >{{ getCharacterName(c.id) }} Lv.{{ c.level + 1}}</div>
      </li>
    </ul>
	</div>
  </div>
</template>

<script lang="ts">
import { mapGetters, mapState, mapMutations } from 'vuex';
import { getCharacterArt } from '../../character-arts-placeholder';
import SmallBar from '../SmallBar.vue';
import CharacterArt from '../CharacterArt.vue';
import { CharacterPower, CharacterTrait } from '../../interfaces';
import { RequiredXp } from '../../interfaces';
import Hint from '../Hint.vue';

export default {
  components: {
    CharacterArt,
    SmallBar,
    Hint,
  },

  computed: {
    ...mapState(['maxStamina', 'currentCharacterId', 'ownedCharacterIds']),
    ...mapGetters([
      'currentCharacter',
      'currentCharacterStamina',
      'getCharacterName', 'charactersWithIds'
    ]),
    isLoadingCharacter(): boolean {
      return !this.currentCharacter;
    },
    displayCharacters() {
      return this.charactersWithIds(this.ownedCharacterIds).filter(Boolean);
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
    },

    filteredCharactersForList() {
      let items = this.displayCharacters;

      items = items.filter(x => x.id !== this.currentCharacter.id);
      return items;
    }
  },

  data() {
    return {
      traits: CharacterTrait
    };
  },

  methods: {
    ...mapMutations(['setCurrentCharacter']),
    getCharacterArt,
    CharacterPower,
    RequiredXp,
    say(id, variable) {
      //alert(message);
      this[variable] = id;
    },
  },
};
</script>

<style scoped>
.root {
  display: inline-flex;
  width: 100%;
}

.character-portrait {
  width: 7.5em;
  height: 7.5em;
  background: gray;
  display: flex;
  justify-content: center;
  align-items: center;
  border: 4px rgba(0, 0, 0, 0.5) inset;
  background: url("../../assets/chara-bg.png") center bottom -4px no-repeat;
  background-size: auto 140%;
  background-clip: border-box;
  margin-right: 0.625em;
}

.character-portrait img {
  max-height: 100%;
  max-width: 100%;
}

.character-data-column {
  display: flex;
  flex-direction: column;
}

.character-data-column > * + * {
  margin-top: 0.375rem;
}

.character-data-column .name {
  font-size: 1.1rem;
}

.character-data-column .subtext {
  font-size: 0.9rem;
  opacity: 0.9;
}

.character-data-column .bar {
  height: 1rem;
}

.power-hint {
  font-size: 1.3rem;
}

div.character-list{
  width: 70%;
}

ul.character-list{
  float: right;
  margin: 0px;
}

li.character{
    background: rgba(255, 255, 255, 0.1);
    padding: 7px 4px 2px;
    margin: 5px;
    vertical-align: middle;
}

.name-list {
  bottom: 20px;
  margin: auto;
  float: left;
  font-size: 0.9em;
  text-align: center;
  color: #9e8a57;
}
</style>
