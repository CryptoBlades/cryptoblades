<template>
  <div>
  <div class="results-panel">
    <div class="float-center">
      <h1 class="text-center outcome result-title">{{ formattedOutcome.toUpperCase() }}</h1>
      <b-container>
        <b-row class="power-rolled">
          <b-col cols="4" lg="5" sm="4" md="4" class="win-details">
            <h5>{{$t('combatResults.youRolled')}}</h5>
          </b-col>
          <b-col cols="4" lg="2" sm="4" md="4" class="win-details">
            <img src="../assets/arrow-right.png" alt="">
          </b-col>
          <b-col cols="4" lg="5" sm="4" md="4" class="win-details">
            <h5>{{fightResults.playerRoll}}</h5>
          </b-col>
        </b-row>
        <b-row class="power-rolled">
          <b-col cols="4"  lg="5" sm="4" md="4" class="win-details">
            <h5>{{$t('combatResults.enemyRolled')}}</h5>
          </b-col>
          <b-col cols="4" lg="2" sm="4" md="4" class="win-details">
            <img src="../assets/arrow-right.png" alt="">
          </b-col>
          <b-col cols="4" lg="5" sm="4" md="4" class="win-details">
            <h5>{{fightResults.enemyRoll}}</h5>
          </b-col>
        </b-row>
      </b-container>
      <b-container v-if="fightResults.isVictory">
        <b-row>
          <b-col class="you-earned">
            <h4>{{$t('combatResults.earned')}}</h4>
          </b-col>
        </b-row>
        <b-row>
          <b-col class="earned">
            <div class="h5 text-white">
              <div v-if="!isValor">
                <div>
                  <b>{{ formattedSkill }}</b>
                  <span>
                    <small class="mr-2">(<b>${{ fightRewardsAmountInUSD }}</b>)</small>
                    <Hint :text="$t('combatResults.earnedSkillHint')" />
                  </span>
                </div>
                <div>
                  <span class="mr-2" v-html="$t('combatResults.earnedSkill')"> </span>
                  <Hint :text="$t('combatResults.hint')" />
                </div>
              </div>
              <div v-else>
                <div>
                  <b>{{ formattedSkill }}</b>
                  <span>
                    <small class="mr-2">(<b>${{ fightRewardsAmountInUSD }}</b>)</small>
                    <Hint :text="$t('combatResults.earnedValorHint')" />
                  </span>
                </div>
                <div>
                  <span class="mr-2" v-html="$t('combatResults.earnedValor')"> </span>
                  <Hint :text="$t('combatResults.hint')" />
                </div>
              </div>
              <span v-if="+gasOffsetPerFight" v-html="$t('combatResults.gasOffset', {
                  offset: formattedSkillGasOffsetRewards,
                  inUSD: isValor ? '' : formattedInUsd(calculateSkillPriceInUsd(formattedSkillGasOffsetRewards).toFixed(4))
                })"></span>
            </div>
            <h5>+ {{formattedXpGain}}</h5>
          </b-col>
        </b-row>
      </b-container>
      <h6 class="text-center gas-spent">
        {{$t('combatResults.gasFee', {
          bnbGasUsed : fightResults.bnbGasUsed,
          gasToken : gasToken
          })
        }}
      </h6>
    </div>
  </div>
    <div v-if="showAds && !isMobile()" class="ad-container align-items-center">
      <script2 async src="https://coinzillatag.com/lib/display.js"></script2>
        <div class="coinzilla" data-zone="C-316621de2f7b8b25140"></div>
          <script2>
                window.coinzilla_display = window.coinzilla_display || [];
                var c_display_preferences = {};
                c_display_preferences.zone = "316621de2f7b8b25140";
                c_display_preferences.width = "300";
                c_display_preferences.height = "250";
                coinzilla_display.push(c_display_preferences);
          </script2>
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import {fromWeiEther, toBN} from '../utils/common';
import {PropType} from 'vue/types/options';
import axios from 'axios';
import {getConfigValue} from '@/contracts';
import i18n from '@/i18n';
import {TranslateResult} from 'vue-i18n';
import '@/mixins/general';
import Hint from '@/components/Hint.vue';
import { mapActions, mapGetters, mapState } from 'vuex';
import { SupportedProject } from '@/views/Treasury.vue';
import { Accessors } from 'vue/types/options';


interface StoreMappedTreasuryGetters {
  getPartnerProjects: SupportedProject[];
  getProjectMultipliers: Record<number, string>
}

