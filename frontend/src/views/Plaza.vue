<template>
  <div class="body main-font">
    <div class="character-list">
      <button @click="onMintCharacter">Mint new character</button>
      <character-list
        :value="currentCharacterId"
        @input="setCurrentCharacter"
      />
    </div>
    <div class="weapon-grid">
      <h1 class="">Weapons</h1>
      <weapon-grid />
    </div>
    <div class="character-preview">
      <h1 class="character-name">{{ character.name }}</h1>
      <h2 class="character-sub">
        Level {{ character.level }} ({{ character.experience }} XP)
      </h2>
      <character class="character-inner" />
    </div>
  </div>
</template>

<script>
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
  grid-template-areas: "weapongrid main characterlist";
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
  margin-bottom: 0;
}

.character-sub {
  margin-top: 0;
  opacity: 80%;
}

.character-inner {
  flex-grow: 1;
}
</style>
