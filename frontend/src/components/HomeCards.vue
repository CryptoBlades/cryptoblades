<template>
  <div class="cards">
    <div class="content-wrap">
      <div class="lcard">
        <HomeRaidCard />
      </div>
      <div class="rcard">
        <CTA
          cta-bg="adventure"
          cta-title="Adventure"
          cta-desc="Engage on PVE battles to earn rewards."
          btn-text="Combat"
          btn-route="combat"
          btn-size="m"
        />
        <CTA
          cta-bg="rank-match"
          cta-title="Rank Match"
          cta-desc="Defeat other Players on PVP battles to earn rewards."
          btn-text="Sign Up"
          btn-route="sign-up"
          btn-size="m"
        />
      </div>
    </div>
  </div>
</template>

<script>
import HomeRaidCard from '@/components/HomeRaidCard';
import CTA from '@/components/CTA';
export default {
  name: 'HomeCards',
  components: { HomeRaidCard, CTA}
};
</script>

<style scoped>
.cards {
  margin-top: -250px;
}
.content-wrap > div:first-child {
  flex-grow: 1;
}
.content-wrap > div:last-child {
  max-width: 550px;
  width: 100%;
  padding-left: 50px;
}
.content-wrap .card-item {
  border-radius: 10px;
  border: 1px solid #404857;
  background-size: cover;
}
</style>
