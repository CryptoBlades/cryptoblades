<template>
  <div>
    <button @click="setTab(0)">Arena</button>
    <button @click="setTab(1)">Leaderboard</button>
  </div>
</template>

<script>
export default {
  methods: {
    setTab(tabNumber) {
      this.$emit('changeTab', tabNumber);
    }
  }
};
</script>