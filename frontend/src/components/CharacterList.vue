<template>
  <div>
    <button @click="$emit('mintCharacter')">Mint new character</button>
    <ul>
      <li v-for="c in characters" :key="c.id">
        <a @click="$emit('select', c)" :title="JSON.stringify(c, null, '  ')">Character #{{ c.id }}</a>
      </li>
    </ul>
  </div>
</template>

<script>
export default {
  props: ["characters"],
};
</script>

<style>
</style>
