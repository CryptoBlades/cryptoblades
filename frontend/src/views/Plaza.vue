<template>
  <div class="body">
    <h1>Plaza</h1>
    <character-list
      class="character-list"
      :characters="characters"
      @mintCharacter="$emit('mintCharacter')"
      @select="$emit('selectCharacter', $event)"
    />
    <stamina-bar
      class="stamina-bar"
      :current="stamina.current"
      :max="stamina.max"
    />
    <weapon-grid class="weapon-grid" :weapons="weapons" />
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

export default {
  props: ["character", "characters", "weapons", "stamina"],
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
