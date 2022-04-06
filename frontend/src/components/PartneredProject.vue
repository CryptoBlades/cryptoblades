<template>
  <div class="partner-div m-4">
    <div class="d-flex relative">
      <b-icon-exclamation-circle class="partner-note" variant="danger" scale="1.2" v-if="partnerProject.note"
                                 v-tooltip="partnerProject.note"/>
      <img :src="partnerProject.logo" class="partner-logo" alt="Partner Logo"/>
      <div class="d-flex flex-column justify-content-center ml-2">
        <h4 class="d-flex align-items-center partner-name">{{ partnerProject.name }}</h4>
        <div class="d-flex">
          <h6>Token: {{ partnerProject.tokenSymbol }}</h6>
          <a @click="addTokenToMetamask" class="ml-1 a-button">({{ $t('PartneredProject.add') }})</a>
        </div>
        <span class="multiplier-text">{{ skillToPartnerRatio }} SKILL/{{ partnerProject.tokenSymbol }}</span>
        <span :class="+multiplier < 0.5 ? 'very-low-multiplier' : (+multiplier < 0.75 ? 'low-multiplier' : '')"
              class="multiplier-text">{{ $t('PartneredProject.multiplier') }}: x{{ multiplier }}</span>
        <span :class="+multiplier < 0.5 ? 'very-low-multiplier' : (+multiplier < 0.75 ? 'low-multiplier' : '')"
              class="multiplier-text">$/{{ $t('PartneredProject.unclaimed') }}: ${{ moneyPerUnclaimed }}</span>
        <span
          class="multiplier-text">{{ $t('PartneredProject.distribution') }}: {{ distributionTime }} {{ $t('PartneredProject.days') }}</span>
      </div>
    </div>
    <div class="mt-1 progress w-90 justify-items-center">
      <div class="progress-bar progress-bar-striped progress-bar-animated" role="progressbar"
           :style="[{'width': progressBarWidth, 'background-color': '#9e8a57'}]"/>
    </div>
    <h6 class="mt-1 text-center">{{ $t('PartneredProject.claimed') }} {{ tokensClaimed }} / {{ partnerProject.tokenSupply }}</h6>
    <div class="d-flex flex-column align-items-center w-100">
      <b-card no-body class="collapse-style" :class="detailsOpened ? 'on-top' : ''">
        <b-card-header class="d-flex flex-column align-items-center w-100 mt-1 p-0" v-b-toggle="'collapse-' + partnerProject.id"
                       @click="toggleDetails()">
          <h6 class="when-open">{{ $t('PartneredProject.less') }}...</h6><h6 class="when-closed">
          {{ $t('PartneredProject.more') }}...</h6>
        </b-card-header>
        <b-collapse :id="'collapse-' + partnerProject.id">
          <b-card-body>
            <b-card-text>
              <div>
                {{ partnerProject.details }}
              </div>
              <div>
                <a class="a-button" @click="openPartnerWebsite">{{ partnerProject.website }}</a>
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
import {mapActions} from 'vuex';
import {addTokenToMetamask, toBN} from '@/utils/common';
import {PropType} from 'vue/types/options';
import {SupportedProject} from '@/views/Treasury.vue';

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
    partnerProject: {
      type: Object as PropType<SupportedProject>,
      required: true,
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
      detailsOpened: false,
    } as Data;
  },

  computed: {
    progressBarWidth(): string {
      if (!this.partnerProject.tokenSupply) return '0%';
      return `${Math.round((+this.tokensClaimed / +this.partnerProject.tokenSupply) * 100)}%`;
    },

    moneyPerUnclaimed(): string {
      return toBN(this.partnerProject.tokenPrice).div(toBN(10).pow(18)).div(+this.skillToPartnerRatio).times(+this.multiplier).toFixed(2);
    }
  },

  methods: {
    ...mapActions(['getPartnerProjectMultiplier', 'getPartnerProjectClaimedAmount', 'getSkillToPartnerRatio', 'getPartnerProjectDistributionTime']),

    async update(): Promise<void> {
      const currentMultiplier = await this.getPartnerProjectMultiplier(this.partnerProject.id);
      this.multiplier = toBN(currentMultiplier).div(toBN(10).pow(18)).toFixed(4);

      this.distributionTime = await this.getPartnerProjectDistributionTime(this.partnerProject.id);

      const currentClaimedTokens = await this.getPartnerProjectClaimedAmount(this.partnerProject.id);
      this.tokensClaimed = toBN(currentClaimedTokens).div(toBN(10).pow(18)).toFixed(2);

      const currentSkillToPartnerRatio = await this.getSkillToPartnerRatio(this.partnerProject.id);
      this.skillToPartnerRatio = toBN(1).dividedBy(toBN(currentSkillToPartnerRatio).dividedBy(toBN(2).exponentiatedBy(64))).toFixed(4);
    },

    toggleDetails() {
      this.detailsOpened = !this.detailsOpened;
    },

    async addTokenToMetamask() {
      await addTokenToMetamask(this.partnerProject.tokenAddress, this.partnerProject.tokenSymbol);
    },

    openPartnerWebsite() {
      window.open(this.partnerProject.website, '_blank');
    }
  },

  async created() {
    await this.update();
    this.updateInterval = setInterval(async () => {
      await this.update();
    }, 10000);
  },

  beforeDestroy() {
    if (this.updateInterval) {
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
  background: linear-gradient(45deg, rgba(20, 20, 20, 1) 0%, rgba(36, 39, 32, 1) 100%);
  position: relative;
}

.partner-logo {
  width: 100px;
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
  background: linear-gradient(45deg, rgba(20, 20, 20, 1) 0%, rgba(36, 39, 32, 1) 100%);
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
