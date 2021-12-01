<template>
  <div class="partner-div m-4">
    <div class="d-flex">
      <img :src="partnerLogoPath" class="partner-logo"/>
      <div class="d-flex flex-column justify-content-center ml-2">
        <h4 class="d-flex align-items-center partner-name">{{name}}</h4>
        <div class="d-flex">
          <h6>Token: {{tokenSymbol}}</h6>
          <a @click="addTokenToMetamask" class="ml-1 add-token-button">(Add)</a>
        </div>
        <span class="multiplier-text">{{skillToPartnerRatio}} SKILL/{{tokenSymbol}}</span>
        <span class="multiplier-text">Multiplier: x{{multiplier}}</span>
      </div>
    </div>
    <div class="mt-1 progress w-90 justify-items-center">
      <div class="progress-bar progress-bar-striped progress-bar-animated" role="progressbar"
        :style="[{'width': progressBarWidth, 'background-color': '#9e8a57'}]"/>
    </div>
    <h6 class="mt-1 text-center">Claimed {{tokensClaimed}} / {{tokenSupply}}</h6>
    <div class="d-flex flex-column align-items-center w-100">
      <b-card no-body class="collapse-style" v-bind:class="detailsOpened ? 'on-top' : ''">
        <b-card-header class="d-flex flex-column align-items-center w-100 mt-1 p-0" v-b-toggle="'collapse-' + id" @click="toggleDetails()">
          <h6 class="when-open">Less...</h6><h6 class="when-closed">More...</h6>
        </b-card-header>
        <b-collapse :id="'collapse-' + id">
          <b-card-body>
            <b-card-text>{{partnerDetails}}</b-card-text>
          </b-card-body>
        </b-collapse>
      </b-card>
    </div>
 </div>
</template>

<script lang='ts'>
import Vue from 'vue';
import { mapActions } from 'vuex';
import { addTokenToMetamask, toBN } from '@/utils/common';
import partnersInfo from '../../partners.json';

export interface PartnersInfo {
  partners: Record<string, Record<string, any>>;
}

interface Data {
  images: any;
  multiplier: string;
  tokensClaimed: string;
  skillToPartnerRatio: string;
  updateInterval: ReturnType<typeof setInterval> | null;
  detailsOpened: boolean;
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
    tokenAddress: {
      type: String,
      default: ''
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
      updateInterval: null,
      detailsOpened: false
    } as Data;
  },

  computed: {
    progressBarWidth(): string {
      if(!this.tokenSupply) return '0%';
      return `${Math.round((+this.tokensClaimed / +this.tokenSupply) * 100)}%`;
    },

    partnerDetails(): string {
      return (partnersInfo as PartnersInfo).partners[this.name].details;
    },

    partnerLogoPath(): string {
      const fileName = (partnersInfo as PartnersInfo).partners[this.name].logo;
      return this.imgPath(fileName);
    }
  },

  watch: {
    id: {
      async handler() {
        await this.update();
      }
    }
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
      this.skillToPartnerRatio = toBN(1).dividedBy(toBN(currentSkillToPartnerRatio).dividedBy(toBN(2).exponentiatedBy(64))).toFixed(4);
    },

    toggleDetails() {
      this.detailsOpened = !this.detailsOpened;
    },

    async addTokenToMetamask() {
      await addTokenToMetamask(this.tokenAddress, this.tokenSymbol);
    }
  },

  async created() {
    await this.update();
    this.updateInterval = setInterval(async () => { this.update(); }, 10000);
  },

  beforeDestroy() {
    if(this.updateInterval) {
      clearInterval(this.updateInterval);
    }
  }
});

</script>

<style scoped>
.partner-div {
  width: 280px;
  height: 215px;
  border: 2px solid #9e8a57;
  border-radius: 10px;
  padding: 5px;
  background: linear-gradient(45deg, rgba(20,20,20,1) 0%, rgba(36,39,32,1) 100%);
}
.partner-logo {
  width: 100px;
  height: 100px;
}
.multiplier-text {
  font-size: 0.8rem;
}
.collapse-style {
  width: 280px;
  border: 2px solid #9e8a57;
  border-radius: 10px;
  background: linear-gradient(45deg, rgba(20,20,20,1) 0%, rgba(36,39,32,1) 100%);
  overflow: hidden;
}
.partner-name {
  height: 48px;
}
.collapsed > .when-open,
.not-collapsed > .when-closed {
  display: none;
}
.on-top {
  z-index: 10;
}
.add-token-button {
  line-height: 1.2;
}
</style>
