<template>
  <div class="burger-nav">
    <a href="#"><img src="../assets/new-ui/icon-burger-menu.png" class="logo d-inline-block align-top" alt="burger-menu"></a>
  </div>
</template>

<script>
export default {
  name: 'HeaderNav',
  components : {
  },
};
</script>

<style scoped>
.burger-nav {
  display: flex;
  width: 110px;
  align-items: center;
  justify-content: center;
  border-left: 1px solid #404857;
}
</style>
