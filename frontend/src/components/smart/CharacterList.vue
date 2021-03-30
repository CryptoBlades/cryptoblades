<template>
  <div>
    <ul>
      <li
        class="character-item"
        :class="{ selected: value === c.id }"
        v-for="c in ownCharacters"
        :key="c.id"
      >
        <a @click="$emit('input', c.id)" :title="JSON.stringify(c, null, '  ')"
          >Character #{{ c.id }}</a
        >
      </li>
    </ul>
  </div>
</template>

<script>
import { mapGetters } from "vuex";

export default {
  props: ["value"],

  computed: {
    ...mapGetters(["ownCharacters"]),
  },
};
</script>

<style scoped>
.character-item {
  cursor: pointer;
}

.character-item.selected {
  background: orange;
}
</style>
