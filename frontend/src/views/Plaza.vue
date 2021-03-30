<template>
  <div class="body">
    <h1>Plaza</h1>
    <div class="character-list">
      <button @click="onMintCharacter">Mint new character</button>
      <character-list
        :characters="ownCharacters"
        :selectedCharacterId="character.id"
        @select="onSelectCharacter"
      />
    </div>
    <div class="stamina-bar">
      <h2>Stamina</h2>
      <stamina-bar :current="stamina.current" :max="stamina.max" />
    </div>
    <div class="weapon-grid">
      <h2>Weapons</h2>
      <weapon-grid :weapons="ownWeapons" />
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
import WeaponGrid from "../components/WeaponGrid.vue";
import Character from "../components/Character.vue";
import CharacterList from "../components/CharacterList.vue";
import { mapActions, mapGetters, mapState } from "vuex";

export default {
  data() {
    return {
      currentCharacterId: null,
      now: Date.now(),
    };
  },

  computed: {
    ...mapState(["characters", "characterStaminas", "maxStamina"]),
    ...mapGetters(["ownCharacters", "ownWeapons"]),

    currentCharacter() {
      if (this.currentCharacterId == null) return null;

      return this.characters[this.currentCharacterId];
    },

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

    stamina() {
      const currentStamina =
        this.currentCharacterId == null
          ? 0
          : this.characterStaminas[this.currentCharacterId];
      return { current: currentStamina, max: this.maxStamina };
    },

    nowAndCurrentCharacterId() {
      return [this.now, this.currentCharacterId];
    },
  },

  watch: {
    async nowAndCurrentCharacterId(data) {
      const currentCharacterId = data[1];

      if (currentCharacterId != null) {
        await this.fetchCharacterStamina(currentCharacterId);
      }
    },
  },

  methods: {
    ...mapActions(["mintCharacter", "fetchCharacterStamina"]),

    onSelectCharacter(chara) {
      this.currentCharacterId = chara.id;
    },

    async onMintCharacter() {
      try {
        await this.mintCharacter();
        console.log("Successful minting");
      } catch (e) {
        console.error("oh noes, an error when minting", e);
      }
    },
  },

  created() {
    this.nowInterval = setInterval(() => {
      this.now = Date.now();
    }, 3000);
  },

  beforeDestroy() {
    clearInterval(this.nowInterval);
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
  grid-template-columns: 10cm 1fr 10cm;
  grid-template-rows: auto;
  grid-template-areas: "header header header" "staminabar main characterlist" "weapongrid main characterlist" "empty2 main empty";
  column-gap: 0.5cm;
  row-gap: 0.2cm;
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
  min-height: 10cm;
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
