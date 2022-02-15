<template>
  <header>
    <div class="branding">
      <a href="#/"><img src="../assets/logo_Text_Source.png" class="logo d-inline-block align-top" alt="Logo"></a>
    </div>
    <HeaderNav />
    <HeaderBurgerMenu />
  </header>
</template>

<script>
import HeaderNav from '@/components/HeaderNav';
import HeaderBurgerMenu from '@/components/HeaderBurgerMenu';

export default {
  name: 'Header',
  components : {
    HeaderNav,
    HeaderBurgerMenu
  }
};
</script>

<style scoped>
header {
  display: flex;
  flex-direction: row;
  background: #000E29;
  border-bottom: 1px solid #404857;
}
header .branding {
  width: 380px;
  border-right: 1px solid #404857;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 36px 50px;
}
header .branding img {
  width: 267px;
}
</style>
