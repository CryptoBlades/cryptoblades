<template>
  <b-navbar toggleable="sm" type="dark" variant="dark">
    <b-navbar-brand href="#">
      <img src="../assets/logo.png" class="logo d-inline-block align-top" alt="Logo">
    </b-navbar-brand>

    <view-links></view-links>

    <skill-balance-display class="ml-auto" />

    <claim-rewards />

    <options />
  </b-navbar>
</template>

<script lang="ts">
import ViewLinks from './ViewLinks.vue';
import Options from './Options.vue';
import SkillBalanceDisplay from './smart/SkillBalanceDisplay.vue';
import ClaimRewards from './smart/ClaimRewards.vue';

export default {
  components: {
    ViewLinks,
    SkillBalanceDisplay,
    ClaimRewards,
    Options
  },
};
</script>

<style>
a {
  text-decoration: none;
  user-select: none;
  color: #b3b0a7 !important;
}

a:hover,
a.router-link-active {
  color: #f2e3bc;
  text-shadow: 0 0 5px #333, 0 0 10px #333, 0 0 15px #e1bb34, 0 0 10px #e1bb34;
  text-decoration: none !important;
}

.dropdown-menu {
  background: rgb(20,20,20);
  background: linear-gradient(45deg, rgba(20,20,20,1) 0%, rgba(36,39,32,1) 100%);
  border: none !important;
}

.dropdown-menu li a:hover {
  background: transparent !important;
}
</style>

<style scoped>
.logo {
  max-width: 130px;
  padding-top: 7px;
}

.navbar {
  background: rgb(20,20,20);
  background: linear-gradient(45deg, rgba(20,20,20,1) 0%, rgba(36,39,32,1) 100%);
}
</style>
