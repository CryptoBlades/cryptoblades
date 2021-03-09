<template>
  <div>
    <h1>Combat</h1>
    <ul class="encounter-list">
      <li v-for="e in possibleEncounters" :key="e.id">
        <character />
        <big-button
          class="encounter-button"
          :mainText="e.difficulty"
          :subText="'lvl ' + e.levelRange[0] + '-' + e.levelRange[1]"
          @click="$emit('encounter-click', e)"
        />
      </li>
    </ul>
  </div>
</template>

<script>
import Character from "../components/Character.vue";
import BigButton from "../components/BigButton.vue";

export default {
  data() {
    return {
      possibleEncounters: [
        { id: 1, difficulty: "easy", levelRange: [9, 11] },
        { id: 2, difficulty: "medium", levelRange: [11, 13] },
        { id: 3, difficulty: "challenging", levelRange: [14, 16] },
        { id: 4, difficulty: "hard", levelRange: [17, 20] },
      ],
    };
  },

  components: {
    Character,
    BigButton,
  },
};
</script>

<style scoped>
.encounter-list {
  list-style-type: none;
  display: flex;
  margin: 0;
  padding: 0;
  justify-content: space-around;
}

.encounter-button {
  width: 8cm;
}
</style>
