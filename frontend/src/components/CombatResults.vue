<template>
  <div>
  <div class="results-panel">
    <div class="float-center">
      <h1 class="text-center outcome p-4">{{ formattedOutcome.toUpperCase() }}</h1>
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
            <p class="h5 text-white">
              <span v-html="$t('combatResults.earnedSkill', {
                  noIGO: +igoDefaultReward ? formattedSkillNoIGO : formattedSkill,
                  inUSD: formattedInUsd(calculateSkillPriceInUsd(+igoDefaultReward ? formattedSkillNoIGO : formattedSkill).toFixed(4))
                })"> </span>
              <Hint :text="$t('combatResults.hint')" />
              <span v-if="+igoDefaultReward" v-html="$t('combatResults.earnedIGOSkill', {
                  IGO: formattedSkillIGOReward,
                  inUSD: formattedInUsd(calculateSkillPriceInUsd(formattedSkillIGOReward).toFixed(4))
                })"></span>
            </p>
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
import { mapActions } from 'vuex';

interface CombatResult {
  isVictory: boolean;
  playerRoll: string
  enemyRoll: string;
  xpGain: string;
  skillGain: string;
  bnbGasUsed: string;
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
  },

  data() {
    return {
      skillPrice: 0,
      gasToken: '',
      showAds: false,
      igoDefaultReward: 0,
    };
  },

  computed: {
    formattedOutcome(): TranslateResult {
      if(this.fightResults.isVictory) return i18n.t('combatResults.won');
      else return i18n.t('combatResults.lost');
    },
    formattedSkill(): string {
      return toBN(fromWeiEther(this.fightResults.skillGain)).toFixed(6);
    },
    formattedSkillNoIGO(): string {
      return toBN(fromWeiEther((parseInt(this.fightResults.skillGain, 10) - this.igoDefaultReward).toString())).toFixed(6);
    },
    formattedSkillIGOReward(): string {
      return toBN(fromWeiEther((this.igoDefaultReward * this.formattedStaminaUsed).toString())).toFixed(6);
    },
    formattedStaminaUsed(): number {
      return this.staminaUsed / 40;
    },
    formattedSkillTooltip(): string {
      return fromWeiEther(this.fightResults.skillGain)+' SKILL';
    },
    formattedXpGain(): string {
      return this.fightResults.xpGain + ' xp';
    }
  },
  methods: {
    ...mapActions(['fetchIgoRewardsPerFight']),
    async fetchPrices(): Promise<void> {
      const response = await axios.get('https://api.coingecko.com/api/v3/simple/price?ids=cryptoblades,binancecoin&vs_currencies=usd');
      this.skillPrice = response.data?.cryptoblades.usd;
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
    calculateSkillRewardNoIGO(): string{
      return toBN(fromWeiEther((parseInt(this.fightResults.skillGain, 10) - this.igoDefaultReward).toString())).toFixed(6);
    },
    calculateSkillIGOReward(): string{
      if(!this.igoDefaultReward) return '';
      return toBN(fromWeiEther((this.igoDefaultReward * this.formattedStaminaUsed).toString())).toFixed(6);
    },
    checkStorage() {
      if (process.env.NODE_ENV === 'development') this.showAds = false;
      else this.showAds = localStorage.getItem('show-ads') === 'true';
    },
  },
  async beforeMount(){
    this.igoDefaultReward = await this.fetchIgoRewardsPerFight();
  },
  async mounted() {
    this.gasToken = getConfigValue('currencySymbol') || 'BNB';
    await this.fetchPrices();
    this.igoDefaultReward = await this.fetchIgoRewardsPerFight();
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
.outcome {
  font-family: Trajan;
  font-size: 2em;
  font-weight: bold;
  padding: 0.1em;
  margin-top: 0.25em;
  margin-bottom: 0;
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
    margin-bottom: -70px;

}


.tob-bg-img > img{
  margin-top: -40px !important;
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
