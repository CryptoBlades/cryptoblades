<template>
  <div class="main-content">
    <Banner />
    <HomeCards />
  </div>
</template>

<script>
import Banner from '@/components/Banner';
import HomeCards from '@/components/HomeCards';
export default {
  name: 'Home',
  components : {
    Banner,
    HomeCards
  }
};
</script>

<style>

</style>
