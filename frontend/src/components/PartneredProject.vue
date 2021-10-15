<template>
  <div class="partner-div ml-4 mr-4 mb-4 mt-4">
    <div class="d-flex flex-row">
      <img :src="imgPath(logoFileName)" class="partner-logo"/>
      <div class="d-flex flex-column justify-content-center">
        <h4>{{name}}</h4>
        <h6>Token: {{tokenSymbol}}</h6>
      </div>
    </div>
    <div class="progress w-90 justify-items-center">
      <div class="progress-bar progress-bar-striped progress-bar-animated" role="progressbar"
        :style="[{'width': progressBarWidth, 'background-color': '#9e8a57'}]"/>
    </div>
    <h6 class="text-center">Claimed {{tokensClaimed}} / {{tokenSupply}}</h6>
 </div>
</template>

<script lang='ts'>
import Vue from 'vue';

export default Vue.extend({
  props: {
    name: {
      type: String,
      default: '',
    },
    logoFileName: {
      type: String,
      default: '',
    },
    tokenSymbol: {
      type: String,
      default: '',
    },
    tokenSupply: {
      type: String,
      default: '0',
    },
    tokensClaimed: {
      type: String,
      default: '0',
    },
  },

  data() {
    return {
      images: require.context('../assets/partners/', false, /\.png$/)
    };
  },

  computed: {
    progressBarWidth(): string {
      if(!this.tokenSupply) return '0%';
      return `${Math.round((+this.tokensClaimed / +this.tokenSupply) * 100)}%`;
    },
  },

  methods: {
    imgPath(img: string): string {
      return this.images('./' + img);
    }
  }
});

</script>

<style scoped>
.partner-div {
  width: 210px;
  height: 140px;
  border: 2px solid #9e8a57;
  border-radius: 10px;
  padding: 5px;
  background: linear-gradient(45deg, rgba(20,20,20,1) 0%, rgba(36,39,32,1) 100%);
}
.partner-logo {
  width: 90px;
  height: 90px;
}
</style>
