<template>
  <ul class="character-list">
    <li
      class="character"
      :class="{ selected: value === c.id }"
      v-for="c in ownCharacters"
      :key="c.id"
      v-tooltip="tooltipHtml(c)"
      @click="$emit('input', c.id)"
    >
      <div class="art">
        <CharacterArt :character="c" />
      </div>
      <div class="name-wrapper">
        <span class="name">{{ getCharacterName(c.id) }}</span>
      </div>
    </li>
  </ul>
</template>

<script lang="ts">
import { mapGetters } from 'vuex';
import { getCharacterArt } from '../../character-arts-placeholder';
import { ICharacter } from '../../interfaces';
import CharacterArt from '../CharacterArt.vue';

export default {
  props: ['value'],

  computed: {
    ...mapGetters(['ownCharacters', 'getCharacterName']),
  },

  methods: {
    getCharacterArt,
    tooltipHtml(character: ICharacter) {
      if(!character) return '';

      return `
        Level ${character.level}
        <br>
        XP ${character.xp}
        <br>
        Trait ${character.trait}
        <br>
        Stamina ${character.staminaTimestamp}
      `;
    }
  },

  components: {
    CharacterArt,
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
  height: 20em;
  background: rgba(255, 255, 255, 0.1);
  box-shadow: 0 2px 4px #ffffff38;
  border-radius: 5px;
  padding: 0.5em;
  cursor: pointer;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
}

.character .art {
  width: 100%;
  height: 100%;
  background-position: center;
  background-repeat: no-repeat;
  background-size: contain;
}

.valign-middle {
  vertical-align: middle;
}

.character .name-wrapper {
  height: 3em;
  display: flex;
  justify-content: center;
  align-items: center;
}

.character .name {
  font-size: 0.9em;
  text-align: center;
}

.character img {
  object-fit: contain;
}

.character.selected {
  outline: solid currentcolor 2px;
}
</style>
