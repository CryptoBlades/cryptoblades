<template>
  <div class="partner-div m-4">
    <div class="d-flex relative">
      <b-icon-exclamation-circle class="partner-note" variant="danger" scale="1.2" v-if="partnerNote" v-tooltip="partnerNote"/>
      <img :src="partnerLogoPath" class="partner-logo"/>
      <div class="d-flex flex-column justify-content-center ml-2">
        <h4 class="d-flex align-items-center partner-name">{{name}}</h4>
        <div class="d-flex">
          <h6>Token: {{tokenSymbol}}</h6>
          <a @click="addTokenToMetamask" class="ml-1 a-button">({{$t('PartneredProject.add')}})</a>
        </div>
        <span class="multiplier-text">{{skillToPartnerRatio}} SKILL/{{tokenSymbol}}</span>
        <span v-bind:class="+multiplier < 0.5 ? 'very-low-multiplier' : (+multiplier < 0.75 ? 'low-multiplier' : '')"
          class="multiplier-text">{{$t('PartneredProject.multiplier')}}: x{{multiplier}}</span>
        <span v-bind:class="+multiplier < 0.5 ? 'very-low-multiplier' : (+multiplier < 0.75 ? 'low-multiplier' : '')"
        class="multiplier-text">$/{{$t('PartneredProject.unclaimed')}}: ${{moneyPerUnclaimed}}</span>
        <span class="multiplier-text">{{$t('PartneredProject.distribution')}}: {{distributionTime}} {{$t('PartneredProject.days')}}</span>
      </div>
    </div>
    <div class="mt-1 progress w-90 justify-items-center">
      <div class="progress-bar progress-bar-striped progress-bar-animated" role="progressbar"
        :style="[{'width': progressBarWidth, 'background-color': '#9e8a57'}]"/>
    </div>
    <h6 class="mt-1 text-center">{{$t('PartneredProject.claimed')}} {{tokensClaimed}} / {{tokenSupply}}</h6>
    <div class="d-flex flex-column align-items-center w-100">
      <b-card no-body class="collapse-style" v-bind:class="detailsOpened ? 'on-top' : ''">
        <b-card-header class="d-flex flex-column align-items-center w-100 mt-1 p-0" v-b-toggle="'collapse-' + id" @click="toggleDetails()">
          <h6 class="when-open">{{$t('PartneredProject.less')}}...</h6><h6 class="when-closed">{{$t('PartneredProject.more')}}...</h6>
        </b-card-header>
        <b-collapse :id="'collapse-' + id">
          <b-card-body>
            <b-card-text>
              <div>
                {{partnerDetails}}
              </div>
              <div>
                <a class="a-button" @click="openPartnerWebsite">{{partnerWebsite}}</a>
              </div>
            </b-card-text>
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
  distributionTime: string;
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
      distributionTime: '0',
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

    partnerWebsite(): string {
      return (partnersInfo as PartnersInfo).partners[this.name].website;
    },

    partnerNote(): string {
      return (partnersInfo as PartnersInfo).partners[this.name].note;
    },

    partnerLogoPath(): string {
      const fileName = (partnersInfo as PartnersInfo).partners[this.name].logo;
      return this.imgPath(fileName);
    },

    moneyPerUnclaimed(): string {
      return toBN(this.tokenPrice).div(toBN(10).pow(18)).div(+this.skillToPartnerRatio).times(+this.multiplier).toFixed(2);
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
    ...mapActions(['getPartnerProjectMultiplier', 'getPartnerProjectClaimedAmount', 'getSkillToPartnerRatio', 'getPartnerProjectDistributionTime']),
    imgPath(img: string): string {
      return this.images('./' + img);
    },

    async update(): Promise<void> {
      const currentMultiplier = await this.getPartnerProjectMultiplier(this.id);
      this.multiplier = toBN(currentMultiplier).div(toBN(10).pow(18)).toFixed(4);

      const distributionTime = await this.getPartnerProjectDistributionTime(this.id);
      this.distributionTime = distributionTime;

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
    },

    openPartnerWebsite() {
      window.open(this.partnerWebsite, '_blank');
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
  width: 290px;
  height: 250px;
  border: 2px solid #9e8a57;
  border-radius: 10px;
  padding: 5px;
  background: linear-gradient(45deg, rgba(20,20,20,1) 0%, rgba(36,39,32,1) 100%);
  position: relative;
}
.partner-logo {
  max-width: 100px;
  height: auto;
  align-self: center;
}
.multiplier-text {
  font-size: 0.8rem;
}
.collapse-style {
  width: 290px;
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
.a-button {
  line-height: 1.2;
  cursor: pointer;
}
.very-low-multiplier {
  color: rgb(223, 17, 17);
}
.low-multiplier {
  color: rgb(212, 147, 25);
}

.partner-note {
  position: absolute;
  top: 5px;
  right: 5px;
}
</style>
