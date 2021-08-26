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
      <h1 class="text-center outcome">{{formattedVictory}}</h1>
      <p> You gained:  <span class="text-success">{{formattedXpGain}}</span>
        <br/>
        You earned: <span class="text-success" v-tooltip="formattedSkillTooltip">{{formattedSkill}}</span>
        <Hint text="SKILL earned is based on gas costs of the network plus a factor of your power" />
        <br/>
        You spent ~ <span class="text-danger">{{fightResults.bnbGasUsed}}</span> BNB on gas fees
      </p>
      <p>You rolled: <span class="text-success">{{fightResults.playerRoll}}</span>
        <br/>
        Enemy rolled: <span class="text-danger">{{fightResults.enemyRoll}}</span>
      </p>
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
    },
  },

  computed: {
    formattedSkill() {
      const skillBalance = fromWeiEther(this.fightResults.skillGain);
      return `${toBN(skillBalance).toFixed(6)} SKILL`;
    },
    formattedSkillTooltip() {
      return fromWeiEther(this.fightResults.skillGain)+' SKILL';
    },
    formattedVictory() {
      return this.fightResults.isVictory ? 'VICTORY' : 'DEFEAT';
    },
    formattedXpGain() {
      return this.fightResults.xpGain + ' xp';
    }
  },

  mounted() {
  },

  methods: {
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
}
.victory {
  color:greenyellow;
}
.loss {
  color: red;
}
.roll {
  font-size: 1.25em;
}
.reward {
  font-size: 1.5em;
}
.crypto-warrior-image {
  max-width: 13em;
}
</style>
