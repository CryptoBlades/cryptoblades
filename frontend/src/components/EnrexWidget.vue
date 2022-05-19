<template>
  <div>
    <div id="badget-hover-box"></div>
      <div name="39d3428e-48c2-40c7-a06f-8c185a2437cb" side="right" id="badget">
        <div id="badget-box"></div>
      </div>
  </div>
</template>
<script>
export default {
  mounted() {
    const badget = document.createElement('script');
    badget.setAttribute('src', 'https://assets.enrex.io/badget/badget.js');
    document.head.appendChild(badget);
  },
};

</script>

<style scoped>
@import 'https://fonts.googleapis.com/css?family=Lato';
@import 'https://fonts.googleapis.com/css?family=Bebas%20Neue';
</style>