interface CombatResult {
  isVictory: boolean;
  playerRoll: string
  enemyRoll: string;
  xpGain: string;
  skillGain: string;
  bnbGasUsed: string;
}

interface StoreMappedTreasuryState {
  payoutCurrencyId: string;
  partnerProjectMultipliers: Record<number, string>;
  partnerProjectRatios: Record<number, string>;
  defaultSlippage: string;
}
interface StoreMappedTreasuryActions{
  getPartnerProjectMultiplier(id: number): Promise<string>;
  fetchPartnerProjects(): Promise<void>;
}

interface StoreMappedCombatActions {
  fetchIgoRewardsPerFight(): Promise<string>;
  fetchGasOffsetPerFight(): Promise<string>;
}

export default Vue.extend({
  components: {
    Hint
  },
  props: {
    fightResults: {
      type: Object as PropType<CombatResult>,
      default() {
        return {} as CombatResult;
      },
    },
    staminaUsed: {
      type: Number,
      default: 0,
    },
    isValor: {
      type: Boolean,
      default: false
    }
  },

  data() {
    return {
      skillPrice: 0,
      valorPrice: 0,
      gasToken: '',
      showAds: false,
      gasOffsetPerFight: 0,
      highestMultiplier: 0,
      highestMultiplierProject: {} as SupportedProject,
      partnerProjects: [] as SupportedProject[],
    };
  },
  watch: {
    getPartnerProjects(newval) {
      this.partnerProjects = newval;
      this.getProjectMultiplier();
    }
  },
  computed: {
    ...(mapGetters('treasury', ['getPartnerProjects', 'getProjectMultipliers']) as Accessors<StoreMappedTreasuryGetters>),
    ...(mapState('treasury',
      ['payoutCurrencyId','partnerProjectRatios','defaultSlippage'])as Accessors<StoreMappedTreasuryState>),
    formattedOutcome(): TranslateResult {
      if(this.fightResults.isVictory) return i18n.t('combatResults.won');
      else return i18n.t('combatResults.lost');
    },
    formattedSkill(): string {
      return toBN(fromWeiEther(this.fightResults.skillGain)).toFixed(6);
    },
    formattedSkillNoIGO(): string {
      return toBN(fromWeiEther((parseInt(this.fightResults.skillGain, 10)).toString())).toFixed(6);
    },
    formattedSkillGasOffsetRewards(): string {
      return toBN(fromWeiEther((this.gasOffsetPerFight * this.formattedStaminaUsed).toString())).toFixed(6);
    },
    formattedStaminaUsed(): number {
      return this.staminaUsed / 40;
    },
    formattedXpGain(): string {
      return this.fightResults.xpGain + ' xp';
    },
    highestProjectMultiplier(): number {
      return +(toBN(+this.getProjectMultipliers[+this.highestMultiplierProject.id]).div(toBN(10).pow(18)).toFixed(4) || 0);
    },
    fightRewardsAmountInUSD(): string {
      if(this.isValor) {
        return ((this.valorPrice * +this.formattedSkill * this.highestProjectMultiplier) || 0).toFixed(4);
      } else {
        return ((this.skillPrice * +this.formattedSkill * this.highestProjectMultiplier) || 0).toFixed(4);
      }
    }
  },
  methods: {
    ...(mapActions('treasury', ['getPartnerProjectMultiplier', 'fetchPartnerProjects']) as StoreMappedTreasuryActions),
    ...(mapActions('combat', ['fetchIgoRewardsPerFight', 'fetchGasOffsetPerFight']) as StoreMappedCombatActions),
    async fetchPrices(): Promise<void> {
      const response = await axios.get('https://api.coingecko.com/api/v3/simple/price?ids=cryptoblades,binancecoin&vs_currencies=usd');
      this.skillPrice = response.data?.cryptoblades.usd;
    },
    async fetchValorPrice(): Promise<void> {
      const response = await axios.get('https://api.dexscreener.com/latest/dex/search/?q=0x8730c8dedc59e3baffb67bf1fa63d4f0e2d9ecc9');
      this.valorPrice = response.data?.pairs[0].priceUsd;
    },
    async getProjectMultiplier() {
      const tokenSymbol = this.isValor ? 'VALOR' : 'SKILL';
      this.partnerProjects = this.partnerProjects && this.partnerProjects.filter(partnerProject => partnerProject.tokenSymbol.includes(tokenSymbol));
      if(this.partnerProjects.length > 0) {
        this.partnerProjects.map(async (project) => {
          await this.getPartnerProjectMultiplier(project.id);
        });
        const projectMultipliers = await this.getProjectMultipliers;

        this.highestMultiplierProject = this.partnerProjects.sort((a, b) => {
          const highestMultiplierA = +(toBN(+projectMultipliers[a.id]).div(toBN(10).pow(18)).toFixed(4));
          const highestMultiplierB = +(toBN(+projectMultipliers[b.id]).div(toBN(10).pow(18)).toFixed(4));

          return highestMultiplierA - highestMultiplierB;
        })[0];
      }
    },
    formattedInUsd(value: string): string {
      if(!value) return '';
      return `($${value})`;
    },
    calculateSkillPriceInUsd(skill: number): number {
      if(!skill) return 0;
      return (skill as unknown as number * this.skillPrice as unknown as number);
    },
    calculatedSkillReward(): string {
      return toBN(fromWeiEther(this.fightResults.skillGain)).toFixed(6);
    },
    checkStorage() {
      if (process.env.NODE_ENV === 'development') this.showAds = false;
      else this.showAds = localStorage.getItem('show-ads') === 'true';
    },
  },
  async beforeMount(){
    this.gasOffsetPerFight = parseInt(await this.fetchGasOffsetPerFight(), 10);
  },
  async mounted() {
    await this.fetchPartnerProjects();
    this.gasToken = getConfigValue('currencySymbol') || 'BNB';

    await this.fetchValorPrice();
    await this.fetchPrices();
    await new Promise(f => setTimeout(f, 1000));
    this.checkStorage();
  },
});
</script>

