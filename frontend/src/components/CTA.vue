<template>
  <div class="cta small-card" :class="ctaBg">
    <h2>{{ ctaTitle }}</h2>
    <p>{{ ctaDesc }}</p>
    <Button :main-text="btnText" :size="btnSize" :route="btnRoute"/>
  </div>
</template>

<script>
import Button from '@/components/Button';
export default {
  name: 'CTA',
  props: ['ctaBg','ctaTitle','ctaDesc','btnRoute','btnSize','btnText'],
  components : {Button},
};
</script>

<style scoped>
.cta {
  margin-bottom: 50px;
  padding: 40px;
  border-radius: 10px;
  border: 1px solid #404857;
  background: #404857 url('../assets/new-ui/background/bg-49.png') no-repeat center;
  background-size: cover;
}
.cta p {
  margin-bottom: 2.1rem;
}
.cta.adventure {
  background: #404857 url('../assets/new-ui/background/castle-crasher-4k-ri-1600x900.png') no-repeat center;

}
.cta.rank-match {
  background: #404857 url('../assets/new-ui/background/83484.png') no-repeat center;
}
</style>
