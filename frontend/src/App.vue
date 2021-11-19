<template>
  <div class="app">
    <Header />
    <Main />
  </div>
</template>

<script>
import Header from './components/Header';
import Main from './components/Main';

export default {
  name: 'App',
  components : {
    Header,
    Main
  },
};

</script>
