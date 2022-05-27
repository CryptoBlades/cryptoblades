<template>
    <b-tab active :title="$t('Character.upgrade')" title-item-class="character-wrapper" title-link-class="character-tab" >
      <b-card-text class="character-text mb-4">{{$t(`Character.upgradeText`)}}</b-card-text>
      <div class="row w-100 justify-content-between">
        <div class="col col-md-3 d-flex flex-row">
          <div class="soul-container">
            <img src="../../../assets/dusts/soulIcon.svg" alt="soul"/>
          </div>
          <div class="col character-text">
            <p class="mb-0 text-white soul-title">{{$t(`Character.souls`)}}</p>
            <p class="mb-0">{{ soulBalance * 10 }}</p>
          </div>
        </div>
        <div class="w-100 d-block d-md-none"></div>
        <div class="w-col col-md-6 d-flex flex-column">
          <input
            @change="handlePower"
            class="range-character"
            type="range"
            min="0"
            :max="remainingPowerLimit"
            :disabled="soulBalance <= 0"
            :value="handleSoulPowerValue(powerAmount)"
            steps="10"
          />
          <div class="boxed soul-box">
            <p class="text-center character-text">{{powerAmount}}/{{remainingPowerLimit}} Power</p>
          </div>
        </div>
        <div class="w-100 d-block d-md-none"></div>
        <div class="col col-md-3 character-text d-flex">
          <input id="powerAmount" type="number" :value="powerAmount" @change="handleInput" />
          <button class="mx-1 px-2"  @click="handleMax">{{$t(`Character.max`)}}</button>
        </div>
      </div>
      <button class="upgrade-character-button mt-5" :disabled="powerAmount/10 === 0" @click="onUpgradeConfirm">
        <span>{{$t('Character.upgrade')}}</span><br/>{{powerAmount / 10}} {{$t(`Character.soul`)}}
      </button>
    </b-tab>
</template>

<script lang="ts">
import Vue from 'vue';
import { mapActions, mapGetters, mapState } from 'vuex';

import { CharacterPower } from '@/interfaces';


interface Data {
  powerAmount: number
}

interface StoreMappedActions {
  upgradeCharacterWithSoul(payload: {charId: number, soulAmount: number}): Promise<void>;
}


export default Vue.extend({
  props: {
    soulBalance: {
      type: Number,
      default: 0
    }
  },
  data(): Data{
    return {
      powerAmount: 0
    };
  },
  computed:{
    ...mapState(['characters','currentCharacterId']),
    ...mapGetters(['getCharacterPower']),
    remainingPowerLimit(): number {
      return( 4 * CharacterPower(this.characters[this.currentCharacterId]?.level ?? 0) - this.getCharacterPower(this.currentCharacterId.toString()) ?? 0);
    },
  },
  methods: {
    ...mapActions(['upgradeCharacterWithSoul']) as StoreMappedActions,
    handlePower(e: { target: HTMLInputElement }){
      if ((this.remainingPowerLimit > (this.soulBalance * 10) && +e.target.value > (this.soulBalance * 10))) {
        this.powerAmount = this.soulBalance * 10;
        return;
      }
      this.powerAmount = Math.ceil(+e.target.value/10)*10;
    },
    handleMax(): void{
      if ((this.soulBalance * 10) > this.remainingPowerLimit){
        this.powerAmount = Math.ceil(this.remainingPowerLimit/10)*10;
        return;
      }
      this.powerAmount = this.soulBalance * 10;
    },
    handleInput(e:  { target: HTMLInputElement }): void{
      if (+e.target.value > (this.soulBalance * 10)) {
        this.powerAmount = this.soulBalance * 10;
        return;
      }
      this.powerAmount = Math.ceil((+e.target.value)/10)*10;
    },
    handleSoulPowerValue(souls: number): number{
      if (souls >= (this.soulBalance * 10)) {
        this.powerAmount = this.soulBalance * 10;
        return this.soulBalance * 10;
      }
      return souls;
    },
    async onUpgradeConfirm() {
      if(!this.currentCharacterId || this.powerAmount === 0) return;
      try {
        await this.upgradeCharacterWithSoul({ charId: this.currentCharacterId, soulAmount: this.powerAmount/10 });
      }
      catch(err) {
        return;
      }
      this.$emit('fetchSoulBalance');
      this.powerAmount = 0;
    },

  },
});
</script>

<style lang="scss" scoped>
.soul-container {
  width: 56px;
  height: 56px;
  background: transparent radial-gradient(closest-side at 50% 50%, #1D1D1D 0%, #141414 100%) 0% 0% no-repeat padding-box;
  border: 1px solid #EDCD90;
  border-radius: 5px;
  display: grid;
  place-items:center;
}

.soul-title {
  line-height: 24px;
}

.upgrade-character-button {
  width: 200px;
  height: 80px;
  background: transparent;
  background-image: url('../../../assets/btn-join.png');
  background-size: contain;
  background-position: center;
  background-repeat: no-repeat;
  border: none;
  outline: none;
  color: #F0E2B6;
  font-weight: 500;
  font-family: 'Roboto', sans-serif;
  text-transform: uppercase;
}

.upgrade-character-button:disabled {
  filter:grayscale(100%);
  opacity: 0.8;
}

.upgrade-character-button span {
  font-family: 'Oswald', sans-serif;
  color: #fff;
}


.character-text{
  color: #7F8693;
}

.character-text input {
  background: #000E1D 0% 0% no-repeat padding-box;
  border: 1px solid #404857;
  border-radius: 3px;
  color: #fff;
  width: 53px;
  height: 32px;
  text-align: center;
}

.character-text button {
  background: #1E293C 0% 0% no-repeat padding-box;
  border: 1px solid #1E293C;
  border-radius: 3px;
  color: #fff;
  height: 32px;
}


.range-character {
  height: 24px;
}


/* Chrome, Safari, Edge, Opera */
.character-text input::-webkit-outer-spin-button,
.character-text input::-webkit-inner-spin-button {
  -webkit-appearance: none;
  margin: 0;
}

/* Firefox */
.character-text input[type=number] {
  -moz-appearance: textfield;
}


</style>