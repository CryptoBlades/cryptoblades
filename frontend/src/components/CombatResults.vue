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
            <h4>You earned:</h4>
          </b-col>
          <b-col class="text-center no-padding">
            <h4>
              {{formattedUsd}}
              <Hint text="SKILL earned is based on gas costs of the network plus a factor of your power" />
            </h4>
            <h6 class="formatted-skill">{{formattedSkill}}</h6>
            <h5>{{formattedXpGain}}</h5>
          </b-col>
        </b-row>
      </b-container>
      <h6 class="text-left gas-spent">You spent {{fightResults.bnbGasUsed}} BNB on gas fees </h6>
      <img src="../assets/divider4.png" class="expander-divider">
      <b-container>
        <b-row>
          <b-col class="text-left no-padding">
            <h5 class="no-margin">You rolled:</h5>
            <h5 class="no-margin">Enemy rolled:</h5>
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

    <div>
      <ins class="adsbygoogle"
          style="display:block"
          data-ad-client="ca-pub-6717992096530538"
          data-ad-slot="5115599573"
          data-ad-format="auto"
          data-full-width-responsive="true"></ins>
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import { toBN, fromWeiEther } from '../utils/common';
import Hint from '../components/Hint.vue';
import {PropType} from 'vue/types/options';
import axios from 'axios';

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
    };
  },

  computed: {
    formattedOutcome(): string {
      return `You ${this.fightResults.isVictory ? 'won' : 'lost'} the fight!`;
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
    }
  },

  async mounted() {
    await this.fetchPrices();
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
</style>
