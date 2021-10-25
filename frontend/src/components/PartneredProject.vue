<template>
  <div class="partner-div ml-4 mr-4 mb-4 mt-4">
    <div class="d-flex flex-row">
      <img :src="imgPath(logoFileName)" class="partner-logo"/>
      <div class="d-flex flex-column justify-content-center">
        <h4>{{name}}</h4>
        <h6>Token: {{tokenSymbol}}</h6>
        <span class="multiplier-text">{{skillToPartnerRatio}} SKILL/{{tokenSymbol}}</span>
        <span class="multiplier-text">Multiplier: x{{multiplier}}</span>
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
import { mapActions } from 'vuex';
import { toBN } from '@/utils/common';

interface Data {
  images: any;
  multiplier: string;
  tokensClaimed: string;
  skillToPartnerRatio: string;
  updateInterval: any;
}

export default Vue.extend({
  props: {
    id: {
      type: String,
      default: '',
    },
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
    tokenPrice: {
      type: String,
      default: '0',
    },
  },

  data() {
    return {
      images: require.context('../assets/partners/', false, /\.png$/),
      multiplier: '1',
      tokensClaimed: '0',
      skillToPartnerRatio: '0',
      updateInterval: null
    } as Data;
  },

  computed: {
    progressBarWidth(): string {
      if(!this.tokenSupply) return '0%';
      return `${Math.round((+this.tokensClaimed / +this.tokenSupply) * 100)}%`;
    },
  },

  methods: {
    ...mapActions(['getPartnerProjectMultiplier', 'getPartnerProjectClaimedAmount', 'getSkillToPartnerRatio']),
    imgPath(img: string): string {
      return this.images('./' + img);
    },

    async update(): Promise<void> {
      const currentMultiplier = await this.getPartnerProjectMultiplier(this.id);
      this.multiplier = toBN(currentMultiplier).div(toBN(10).pow(18)).toFixed(3);

      const currentClaimedTokens = await this.getPartnerProjectClaimedAmount(this.id);
      this.tokensClaimed = toBN(currentClaimedTokens).div(toBN(10).pow(18)).toFixed(2);

      const currentSkillToPartnerRatio = await this.getSkillToPartnerRatio(this.id);
      this.skillToPartnerRatio = toBN(1).dividedBy(toBN(currentSkillToPartnerRatio).dividedBy(toBN(2).exponentiatedBy(64))).toFixed(2);
    }
  },

  async created() {
    await this.update();
    this.updateInterval = setInterval(async () => { this.update(); }, 10000);
  },

  beforeDestroy() {
    clearInterval(this.updateInterval);
  }
});

</script>

<style scoped>
.partner-div {
  width: 240px;
  height: 160px;
  border: 2px solid #9e8a57;
  border-radius: 10px;
  padding: 5px;
  background: linear-gradient(45deg, rgba(20,20,20,1) 0%, rgba(36,39,32,1) 100%);
}
.partner-logo {
  width: 90px;
  height: 90px;
}
.multiplier-text {
  font-size: 0.8rem;
}
</style>
