import Vue from 'vue';

export default Vue.mixin({
  methods: {
    isMobile() {
      return screen.width <= 576;
    }
  }
});
