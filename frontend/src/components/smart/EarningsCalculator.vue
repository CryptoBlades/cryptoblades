<template>
  <div>
    <div class="character-earning-potential dark-bg-text" v-if="!isLoadingCharacter">
      <div class="milestone-header">
        <img src="../../assets/earning-potential-sword.png" class="sword-left">
        <span class="milestone-text">Next Milestone</span>
        <img src="../../assets/earning-potential-sword.png" class="sword-right">
      </div>
      <div class="milestone-details">
        Earn <span class="bonus-text">{{getNextMilestoneBonus(currentCharacter.level)}}%</span> more per battle at<br>
        <div class="calculator-icon-div">
          <span class="milestone-lvl-text">LVL {{getNextMilestoneLevel(currentCharacter.level)}}</span><br>
          <b-button class="btn btn-primary btn-small" @click="onShowEarningsCalculator">
            <b-icon-calculator-fill class="milestone-hint" scale="1"
              v-tooltip.bottom="`Earnings Calculator`"/>
              Earnings Calculator
          </b-button>

          <b-modal hide-footer ref="earnings-calc-modal" size="xl" title="Earnings Calculator">
            <div class="calculator">
              <div class="calculator-character">
                <span class="calculator-subheader">Character</span>
                <img src="../../assets/placeholder/chara-0.png" class="char-placeholder">
                <span>Element</span>
                <select class="form-control wep-trait-form" v-model="characterElementValue">
                  <option v-for="x in ['Earth', 'Fire', 'Lightning', 'Water']" :value="x" :key="x">{{ x }}</option>
                </select>
                <span>Level</span>
                <div class="slider-input-div">
                  <input class="stat-slider" type="range" min="1" max="255" v-model="levelSliderValue" />
                  <b-form-input class="stat-input" type="number" v-model="levelSliderValue" :min="1" :max="255" />
                </div>
                <span>Stamina</span>
                <select class="form-control wep-trait-form" v-model="staminaSelectValue">
                  <option v-for="x in [40,80,120,160,200]" :value="x" :key="x">{{ x }}</option>
                </select>
              </div>

              <div class="calculator-earnings">
                <div class="coin-price-inputs">
                  <span class="calculator-subheader">Current prices (USD)</span>
                  <div class="prices-div">
                    <div class="token-price-div">
                       BNB: <b-form-label class="price-input" type="number" v-model="bnbPrice" /> <span class="text-white"> ${{bnbPrice }}</span>
                    </div>
                    <div class="token-price-div">
                     SKILL:  <b-form-label class="price-input" type="number" v-model="skillPrice" /> <span class="text-white"> ${{skillPrice }}</span>
                    </div>
                  </div>
                </div>
                <div class="results">
                  <strong>Earnings (USD)</strong>
                  <div class="earnings-grid">
                    <b-row>
                      <b-col><strong>Wins # per day</strong></b-col>
                      <b-col><strong>Daily profit</strong><br>(1 character)</b-col>
                      <b-col><strong>Daily profit</strong><br>(4 characters)</b-col>
                      <b-col><strong>Monthly profit</strong><br>(4 characters)</b-col>
                    </b-row>
                    <b-row class="earnings-row" v-for="i in 7" :key="i">
                      <b-col>{{8 - i}} ({{i - 1}} lost)</b-col>
                      <b-col v-bind:class="[getColoringClass(8 - i - 1)]">
                        ${{ calculationResults.length && calculationResults[8 - i - 1][0].toFixed(2) || 0}}
                      </b-col>
                      <b-col v-bind:class="[getColoringClass(8 - i - 1)]">
                        ${{ calculationResults.length && calculationResults[8 - i - 1][1].toFixed(2) || 0}}
                      </b-col>
                      <b-col v-bind:class="[getColoringClass(8 - i - 1)]">
                        ${{ calculationResults.length && calculationResults[8 - i - 1][2].toFixed(2) || 0}}
                      </b-col>
                    </b-row>
                  </div>
                </div>
                <div class="button-div">
                  <b-button class="btn btn-primary" @click="onReset">
                      Reset
                  </b-button>
                  <b-button class="btn btn-primary" @click="calculateEarnings"
                    v-bind:class="[!canCalculate() ? 'disabled disabled-button' : '']">
                      Calculate
                  </b-button>
                  <b-icon-question-circle class="centered-icon" scale="1.5"
                    v-tooltip.bottom="`Earnings on victory: ${this.stringFormattedSkill(this.fightGasOffset)} gas offset +
                    ${this.stringFormattedSkill(this.fightBaseline)} per square root of power/1000`"/>
                </div>
              </div>

              <div class="calculator-weapon">
                <span class="calculator-subheader">Weapon</span>
                <img src="../../assets/placeholder/sword-placeholder-0.png" class="wep-placeholder">
                <span>Stars</span>
                <b-form-rating @change="refreshWeaponStats" class="stars-picker" variant="warning" v-model="starsValue" size="sm"></b-form-rating>
                <span>Element</span>
                <select class="form-control wep-trait-form" v-model="wepElementValue">
                  <option v-for="x in ['Earth', 'Fire', 'Lightning', 'Water']" :value="x" :key="x">{{ x }}</option>
                </select>
                <span>Stats</span>
                <div>
                  <select class="form-control wep-trait-form" v-model="wepFirstStatElementValue">
                    <option v-for="x in ['STR', 'DEX', 'CHA', 'INT', 'PWR']" :value="x" :key="x">{{ x }}</option>
                  </select>
                  <div class="slider-input-div">
                    <input class="stat-slider" type="range" :min="getMinRoll(starsValue)" :max="getMaxRoll(starsValue)" v-model="wepFirstStatSliderValue" />
                    <b-form-input class="stat-input" type="number" v-model="wepFirstStatSliderValue"
                      :min="getMinRoll(starsValue)" :max="getMaxRoll(starsValue)" />
                  </div>
                </div>
                <div v-if="starsValue > 3">
                  <select class="form-control wep-trait-form" v-model="wepSecondStatElementValue">
                    <option v-for="x in ['STR', 'DEX', 'CHA', 'INT', 'PWR']" :value="x" :key="x">{{ x }}</option>
                  </select>
                  <div class="slider-input-div">
                    <input class="stat-slider" type="range" :min="getMinRoll(starsValue)" :max="getMaxRoll(starsValue)" v-model="wepSecondStatSliderValue" />
                    <b-form-input class="stat-input" type="number" v-model="wepSecondStatSliderValue"
                      :min="getMinRoll(starsValue)" :max="getMaxRoll(starsValue)" />
                  </div>
                </div>
                <div v-if="starsValue > 4">
                  <select class="form-control wep-trait-form" v-model="wepThirdStatElementValue">
                    <option v-for="x in ['STR', 'DEX', 'CHA', 'INT', 'PWR']" :value="x" :key="x">{{ x }}</option>
                  </select>
                  <div class="slider-input-div">
                    <input class="stat-slider" type="range" :min="getMinRoll(starsValue)" :max="getMaxRoll(starsValue)" v-model="wepThirdStatSliderValue" />
                    <b-form-input class="stat-input" type="number" v-model="wepThirdStatSliderValue"
                      :min="getMinRoll(starsValue)" :max="getMaxRoll(starsValue)" />
                  </div>
                </div>
                <span>Bonus power</span>
                <div class="slider-input-div">
                  <input class="stat-slider" type="range" :min="0" :max="2500" v-model="wepBonusPowerSliderValue" />
                  <b-form-input class="power-input" type="number" v-model="wepBonusPowerSliderValue"
                    :min="getMinRoll(starsValue)" :max="getMaxRoll(starsValue)" />
                </div>
              </div>
            </div>
          </b-modal>
        </div>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import { CharacterPower, CharacterTrait, GetTotalMultiplierForTrait, IWeapon, WeaponTrait } from '@/interfaces';
import axios from 'axios';
import Vue from 'vue';
import { mapGetters } from 'vuex';
import { toBN, fromWeiEther } from '../../utils/common';

interface PriceJson {
  binancecoin: CoinPrice;
  cryptoblades: CoinPrice;
}

interface CoinPrice {
  usd: number;
}

export default Vue.extend({
  computed: {
    ...mapGetters([
      'currentCharacter',
      'currentWeapon',
      'fightGasOffset',
      'fightBaseline'
    ]),

    isLoadingCharacter(): boolean {
      return !this.currentCharacter;
    },
  },

  data() {
    return {
      characterElementValue: '',
      levelSliderValue: 1,
      staminaSelectValue: 40,
      starsValue: 1,
      wepElementValue: '',
      wepFirstStatElementValue: '',
      wepSecondStatElementValue: '',
      wepThirdStatElementValue: '',
      wepFirstStatSliderValue: 4,
      wepSecondStatSliderValue: 4,
      wepThirdStatSliderValue: 4,
      wepBonusPowerSliderValue: 0,
      bnbPrice: 0,
      skillPrice: 0,
      calculationResults: [] as number[][],
    };
  },

  methods: {
    async onShowEarningsCalculator() {
      if(this.currentCharacter !== null) {
        this.characterElementValue = CharacterTrait[this.currentCharacter.trait];
        this.levelSliderValue = this.currentCharacter.level + 1;
      }

      if(this.currentWeapon !== null) {
        this.starsValue = this.currentWeapon.stars + 1;
        this.wepElementValue = this.currentWeapon.element;
        this.wepFirstStatSliderValue = this.currentWeapon.stat1Value;
        this.wepSecondStatSliderValue = this.starsValue > 3 && this.currentWeapon.stat2Value;
        this.wepThirdStatSliderValue = this.starsValue > 4 && this.currentWeapon.stat3Value;
        this.wepFirstStatElementValue = this.currentWeapon.stat1;
        this.wepSecondStatElementValue = this.starsValue > 3 && this.currentWeapon.stat2;
        this.wepThirdStatElementValue = this.starsValue > 4 && this.currentWeapon.stat3;
        this.wepBonusPowerSliderValue = this.currentWeapon.bonusPower;
      }

      await this.fetchPrices();
      (this.$refs['earnings-calc-modal'] as any).show();
    },

    onReset() {
      this.characterElementValue = '';
      this.levelSliderValue =  1;
      this.staminaSelectValue = 40;
      this.starsValue =  1;
      this.wepElementValue =  '';
      this.wepFirstStatElementValue =  '';
      this.wepSecondStatElementValue =  '';
      this.wepThirdStatElementValue =  '';
      this.wepFirstStatSliderValue =  4;
      this.wepSecondStatSliderValue =  4;
      this.wepThirdStatSliderValue =  4;
      this.wepBonusPowerSliderValue =  0;
      this.calculationResults = [] as number[][];
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
    },

    async fetchPrices() {
      const response = await axios.get('https://api.coingecko.com/api/v3/simple/price?ids=cryptoblades,binancecoin&vs_currencies=usd');
      const data = response.data as PriceJson;
      this.bnbPrice = data?.binancecoin.usd;
      this.skillPrice = data?.cryptoblades.usd;
    },

    canCalculate(): boolean {
      if(!this.characterElementValue || !this.wepElementValue) return false;
      if(this.starsValue < 4 && !this.wepFirstStatElementValue) return false;
      if(this.starsValue === 4 && (!this.wepFirstStatElementValue || !this.wepSecondStatElementValue)) return false;
      if(this.starsValue === 5 && (!this.wepFirstStatElementValue || !this.wepSecondStatElementValue || !this.wepThirdStatElementValue)) return false;
      return true;
    },

    calculateEarnings() {
      if(!this.canCalculate()) return;
      this.calculationResults = [];
      const fightBnbFee = 0.0007 * this.bnbPrice;
      const weapon = this.getWeapon();
      const characterTrait = CharacterTrait[this.characterElementValue as keyof typeof CharacterTrait];
      const weaponMultiplier = GetTotalMultiplierForTrait(weapon, characterTrait);
      const fights = this.getNumberOfFights(this.staminaSelectValue);

      const totalPower = this.getTotalPower(CharacterPower(this.levelSliderValue - 1), weaponMultiplier, this.wepBonusPowerSliderValue);
      const averageDailyReward = this.getAverageRewardForPower(totalPower) *7.2 +
        this.formattedSkill(this.fightGasOffset) * fights;
      const averageFightProfit = averageDailyReward * this.skillPrice / 7.2;
      for(let i = 1; i < 8; i++) {
        const averageDailyProfitForCharacter = averageFightProfit * i -
          ((this.getNumberOfFights(this.staminaSelectValue) * fightBnbFee));
        const averageDailyProfitForAllCharacter = 4 * averageDailyProfitForCharacter;
        const averageMonthlyProfitForAllCharacter = 30 * averageDailyProfitForAllCharacter;
        this.calculationResults.push([averageDailyProfitForCharacter, averageDailyProfitForAllCharacter, averageMonthlyProfitForAllCharacter]);
      }
    },

    getNumberOfFights(stamina: number) {
      return 288 / stamina;
    },

    getWeapon(): IWeapon {
      const weapon = {
        stat1Type: WeaponTrait[this.wepFirstStatElementValue as keyof typeof WeaponTrait],
        stat2Type: WeaponTrait[this.wepSecondStatElementValue as keyof typeof WeaponTrait],
        stat3Type: WeaponTrait[this.wepThirdStatElementValue as keyof typeof WeaponTrait],
        stat1Value: this.wepFirstStatSliderValue,
        stat2Value: this.starsValue > 3 && this.wepSecondStatSliderValue || 0,
        stat3Value: this.starsValue > 4 && this.wepThirdStatSliderValue || 0,
      } as IWeapon;
      return weapon;
    },

    getTotalPower(characterPower: number, weaponMultiplier: number, bonusPower: number): number {
      return characterPower * weaponMultiplier + Number(bonusPower);
    },

    getAverageRewardForPower(power: number): number {
      return (this.formattedSkill(this.fightBaseline) * Math.sqrt(power / 1000));
    },

    getNextMilestoneBonus(level: number): string {
      const nextMilestoneLevel = this.getNextMilestoneLevel(level);
      return this.getRewardDiffBonus(level, nextMilestoneLevel);
    },

    getNextMilestoneLevel(level: number): number {
      return (Math.floor(level / 10) + 1) * 10 + 1;
    },

    getAverageRewardAtLevel(level: number): number {
      return this.formattedSkill(this.fightGasOffset) + (this.formattedSkill(this.fightBaseline) * (Math.sqrt(CharacterPower(level - 1)/1000)));
    },

    getRewardDiffBonus(level: number, targetLevel: number): string {
      return (this.getAverageRewardAtLevel(targetLevel) /
        this.getAverageRewardAtLevel(level + 1) * 100 - 100).toFixed(2);
    },

    formattedSkill(skill: number): number {
      const skillBalance = fromWeiEther(skill.toString());
      return toBN(skillBalance).toNumber();
    },

    stringFormattedSkill(skill: number): string {
      const skillBalance = fromWeiEther(skill.toString());
      return toBN(skillBalance).toFixed(6);
    },

    getColoringClass(i: number): string {
      if(!this.calculationResults.length || this.calculationResults[i][0] === 0) return '';
      if(this.calculationResults[i][0] < 0) return 'negative-value';
      return 'positive-value';
    },

    refreshWeaponStats(value: number) {
      this.wepFirstStatSliderValue = this.getMinRoll(value);
      this.wepSecondStatSliderValue = this.getMinRoll(value);
      this.wepThirdStatSliderValue = this.getMinRoll(value);
    }
  },
});
</script>
<style scoped>

.sword-left {
  position: relative;
  margin-right: 5px;
  width: 5em;
  pointer-events: none;
}

.sword-right {
  transform: scaleX(-1);
  margin-left: 5px;
  position: relative;
  width: 5em;
  pointer-events: none;
}

.character-earning-potential {
  position: relative;
  display: flex;
  align-items: center;
  flex-direction: column;
}

.milestone-text {
  color: #dabf75; /* little lighter to emboss */
}

.milestone-details {
  text-align: center;
  line-height: 1;
}

.bonus-text {
  color: green;
}

.milestone-lvl-text {
  color: rgb(236, 75, 75);
}

.calculator-icon-div {
  margin-top: 6px;
}
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
  padding-right: 5px;
}

.calculator-weapon {
  justify-self: flex-end;
  width: 20%;
  padding-left: 5px;
}

.stat-slider {
  width: 100%;
}

.form-control.stat-input {
  width: 45px;
  height: 20px;
  padding: 0;
}

.form-control.power-input {
  width: 55px;
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
  font-weight: 700;
}

.b-rating.stars-picker {
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

.prices-div {
  display: flex;
  flex-direction: row;
  justify-content: center;
}

.coin-price-inputs {
  width: 100%;
  display: flex;
  flex-direction: column;
}

.calculator-earnings {
  width: 100%;
}

.token-price-div {
  display: flex;
  flex-direction: row;
  margin: 0 10px 0 10px;
}

.form-control.price-input {
  width: 70px;
  height: 20px;
  padding: 0;
}

.earnings-grid {
  width: 100%;
  height: max-content;
  display: flex;
  flex-direction: column;
  align-items: center;
}

.results {
  display: flex;
  flex-direction: column;
  width: 100%;
  height: 100%;
  padding: 20px;
}

.row {
  width: 100%;
}

.col {
  border: 1px solid #9e8a57;
  text-align: center;
}

.earnings-row .col {
  text-align: right;
}

.button-div {
  margin-top: 5px;
  display: flex;
  justify-content: center;
}

.button-div > * {
  margin: 5px;
}

.disabled-button {
  pointer-events: none;
}

.positive-value {
  color: green;
}

.negative-value {
  color: red;
}

.centered-icon {
  align-self: center;
  margin-left: 5px;
}

.btn-small {
  font-size: small;
  margin-top: 5px;
}

@media (max-width: 576px) {
  .calculator {
    flex-direction: column;
  }
  .calculator-character, .calculator-weapon {
    justify-self: center;
    width: 100%;
  }
}
</style>
