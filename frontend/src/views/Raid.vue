<template>
  <div class="main-content">
    <RaidBanner />
    <RaidTab />
    <CharacterNav />
 </div>
</template>
<script>
import RaidBanner from '@/components/raid/Banner';
import CharacterNav from '@/components/raid/CharacterNav';
import RaidTab from '@/components/raid/RaidTab';
export default {
  name: 'Home',
  components : {
    RaidBanner,
    RaidTab,
    CharacterNav
  }
};
</script>
