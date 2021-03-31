<template>
  <div class="root main-font">
    <div
      class="character-portrait"
      :title="JSON.stringify(currentCharacter, null, '  ')"
    >
      <img src="../../assets/chara.png" alt="Placeholder character" />
    </div>

    <div class="character-data-column dark-bg-text">
      <span class="name bold">Character #{{ currentCharacter.id }}</span>
      <span class="subtext">
        Level {{ currentCharacter.level }} ({{ currentCharacter.xp }} XP)
      </span>
      <span class="subtext">Power: 9001</span>
      <small-bar
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
    ...mapState(["maxStamina"]),
    ...mapGetters(["currentCharacter", "currentCharacterStamina"]),
  },
};
</script>

<style scoped>
.root {
  padding: 5px;
  display: flex;
}

.character-portrait {
  width: 120px;
  height: 120px;
  background: gray;
  display: flex;
  justify-content: center;
  align-content: center;
  border: 4px purple inset;
  margin-right: 10px;
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
