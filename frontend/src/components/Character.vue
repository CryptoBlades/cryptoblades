<template>
  <div class="wrapper">
    <!-- <img src="../assets/chara.png" alt="Placeholder character"> -->
    <div class="image"></div>
  </div>
</template>

<script>
export default {};
</script>

<style>
.wrapper {
  margin: 0;
  display: flex;
  justify-content: center;
  align-content: center;
  background: url("../assets/chara-bg.png") center bottom no-repeat;
  padding: 5em;
  padding-bottom: 1em;
}

.image {
  height: 100%;
  width: 100%;
  background: url("../assets/chara.png") center no-repeat;
  background-size: contain;
}
</style>
