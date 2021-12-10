<template>
  <section>
    <router-view />
  </section>
</template>

<script>
export default {
  name: 'MainContent',
  components : {

  }
};
</script>
<style>
  h2 {
    font-family: 'Trajan';
    font-size: 25px;
    color: #EDCD90;
    font-weight: bold;
  }
  .content-wrap {
    display: flex;
    width: 100%;
    justify-content: space-between;
    padding: 40px 40px 40px 60px;
  }

  .icon-frame-sm {
    background: url("../assets/new-ui/icon-rect-small.png") no-repeat;
    background-size: contain;
    width: 48px;
    height: 48px;
    display: flex;
    align-items: center;
    justify-content: center;
    margin-bottom: 12px;
  }
  .icon-frame-sm img {
    width: 18px;
  }
  .icon-frame-sm.active {
    background: url("../assets/new-ui/icon-rect-small-active.png") no-repeat;
  }

  .char-progress-bar {
    height: 5px;
    display: block;
    background: #817D6D;
    position: relative;
    max-width: 360px;
    width: 100%;
    margin-bottom: 23px;
  }
  .char-progress-bar .percent {
    display: block;
    position: absolute;
    width: 50%;
    height: 5px;
    background: #EDCD90;
    left: 0;
    top: 0;
  }
</style>
<style scoped>
  .main-content {
    flex-grow: 1;
    display: flex;
    min-height: 90vh;
    flex-direction: column;
    position: relative;
  }

  section {
    flex-grow: 1;
  }
</style>
