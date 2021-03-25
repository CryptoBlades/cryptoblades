<template>
  <div>
    <ul>
      <li
        class="character-item"
        :class="{ selected: selectedCharacterId === c.id }"
        v-for="c in characters"
        :key="c.id"
      >
        <a @click="$emit('select', c)" :title="JSON.stringify(c, null, '  ')"
          >Character #{{ c.id }}</a
        >
      </li>
    </ul>
  </div>
</template>

<script>
export default {
  props: ["characters", "selectedCharacterId"],
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
