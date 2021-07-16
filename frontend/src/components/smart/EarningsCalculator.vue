<template>
  <div>
    <b-icon-calculator-fill class="milestone-hint" scale="0.95"
      v-tooltip.bottom="`Eranings Calculator`" v-on:click="onShowEarningsCalculator"/>

    <b-modal hide-footer ref="earnings-calc-modal" size="xl" title="Earnings Calculator">
      <div class="calculator">
        <div class="calculator-character">
          <span class="calculator-subheader">Character</span>
          <img src="../../assets/placeholder/chara-0.png" class="char-placeholder">
          <strong>Element</strong>
          <select class="form-control wep-trait-form" v-model="elementValue">
            <option v-for="x in ['Earth', 'Fire', 'Lightning', 'Water']" :value="x" :key="x">{{ x }}</option>
          </select>
          <strong>Level</strong>
          <div class="slider-input-div">
            <input class="stat-slider" type="range" min="1" max="255" v-model="levelSliderValue" />
            <b-form-input class="stat-input" type="number" v-model="levelSliderValue" :min="1" :max="255" />
          </div>
        </div>
        <div class="calculator-earnings">
          <div class="coin-price-inputs">
            <span class="calculator-subheader">Current prices</span>
          </div>
          <div class="results-grid">
            <span>Results</span>
          </div>
        </div>
        <div class="calculator-weapon">
          <span class="calculator-subheader">Weapon</span>
          <img src="../../assets/placeholder/sword-placeholder-0.png" class="wep-placeholder">
          <strong>Stars</strong>
          <b-form-rating @click="onStarsValueChange" class="stars-picker" variant="warning" v-model="starsValue" size="sm"></b-form-rating>
          <strong>Element</strong>
          <select class="form-control wep-trait-form" v-model="wepElementValue">
            <option v-for="x in ['Earth', 'Fire', 'Lightning', 'Water']" :value="x" :key="x">{{ x }}</option>
          </select>
          <strong>Stats</strong>
          <div>
            <select class="form-control wep-trait-form" v-model="wepFirstStatElementValue">
              <option v-for="x in ['Earth', 'Fire', 'Lightning', 'Water']" :value="x" :key="x">{{ x }}</option>
            </select>
            <div class="slider-input-div">
              <input class="stat-slider" type="range" :min="getMinRoll(starsValue)" :max="getMaxRoll(starsValue)" v-model="wepFirstStatSliderValue" />
              <b-form-input class="stat-input" type="number" v-model="wepFirstStatSliderValue" :min="getMinRoll(starsValue)" :max="getMaxRoll(starsValue)" />
            </div>
          </div>
          <div v-if="starsValue > 3">
            <select class="form-control wep-trait-form" v-model="wepSecondStatElementValue">
              <option v-for="x in ['Earth', 'Fire', 'Lightning', 'Water']" :value="x" :key="x">{{ x }}</option>
            </select>
            <div class="slider-input-div">
              <input class="stat-slider" type="range" :min="getMinRoll(starsValue)" :max="getMaxRoll(starsValue)" v-model="wepSecondStatSliderValue" />
              <b-form-input class="stat-input" type="number" v-model="wepSecondStatSliderValue" :min="getMinRoll(starsValue)" :max="getMaxRoll(starsValue)" />
            </div>
          </div>
          <div v-if="starsValue > 4">
            <select class="form-control wep-trait-form" v-model="wepThirdStatElementValue">
              <option v-for="x in ['Earth', 'Fire', 'Lightning', 'Water']" :value="x" :key="x">{{ x }}</option>
            </select>
            <div class="slider-input-div">
              <input class="stat-slider" type="range" :min="getMinRoll(starsValue)" :max="getMaxRoll(starsValue)" v-model="wepThirdStatSliderValue" />
              <b-form-input class="stat-input" type="number" v-model="wepThirdStatSliderValue" :min="getMinRoll(starsValue)" :max="getMaxRoll(starsValue)" />
            </div>
          </div>
        </div>
      </div>
    </b-modal>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import { mapGetters } from 'vuex';

export default Vue.extend({
  computed: {
    ...mapGetters([
      'currentCharacter'
    ]),

    isLoadingCharacter(): boolean {
      return !this.currentCharacter;
    },
  },

  data() {
    return {
      elementValue: '',
      levelSliderValue: 1,
      starsValue: 1,
      wepElementValue: '',
      wepFirstStatElementValue: '',
      wepSecondStatElementValue: '',
      wepThirdStatElementValue: '',
      wepFirstStatSliderValue: 4,
      wepSecondStatSliderValue: 4,
      wepThirdStatSliderValue: 4,
    };
  },

  methods: {
    onShowEarningsCalculator() {
      (this.$refs['earnings-calc-modal'] as any).show();
    },

    getMinRoll(stars: number): number {
      switch(stars) {
      case 2: return 180;
      case 3: return 280;
      case 4: return 200;
      case 5: return 268;
      default: return 4;
      }
    },

    getMaxRoll(stars: number): number {
      switch(stars) {
      case 1: return 200;
      case 2: return 300;
      default: return 400;
      }
    }
  },

  watch: {
    starsValue(value: number) {
      this.wepFirstStatSliderValue = this.getMinRoll(value);
      this.wepSecondStatSliderValue = this.getMinRoll(value);
      this.wepThirdStatSliderValue = this.getMinRoll(value);
    }
  }
});
</script>
<style>
.char-placeholder {
  align-self: center;
  height: 15rem;
  width: initial;
}

.wep-placeholder {
  align-self: center;
  height: 9rem;
  width: initial;
}

.calculator {
  display: flex;
  flex-direction: row;
  align-content: center;
  justify-content: space-between;
}

.calculator-weapon, .calculator-earnings, .calculator-character {
  display: flex;
  flex-direction: column;
}

.calculator-character {
  justify-self: flex-start;
  width: 20%;
}

.calculator-weapon {
  justify-self: flex-end;
  width: 20%;
}

.stat-slider {
  width: 100%;
}

.form-control.stat-input {
  width: 45px;
  height: 20px;
  padding: 0;
}

.slider-input-div {
  display: flex;
  flex-direction: row;
  margin-top: 5px;
}

.calculator-subheader {
  text-align: center;
}

.stars-picker {
 background-color: #5b553d;
}

.form-control.wep-trait-form {
  padding: 0;
  height: 1.5em;
  font-size: small;
  margin-top: 5px;
}

.milestone-hint {
  margin-left: 5px;
}
</style>
