<template>
  <a class="calculator-icon" @click="onShowEarningsCalculator">
    <div class="character-earning-potential">
      <div class="milestone-details">
        <div class="calculator-icon-div">
          <p class="h2 m-0">
            <b-icon-calculator-fill class="yellow-icon" scale="1"/>
          </p>
          <span class="text-light title-text">{{$t("EarningsCalculator.earningsCalculator")}}</span>

          <b-modal hide-footer hide-header ref="earnings-calc-modal" size="xl">
            <h4 class="modal-title">{{$t("EarningsCalculator.earningsCalculator")}}</h4>
            <div class="calculator">
              <div class="calculator-character">
                <span class="calculator-subheader">{{$t('character')}}</span>
                <img src="../../assets/characters/KnightFire.png" class="char-placeholder">
                <span>{{$t('element')}}</span>
                <select class="form-control wep-trait-form" v-model="characterElementValue">
                  <option v-for="x in this.$t('traits')" :value="x" :key="x">{{ x }}</option>
                </select>
                <span>{{$t('level')}}</span>
                <div class="slider-input-div">
                  <input class="stat-slider" type="range" min="1" max="255" v-model="levelSliderValue" />
                  <b-form-input class="stat-input" type="number" v-model="levelSliderValue" :min="1" :max="255" />
                </div>
                <span>{{$t('Character.souls')}}</span>
                <div class="slider-input-div">
                  <input class="stat-slider" type="range" :min="0" :max="maxSoulSliderValue" v-model="soulSliderValue" />
                  <b-form-input class="stat-input" type="number" v-model="soulSliderValue" :min="0" :max="maxSoulSliderValue" />
                </div>
                <span>{{$t('stamina')}}</span>
                <select class="form-control wep-trait-form" v-model="staminaSelectValue">
                  <option v-for="x in [40,80,120,160,200]" :value="x" :key="x">{{ x }}</option>
                </select>
              </div>

              <div class="calculator-earnings">
                <div class="d-flex">
                  <div class="coin-price-inputs">
                    <span class="calculator-subheader">{{$t('EarningsCalculator.currentPrices')}} (USD)</span>
                    <div class="prices-div">
                      <div class="token-price-div">
                        {{gasToken}}:
                        <span v-if="!isLoading">${{currentTokenPrice}}</span>
                        <span v-else><i class="fas fa-spinner fa-spin ml-2"></i></span>
                      </div>
                      <div class="token-price-div">
                        SKILL:
                        <span v-if="!isLoading">${{skillPrice}}</span>
                        <span v-else><i class="fas fa-spinner fa-spin ml-2"></i></span>
                      </div>
                    </div>
                  </div>
                  <div class="coin-price-inputs">
                    <span class="calculator-subheader">{{$t('EarningsCalculator.currentBestMultiplier')}}</span>
                    <div class="prices-div">
                      <div class="token-price-div">
                        <span v-if="!isLoading">x{{currentMultiplier}}</span>
                        <span v-else><i class="fas fa-spinner fa-spin ml-2"></i></span>
                      </div>
                    </div>
                  </div>
                </div>
                <div class="results">
                  <strong>{{$t('EarningsCalculator.earnings')}} (USD)</strong>
                  <div class="earnings-grid">
                    <b-row>
                      <b-col><strong>{{$t('EarningsCalculator.winsPerDay')}}</strong></b-col>
                      <b-col><strong>{{$t('EarningsCalculator.dailyProfit')}}</strong><br>(1 {{$t('character')}})</b-col>
                      <b-col><strong>{{$t('EarningsCalculator.dailyProfit')}}</strong><br>(4 {{$t('characters')}})</b-col>
                      <b-col><strong>{{$t('EarningsCalculator.monthlyProfit')}}</strong><br>(4 {{$t('characters')}})</b-col>
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
                    v-tooltip.bottom="$t('EarningsCalculator.earningsHint')"/>
                </div>
              </div>

              <div class="calculator-weapon">
                <span class="calculator-subheader">{{$t('weapon')}}</span>
                <img src="../../assets/placeholder/weapon5.png" class="wep-placeholder">
                <span>{{$t('stars')}}</span>
                <b-form-rating @change="refreshWeaponStats" class="stars-picker" variant="warning" v-model="starsValue" size="sm"></b-form-rating>
                <span>{{$t('element')}}</span>
                <select class="form-control wep-trait-form" v-model="wepElementValue">
                  <option v-for="x in this.$t(['traits'])" :value="x" :key="x">{{ x }}</option>
                </select>
                <span>{{$t('stats')}}</span>
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
                <span>{{$t('bonusPower')}}</span>
                <div class="slider-input-div">
                  <input class="stat-slider" type="range" :min="0" :max="2500" v-model="wepBonusPowerSliderValue" />
                  <b-form-input class="power-input" type="number" v-model="wepBonusPowerSliderValue"
                    :min="getMinRoll(starsValue)" :max="getMaxRoll(starsValue)" />
                </div>
              </div>
            </div>
            <div class="footer-close" @click="$refs['earnings-calc-modal'].hide()">
              <p class="tapAny mt-4">{{$t('tapAnyWhere')}}</p>
              <p class="close-icon"></p>
            </div>
          </b-modal>
        </div>
      </div>
    </div>
  </a>
