<template>
  <b-navbar-nav>
    <b-nav-item-dropdown right>
      <template #button-content>
        Options
      </template>

      <b-dropdown-item
        @click="toggleGraphics()">3D Graphics: {{ hideGraphics ? 'Off' : 'On' }}</b-dropdown-item>

    </b-nav-item-dropdown>
  </b-navbar-nav>
</template>

<script>
export default {

  created() {
    this.hideGraphics = !!localStorage.getItem('graphics');
  },

  data() {
    return {
      hideGraphics: this.hideGraphics
    };
  },

  methods: {
    toggleGraphics() {
      this.hideGraphics = !this.hideGraphics;
      if(this.hideGraphics) localStorage.setItem('graphics', 'off');
      else                  localStorage.removeItem('graphics');
    }
  }
};
</script>

<style scoped>
</style>