<style>
.results-panel {
  display: flex;
  flex-direction: row-reverse;
  justify-content: space-around;
  align-items: center;
  margin: auto;
  text-align: center;
}

.result-title{
  margin-bottom: 3em;
  color: #EDCD90;
}

.outcome {
  font-family: Trajan;
  font-size: 2em;
  padding: 0.1em;
  margin-top: 0.25em;
  margin-bottom: 1em;
}
.expander-divider {
  width: 100%;
  position: relative;
  height: 0.2em;
}
.formatted-skill {
  margin-top: -10px;
  margin-bottom: 0;
  font-size: 0.8em;
}
.gas-spent {
  font-size: 1em;
  margin-bottom: 0;
}
.no-padding {
  padding: 0 !important;
}
.no-margin {
  margin: 0;
}
.crypto-warrior-image {
  max-width: 13em;
}

.results-panel > div > div{
  margin-bottom: 40px;
}

.results-panel > div > div:nth-child(2) > div > div{
  text-align: center;
  padding: 0px;
}


.power-rolled{
  border-bottom: 1px solid rgba(255, 255, 255, 0.282);
  widows: 70%;
  margin: auto;
}

.power-rolled .win-details:nth-child(1){
  text-align: right;
}

.power-rolled .win-details:nth-child(2){
  text-align: center;
}

.power-rolled .win-details:nth-child(3){
  text-align: left;
  flex-wrap:nowrap;
}



.win-details{
  padding: 0px;
}

.win-details > h5{
  font-family: Roboto;
  color: rgba(255, 255, 255, 0.405);
  font-size: 1em;
  margin-bottom: 10px;
  margin-top: 10px;
}

.earned > h4{
  font-family: Roboto;
  color: #fff;
  font-size:1em;
}

.earned > h5{
  font-family: Roboto;
  color: rgb(186, 186, 4);
}

.gas-spent{
    font-family: Roboto;
    font-size: 0.8em;
    color: rgba(255, 255, 255, 0.357);
}

.win-details > img{
  width: 9px;
  margin-bottom: 10px;
  margin-top: 10px;
}

.you-earned > h4{
  font-size: 1.6em;
  font-family: 'Roboto', 'serif'  !important;
}

.ad-container {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.top-bg-img > img, .bot-bg-img > img {
    width: 69% !important;
}




@media all and (max-width: 600px) {
  /* .modal-dialog{
    margin-top: 10em;
  } */

  .outcome{
    font-size: 1.5em;
  }

  .modal-content{
    width: auto !important;
  }

  .float-center .container{
    padding: 0px !important;;
  }

  .float-center .container .power-rolled{
    padding: 0px !important;
    width: 100% !important;
  }
}

</style>
