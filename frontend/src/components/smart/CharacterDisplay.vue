<template>
  <div class="root main-font">
    <div
      class="character-portrait"
      :title="JSON.stringify(currentCharacter, null, '  ')"
    >
      <img
        v-if="!isLoadingCharacter"
        src="../../assets/chara.png"
        alt="Placeholder character"
      />
      <span v-if="isLoadingCharacter">Loading...</span>
    </div>

    <div class="character-data-column dark-bg-text">
      <span v-if="!isLoadingCharacter" class="name bold"
        >Character #{{ currentCharacter.id }}</span
      >
      <span v-if="isLoadingCharacter" class="name bold">Loading...</span>
      <span v-if="!isLoadingCharacter" class="subtext">
        Level {{ currentCharacter.level }} ({{ currentCharacter.xp }} XP)
      </span>
      <span v-if="!isLoadingCharacter" class="subtext">Power: 9001</span>
      <small-bar
        v-if="!isLoadingCharacter"
        class="bar stamina"
        :current="currentCharacterStamina"
        :max="maxStamina"
        faIcon="fa-bolt"
        primaryColor="#ec4b4b"
        altText="Stamina"
      />
    </div>
  </div>
</template>

<script>
import { mapGetters, mapState } from "vuex";
import SmallBar from "../SmallBar.vue";

export default {
  components: {
    SmallBar,
  },

  computed: {
    ...mapState(["maxStamina", "currentCharacterId"]),
    ...mapGetters(["currentCharacter", "currentCharacterStamina"]),

    isLoadingCharacter() {
      return this.currentCharacter == null;
    },
  },
};
</script>

<style scoped>
.root {
  display: inline-flex;
}

.character-portrait {
  width: 7.5em;
  height: 7.5em;
  background: gray;
  display: flex;
  justify-content: center;
  align-items: center;
  border: 4px purple inset;
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
  opacity: 90%;
}

.character-data-column .bar {
  height: 1rem;
}
</style>
