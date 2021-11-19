<template>
  <main>
    <SideBar />
    <MainContent />
  </main>
</template>

<script>
import SideBar from '@/components/SideBar';
import MainContent from '@/components/MainContent';

export default {
  name: 'Main',
  components : {
    SideBar,
    MainContent
  },
};
</script>

<style scoped>
/*Main*/
main {
  display: flex;
  flex-wrap: wrap;
  flex-direction: row;
  background: #000E29;
}
</style>
