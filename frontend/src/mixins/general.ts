import Vue from 'vue';

Vue.mixin({
  methods: {
    isMobile() {
      if( screen.width <= 576 ) {
        return true;
      }
      else {
        return false;
      }
    }
  }
});
