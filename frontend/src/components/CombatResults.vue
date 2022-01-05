<template>
  <div>
    <div class="tob-bg-img promotion-decoration">
      <img class="vertical-decoration bottom" src="../assets/border-element.png">
    </div>
    <div class="float-left crypto-warrior-image">
      <img class="vertical-decoration" src="../assets/cryptowarrior.png">
    </div>
  <div class="results-panel">
    <div class="float-right">
      <h1 class="text-left outcome">{{ formattedOutcome }}</h1>
      <b-container v-if="fightResults.isVictory">
        <b-row>
          <b-col class="text-left no-padding">
            <h4>{{$t('combatResults.earned')}}</h4>
          </b-col>
          <b-col class="text-center no-padding">
            <h4>
              {{formattedUsd}}
              <Hint :text="$t('combatResults.hint')" />
            </h4>
            <h6 class="formatted-skill">{{formattedSkill}}</h6>
            <h5>{{formattedXpGain}}</h5>
          </b-col>
        </b-row>
      </b-container>
      <h6 class="text-left gas-spent">
        {{$t('combatResults.gasFee', {
          bnbGasUsed : fightResults.bnbGasUsed,
          gasToken : gasToken
          })
        }}
      </h6>
      <img src="../assets/divider4.png" class="expander-divider">
      <b-container>
        <b-row>
          <b-col class="text-left no-padding">
            <h5 class="no-margin">{{$t('combatResults.youRolled')}}</h5>
            <h5 class="no-margin">{{$t('combatResults.enemyRolled')}}</h5>
          </b-col>
          <b-col class="text-center no-padding">
            <h5 class="no-margin">{{fightResults.playerRoll}}</h5>
            <h5 class="no-margin">{{fightResults.enemyRoll}}</h5>
          </b-col>
        </b-row>
      </b-container>
    </div>
  </div>
    <div class="bot-bg-img promotion-decoration">
      <img src="../assets/border-element.png">
    </div>
    <div v-if="showAds && !isMobile()" class="ad-container align-items-center">
      <Adsense v-if="showAds && !isMobile()" data-ad-client="ca-pub-6717992096530538" data-ad-slot="5115599573"
               data-ad-format="auto" data-full-width-responsive="yes"/>
      <ins class="61c1ff6442013d001aecb701" style="display:inline-block;width:336px;height:280px;"/>
      <script2>!function(e,n,c,t,o,r){!function
        e(n,c,t,o,r,m,s,a){s=c.getElementsByTagName(t)[0],(a=c.createElement(t)).async=!0,a.src="https://"+r[m]+"/js/"+o+".js",a.onerror=function(){a.remove(),(m+=1)>=r.length||e(n,c,t,o,r,m)},s.parentNode.insertBefore(a,s)}(window,document,"script","61c1ff6442013d001aecb701",["cdn.bmcdn2.com"],0)}();
      </script2>
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import {fromWeiEther, toBN} from '../utils/common';
import Hint from '../components/Hint.vue';
import {PropType} from 'vue/types/options';
import axios from 'axios';
import {getConfigValue} from '@/contracts';
import i18n from '@/i18n';
import {TranslateResult} from 'vue-i18n';
import '@/mixins/general';

interface CombatResult {
  isVictory: boolean;
  playerRoll: string
  enemyRoll: string;
  xpGain: string;
  skillGain: string;
  bnbGasUsed: string;
}

export default Vue.extend({
  props: {
    fightResults: {
      type: Object as PropType<CombatResult>,
      default() {
        return {} as CombatResult;
      },
    }
  },

  data() {
    return {
      skillPrice: 0,
      gasToken: '',
      showAds: false
    };
  },

  computed: {
    formattedOutcome(): TranslateResult {
      if(this.fightResults.isVictory) return i18n.t('combatResults.won');
      else return i18n.t('combatResults.lost');
    },
    formattedUsd(): string {
      return `$${(this.calculateSkillPriceInUsd()).toFixed(2)}`;
    },
    formattedSkill(): string {
      return `(${toBN(fromWeiEther(this.fightResults.skillGain)).toFixed(6)} SKILL)`;
    },
    formattedSkillTooltip(): string {
      return fromWeiEther(this.fightResults.skillGain)+' SKILL';
    },
    formattedXpGain(): string {
      return this.fightResults.xpGain + ' xp';
    }
  },
  methods: {
    async fetchPrices(): Promise<void> {
      const response = await axios.get('https://api.coingecko.com/api/v3/simple/price?ids=cryptoblades,binancecoin&vs_currencies=usd');
      this.skillPrice = response.data?.cryptoblades.usd;
    },
    calculateSkillPriceInUsd(): number {
      return fromWeiEther(this.fightResults.skillGain) as unknown as number * this.skillPrice as unknown as number;
    },
    checkStorage() {
      this.showAds =  localStorage.getItem('show-ads') === 'true';
    },
  },

  async mounted() {
    this.gasToken = getConfigValue('currencySymbol') || 'BNB';
    await this.fetchPrices();
    await new Promise(f => setTimeout(f, 1000));
    this.checkStorage();
  },
  components: {
    Hint,
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
.ad-container {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}
</style>
