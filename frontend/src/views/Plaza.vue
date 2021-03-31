<template>
  <div class="body">
    <h1>Plaza</h1>
    <div class="character-list">
      <button @click="onMintCharacter">Mint new character</button>
      <character-list
        :value="currentCharacterId"
        @input="setCurrentCharacter"
      />
    </div>
    <div class="stamina-bar">
      <h2>Stamina</h2>
      <stamina-bar :current="currentCharacterStamina" :max="maxStamina" />
    </div>
    <div class="weapon-grid">
      <h2>Weapons</h2>
      <weapon-grid />
    </div>
    <div class="character-preview">
      <h2 class="character-name">{{ character.name }}</h2>
      <h3 class="character-sub">
        Level {{ character.level }} ({{ character.experience }} XP)
      </h3>
      <character class="character-inner" />
    </div>
  </div>
</template>

<script>
import StaminaBar from "../components/StaminaBar.vue";
import WeaponGrid from "../components/smart/WeaponGrid.vue";
import Character from "../components/Character.vue";
import CharacterList from "../components/smart/CharacterList.vue";
import { mapActions, mapGetters, mapMutations, mapState } from "vuex";

export default {
  computed: {
    ...mapState(["characters", "maxStamina", "currentCharacterId"]),
    ...mapGetters([
      "ownCharacters",
      "ownWeapons",
      "currentCharacter",
      "currentCharacterStamina",
    ]),

    character() {
      if (this.currentCharacter == null) {
        return {
          id: null,
          name: "???",
          level: -1,
          experience: -1,
        };
      }

      const c = this.currentCharacter;
      return {
        id: c.id,
        name: `Character #${c.id} (Appearance ${c.appearance})`,
        level: c.level,
        experience: c.xp,
      };
    },
  },

  methods: {
    ...mapMutations(["setCurrentCharacter"]),
    ...mapActions(["mintCharacter"]),

    async onMintCharacter() {
      try {
        await this.mintCharacter();
        console.log("Successful minting");
      } catch (e) {
        console.error("oh noes, an error when minting", e);
      }
    },
  },

  components: {
    StaminaBar,
    WeaponGrid,
    Character,
    CharacterList,
  },
};
</script>

<style scoped>
.body {
  display: grid;
  grid-template-columns: 23rem 1fr 23rem;
  grid-template-rows: auto;
  grid-template-areas: "header header header" "staminabar main characterlist" "weapongrid main characterlist" "empty2 main empty";
  column-gap: 1rem;
  row-gap: 0.5rem;
}

.character-list {
  grid-area: characterlist;
}

.stamina-bar {
  grid-area: staminabar;
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
  margin: 0;
}

.character-sub {
  margin: 0;
}

.character-inner {
  flex-grow: 1;
}
</style>