</template>

<script lang="ts">
import { getConfigValue } from '@/contracts';
import { CharacterPower, CharacterTrait, GetTotalMultiplierForTrait, IWeapon, WeaponTrait } from '@/interfaces';
import axios from 'axios';
import Vue from 'vue';
import { Accessors } from 'vue/types/options';
import { mapActions, mapGetters } from 'vuex';
import { toBN, fromWeiEther } from '../../utils/common';

interface PriceJson {
  binancecoin: CoinPrice;
  cryptoblades: CoinPrice;
  'huobi-token': CoinPrice;
  'oec-token': CoinPrice;
  'matic-network': CoinPrice;
  'avalanche-2': CoinPrice;
  ethereum: CoinPrice;
}

interface StoreMappedCombatGetters {
  fightGasOffset: string;
  fightBaseline: string;
}

interface StoreMappedCombatActions {
  fetchExpectedPayoutForMonsterPower(
    { power, isCalculator }:
    { power: string | number, isCalculator: boolean }): Promise<string>;
  getCombatTokenChargePercent(): Promise<string>;
}

interface StoreMappedTreasuryActions {
  getCurrentBestMultiplier(): Promise<number>;
}

interface CoinPrice {
  usd: number;
}

export default Vue.extend({
  computed: {
    ...mapGetters([
      'currentCharacter',
      'currentWeapon',
      'getCharacterPower'
    ]),
    ...(mapGetters('combat', [
      'fightGasOffset',
      'fightBaseline'
    ]) as Accessors<StoreMappedCombatGetters>),

    isLoadingCharacter(): boolean {
      return !this.currentCharacter;
    },

    currentTokenPrice(): number {
      switch(this.gasToken) {
      case 'BNB':
        return this.bnbPrice;
      case 'HT':
        return this.htPrice;
      case 'OKT':
        return this.oktPrice;
      case 'MATIC':
        return this.maticPrice;
      case 'AVAX':
        return this.avaxPrice;
      case 'aETH':
        return this.auroraPrice;
      case 'SFUEL':
        return this.skalePrice;
      default:
        return this.bnbPrice;
      }
    },

    maxSoulSliderValue(): number {
      return CharacterPower(this.levelSliderValue - 1) * this.powerMultiplierLimit;
    }
  },

  data() {
    return {
      characterElementValue: '',
      levelSliderValue: 1,
      soulSliderValue: 0,
      staminaSelectValue: 200,
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
      htPrice: 0,
      oktPrice: 0,
      maticPrice: 0,
      avaxPrice: 0,
      auroraPrice: 0,
      skalePrice: 0,
      skillPrice: 0,
      calculationResults: [] as number[][],
      gasToken: '',
      fightFeePercentage: 0,
      currentMultiplier: 1,
      isLoading: false,
      powerMultiplierLimit: 3 // hardcoded soul power limit in the contract
    };
  },

  methods: {
    ...(mapActions('combat', ['fetchExpectedPayoutForMonsterPower', 'getCombatTokenChargePercent',]) as StoreMappedCombatActions),
    ...(mapActions('treasury', ['getCurrentBestMultiplier']) as StoreMappedTreasuryActions),

    async onShowEarningsCalculator() {
      if(this.currentCharacter !== null && this.currentCharacter !== undefined) {
        this.characterElementValue = CharacterTrait[this.currentCharacter.trait];
        this.levelSliderValue = this.currentCharacter.level + 1;
        this.soulSliderValue = this.getCharacterPower(this.currentCharacter.id) - CharacterPower(this.currentCharacter.level);
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

      (this.$refs['earnings-calc-modal'] as any).show();
      this.isLoading = true;
      try {
        await this.fetchPricesAndFees();
      }
      finally {
        this.isLoading = false;
      }
    },

    onReset() {
      this.characterElementValue = '';
      this.levelSliderValue =  1;
      this.staminaSelectValue = 200;
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

    async fetchPricesAndFees() {
      await this.fetchPrices();
      this.fightFeePercentage = +await this.getCombatTokenChargePercent();
      this.currentMultiplier = +(+(await this.getCurrentBestMultiplier()/1e18).toFixed(4));
    },

    async fetchPrices() {
      const response = await axios.get('https://api.coingecko.com/api/v3/simple/price?ids=cryptoblades,binancecoin,huobi-token,oec-token,matic-network,avalanche-2,ethereum&vs_currencies=usd');
      const data = response.data as PriceJson;
      this.bnbPrice = data?.binancecoin.usd;
      this.skillPrice = data?.cryptoblades.usd;
      this.htPrice = data?.['huobi-token'].usd;
      this.oktPrice = data?.['oec-token'].usd;
      this.maticPrice = data?.['matic-network'].usd;
      this.avaxPrice = data?.['avalanche-2'].usd;
      this.auroraPrice = data?.ethereum.usd;
    },

    canCalculate(): boolean {
      if(this.isLoading) return false;
      if(!this.characterElementValue || !this.wepElementValue) return false;
      if(this.starsValue < 4 && !this.wepFirstStatElementValue) return false;
      if(this.starsValue === 4 && (!this.wepFirstStatElementValue || !this.wepSecondStatElementValue)) return false;
      if(this.starsValue === 5 && (!this.wepFirstStatElementValue || !this.wepSecondStatElementValue || !this.wepThirdStatElementValue)) return false;
      return true;
    },

    async calculateEarnings() {
      if(!this.canCalculate()) return;
      this.calculationResults = [];
      const fightFee = +getConfigValue('fightGas') * this.currentTokenPrice;
      const weapon = this.getWeapon();
      const characterTrait = CharacterTrait[this.characterElementValue as keyof typeof CharacterTrait];
      const weaponMultiplier = GetTotalMultiplierForTrait(weapon, characterTrait);

      const totalPower = this.getTotalPower(CharacterPower(this.levelSliderValue - 1) + +this.soulSliderValue, weaponMultiplier, this.wepBonusPowerSliderValue);
      const averageDailyReward = await this.getAverageRewardForPower(totalPower) * 7.2;
      const averageDailyCostInNativeTokenFees = this.gasToken === 'SFUEL' ? 0 : averageDailyReward * this.skillPrice * this.fightFeePercentage / 100;
      const averageFightProfit = averageDailyReward * this.skillPrice * this.currentMultiplier / 7.2;
      for(let i = 1; i < 8; i++) {
        const averageDailyProfitForCharacter = averageFightProfit * i -
          ((this.getNumberOfFights(this.staminaSelectValue) * fightFee)) - averageDailyCostInNativeTokenFees;
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

    async getAverageRewardForPower(power: number) {
      const expectedPayout = parseInt(await this.fetchExpectedPayoutForMonsterPower({ power: Math.round(power), isCalculator: true }), 10);
      return this.formattedSkill(expectedPayout);
    },

    getNextMilestoneBonus(level: number): string {
      const nextMilestoneLevel = this.getNextMilestoneLevel(level);
      return this.getRewardDiffBonus(level, nextMilestoneLevel);
    },

    getNextMilestoneLevel(level: number): number {
      return (Math.floor(level / 10) + 1) * 10 + 1;
    },

    getAverageRewardAtLevel(level: number): number {
      return this.formattedSkill(parseInt(this.fightGasOffset, 10))
      + (this.formattedSkill(parseInt(this.fightBaseline, 10))
      * (Math.sqrt(CharacterPower(level - 1)/1000)));
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

  mounted() {
    this.gasToken = getConfigValue('currencySymbol') || 'BNB';
  }
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
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-items: center;
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
  width: 60px;
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
  height: 2rem;
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

.yellow-icon {
  color: #EDCD90;
}

.calculator-icon {
  min-height: 7rem;
  min-width: 4rem;
  max-width: 7rem;
  background: #1a253b 0% 0% no-repeat padding-box;
  border: 1px solid #344362;
  border-radius: 5px;
  text-align: center;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 2px;
  cursor: pointer;
}

.title-text {
  font-size: 0.85vw;
}

.modal-title {
  font-family: Trajan;
  font-size: 28px;
  margin-bottom: 30px;
  color: #e9c97a;
  text-transform: uppercase;
  text-align: center;
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
