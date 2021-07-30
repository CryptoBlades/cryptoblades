<template>
  <div class="results-panel">
    <span class="outcome">{{ getSuccessText() }}</span>
    <span class="roll">{{ "You rolled "+results[1]+", Enemy rolled "+results[2] }}</span>
    <span v-if="results[0]" class="reward">
      {{ "You earned "+results[3]+" xp"}}
      <br>
      <span v-tooltip="convertWei(results[4])+' SKILL'">{{"and "+formattedSkill}}</span>
        <Hint text="SKILL earned is based on gas costs of the network plus a factor of your power" />
    </span>
  </div>
</template>

<script>
import { toBN, fromWeiEther } from '../utils/common';
import Hint from '../components/Hint.vue';

export default {
  props: ['results'],

  computed: {
    formattedSkill() {
      const skillBalance = fromWeiEther(this.results[4]);
      return `${toBN(skillBalance).toFixed(6)} SKILL`;
    }
  },

  methods: {
    getSuccessText() {
      return this.results[0] ? 'You won the fight!' : 'You lost the fight!';
    },
    convertWei(wei) {
      return fromWeiEther(wei);
    }
  },

  components: {
    Hint,
  },
};
</script>

<style>
.results-panel {
  width: 25em;
  background: rgba(255, 255, 255, 0.1);
  box-shadow: 0 2px 4px #ffffff38;
  border-radius: 5px;
  padding: 0.5em;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  margin: auto;
  text-align: center;
}
.outcome {
  font-size: 2em;
  font-weight: bold;
  padding: 0.5em;
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
</style>
