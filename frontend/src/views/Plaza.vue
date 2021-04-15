<template>
  <div class="body main-font">
    <div class="container" v-if="ownCharacters.length > 0">
      <div class="character-list">
        <div class="character-header-wrapper">
          <h1>
            Characters
            <button class="mint-character" @click="onMintCharacter">
              <i class="fas fa-plus"></i>
            </button>
          </h1>

        </div>

        <character-list
          :value="currentCharacterId"
          @input="setCurrentCharacter"
        />
      </div>
      <div class="weapon-grid">
        <h1>Weapons</h1>

        <div v-if="ownWeapons.length > 0">
          <weapon-grid />
        </div>

        <div v-if="ownWeapons.length === 0">
          You do not have any weapons. You can forge one at the Blacksmith.
        </div>
      </div>
      <div class="character-preview">
        <h1 class="character-name">{{ character.name }}</h1>
        <h2 class="character-sub">
          Level {{ character.level + 1 }} ({{ character.experience }} XP)
        </h2>
        <character class="character-inner" :character="currentCharacter" />
      </div>
    </div>

    <div v-if="ownCharacters.length === 0" class="blank-slate">
      You do not have any characters.
      <br>
      You can recruit one by clicking the button below.
      <br>
      <br>
      <big-button
        class="button"
        mainText="Recruit character"
        @click="onMintCharacter"
      />
    </div>
  </div>
</template>

<script>
import BigButton from '../components/BigButton.vue';
import WeaponGrid from '../components/smart/WeaponGrid.vue';
import Character from '../components/Character.vue';
import CharacterList from '../components/smart/CharacterList.vue';
import { mapActions, mapGetters, mapMutations, mapState } from 'vuex';

export default {
  computed: {
    ...mapState(['characters', 'maxStamina', 'currentCharacterId']),
    ...mapGetters([
      'ownCharacters',
      'ownWeapons',
      'currentCharacter',
      'currentCharacterStamina',
      'getCharacterName',
    ]),

    character() {
      if (this.currentCharacter == null) {
        return {
          id: null,
          name: '???',
          level: -1,
          experience: -1,
        };
      }

      const c = this.currentCharacter;
      return {
        id: c.id,
        name: this.getCharacterName(c.id),
        level: c.level,
        experience: c.xp,
      };
    },
  },

  methods: {
    ...mapMutations(['setCurrentCharacter']),
    ...mapActions(['mintCharacter']),

    async onMintCharacter() {
      try {
        await this.mintCharacter();
      } catch (e) {
        alert('Could not mint character: insufficient funds or transaction denied.');
      }
    },
  },

  components: {
    BigButton,
    WeaponGrid,
    Character,
    CharacterList,
  },
};
</script>

<style scoped>
.container {
  display: grid;
  grid-template-columns: 23rem 1fr 23rem;
  grid-template-rows: auto;
  grid-template-areas: "weapongrid main characterlist";
  column-gap: 4rem;
  row-gap: 0.5rem;
}

.character-list {
  grid-area: characterlist;
}

.character-header-wrapper {
  display: flex;
  align-items: center;
}

.character-header-wrapper h1 {
  flex-grow: 1;
}

.character-header-wrapper .mint-character {
  height: 2.5rem;
  width: 2.5rem;
  font-size: 1.3rem;
  color: rgba(255, 255, 255, 0.6);
  background: none;
  border: none;
  border-radius: 0.1em;

  float: right;
}

.character-header-wrapper .mint-character:hover {
  color: white;
  background: rgba(255, 255, 255, 0.25);
}

.weapon-grid {
  grid-area: weapongrid;
}

.character-preview {
  grid-area: main;
  display: flex;
  flex-direction: column;
  min-height: 24rem;
}

.character-name {
  margin-bottom: 0;
}

.character-sub {
  margin-top: 0;
  opacity: 80%;
}

.character-inner {
  flex-grow: 1;
  min-height: 30em;
}
</style>
