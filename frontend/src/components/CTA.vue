<template>
  <div class="cta small-card">
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
  data() {
    return {
      styleObject: {
        color: 'red',
        fontSize: '13px',
        backgroundImage : 'url('+this.ctaBg+')'
      }
    };
  }
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
</style>
