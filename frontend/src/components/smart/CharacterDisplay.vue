<template>
  <div class="character-display-container">
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
          Level {{ currentCharacter.level + 1 }} ({{ currentCharacter.xp }} / {{RequiredXp(currentCharacter.level).toLocaleString()}} XP)
        </span>
        <span v-if="!isLoadingCharacter" class="subtext">
          Power: {{CharacterPower(currentCharacter.level).toLocaleString()}}
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
          v-tooltip="toolTipHtml"
          faIcon="fa-bolt"
          primaryColor="#ec4b4b"
          altText="Stamina"
        />
      </div>
      <div class="character-list d-none d-sm-block">
      <ul class="character-list"
          v-bind:class="getIsInCombat ? 'disabled-li' : ''">
        <li
          class="character"
          v-for="c in filteredCharactersForList"
          :key="c.id"
          @click="!getIsInCombat && setCurrentCharacter(c.id)"
        >
        <div class="name-list"
        >{{ getCharacterName(c.id) }} Lv.{{ c.level + 1}}</div>
        </li>
      </ul>
      </div>
    </div>

    <div class="character-list-mobile" v-if="isMobile()">
      <ul>
        <li
          class="character"
          v-for="c in filteredCharactersForList"
          :key="c.id"
          @click="!getIsInCombat && setCurrentCharacter(c.id)"
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
      'getCharacterName',
      'charactersWithIds',
      'ownCharacters',
      'timeUntilCurrentCharacterHasMaxStamina',
      'getIsInCombat'
    ]),

    isLoadingCharacter(): boolean {
      return !this.currentCharacter;
    },

    toolTipHtml(): string {
      return 'Regenerates 1 point every 5 minutes, stamina bar will be full at: ' + this.timeUntilCurrentCharacterHasMaxStamina;
    },

    filteredCharactersForList(): any {
      let items: any  = this.ownCharacters;

      items = items.filter((x: any) => x.id !== this.currentCharacterId);

      if (items.length >= 4) items = items.filter((x: any) => x.id !== 0);

      return items;
    }
  },

  data() {
    return {
      traits: CharacterTrait,
      isPlaza : false
    };
  },
  methods: {
    ...mapMutations(['setCurrentCharacter']),
    getCharacterArt,
    CharacterPower,
    RequiredXp,
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
  cursor: pointer;
}

.name-list {
  bottom: 20px;
  margin: auto;
  float: left;
  font-size: 0.9em;
  text-align: center;
  color: #9e8a57;
}

.character-list-mobile {
  border-top: 3px solid #9e8a57;
  margin-top : 15px;
  padding-top: 15px;
  display :flex;
  flex-direction: column;
  justify-content: space-around;
  align-items: stretch;
}

.character-list-mobile > ul{
  padding :0px;
}
.character-list-mobile > ul > li{
  justify-content: center;
  display: flex;
}
.disabled-li {
  pointer-events: none;
  opacity: 0.6;
}
</style>
