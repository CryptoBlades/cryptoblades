<template>
  <div class="btn-wrap">
    <!--  router button  -->
    <router-link :to="{ name: route }" class="button" :class="size" v-if="route">
      <span>{{ mainText }}</span>
      <span class="sub">{{ subText }}</span>
    </router-link>
    <!-- normal button  -->
    <a href="#" class="button" :class="size" v-if="targetRef" @click="showTarget()">
      <span>{{ mainText }}</span>
      <span class="sub">{{ subText }}</span>
    </a>
  </div>
</template>

<script lang="ts">

export default {
  props: ['mainText', 'subText', 'disabled', 'route', 'size', 'targetRef'],
  methods : {
    showTarget(){
      this.$emit('click',this.targetRef);
    }
  }
};

</script>

<style scoped>
.btn-wrap {
  padding: 0 33px;
  display: inline-block;
}
.button {
  border-top: 1px solid #EDCD90;
  border-bottom: 1px solid #EDCD90;
  display: flex;
  align-items: center;
  justify-content: center;
  text-decoration: none;
  flex-direction: column;
  padding: 0 20px;
  position: relative;
  height: 60px;
  text-transform: uppercase;
}
.button span {
  font-size: 20px;
  line-height: 26px;
  font-family: Oswald;
  font-weight: 500;
  color: #fff;
  display: block;
}
.button span.sub {
  color: #EDCD90;
  font-family: Roboto;
  font-size: 16px;
}
.button:before,
.button:after {
  content: '';
  display: block;
  position: absolute;
  background: url("../assets/new-ui/btn/btn-left-border-sm.png") no-repeat;
  width: 33px;
  height: 60px;
  top: -1px;
  right: 100%;
}
.button:after {
  background: url("../assets/new-ui/btn/btn-right-border-sm.png") no-repeat;
  left: 100%;
}
.button.lg span,
.button.sm span {
  font-size: 25px;
  line-height: 30px;
}
.button.lg span.sub,
.button.sm span.sub {
  font-size: 16px;
}
.button.lg {
  height: 80px;
}
.button.lg:before {
  background: url("../assets/new-ui/btn/btn-left-border-lg.png") no-repeat;
  height: 80px;
}
.button.lg:after {
  background: url("../assets/new-ui/btn/btn-right-border-lg.png") no-repeat;
  left: 99.9%;
  height: 80px;
}

.button:disabled {
  opacity: 0.4 !important;
}

h1 {
  margin-top: 0;
  padding-top: 10px;
}

h2 {
  white-space: pre;
}

@media only screen and (min-width: 768px) {
  div.encounter.text-center button h2{
    font-size: x-large;
  }
}
@media only screen and (min-width: 992px) {
  div.encounter.text-center button h2{
    font-size: xx-large;
  }
}

/* Needed to asjust image size, not just image column-size and other classes to accommodate that */
@media all and (max-width:  767.98px) {
  .dark-bg-text{
    width: 75%;
  }
}
</style>
