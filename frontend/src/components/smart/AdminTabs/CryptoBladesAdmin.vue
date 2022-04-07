<template>
  <div class="p-1">
    <h2 class="mt-3">{{
        $t('admin.cryptoblades.setCharacterMintValueCurrent', {cents: currentCharacterMintValue})
      }}</h2>
    <div class="d-flex align-items-center gap-3 flex-wrap">
      <b-form-input v-model="newCharacterMintValue" type="number" number
                    :placeholder="$t('admin.cryptoblades.newValueInCents')"/>
      <b-button @click="setNewCharacterMintValue()" :disabled="setCharacterMintValueButtonDisabled" variant="primary"
                class="text-nowrap">
        {{ $t('admin.cryptoblades.setCharacterMintValue') }}
      </b-button>
    </div>
    <h2 class="mt-3">{{ $t('admin.cryptoblades.setWeaponMintValueCurrent', {cents: currentWeaponMintValue}) }}</h2>
    <div class="d-flex align-items-center gap-3 flex-wrap">
      <b-form-input v-model="newWeaponMintValue" type="number" number
                    :placeholder="$t('admin.cryptoblades.newValueInCents')"/>
      <b-button @click="setNewWeaponMintValue()" :disabled="setWeaponMintValueButtonDisabled" variant="primary"
                class="text-nowrap">
        {{ $t('admin.cryptoblades.setWeaponMintValue') }}
      </b-button>
    </div>
    <h2 class="mt-2">{{ $t('admin.cryptoblades.setFightXpGainCurrentDefault32', {xpGain: currentFightXpGain}) }}</h2>
    <div class="d-flex align-items-center gap-3">
      <b-form-input v-model="newFightXpGain" :placeholder="$t('admin.cryptoblades.fightXpGain')" number type="number"/>
      <b-button @click="setNewFightXpGain()" :disabled="setNewFightXpGainButtonDisabled"
                variant="primary" class="text-nowrap">
        {{ $t('admin.cryptoblades.setFightXpGain') }}
      </b-button>
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import {mapActions} from 'vuex';


interface StoreMappedActions {
  setCharacterMintValue(payload: { cents: number }): Promise<void>;

  setWeaponMintValue(payload: { cents: number }): Promise<void>;

  getCharacterMintValue(): Promise<number>;

  getWeaponMintValue(): Promise<number>;

  getFightXpGain(): Promise<number>;

  setFightXpGain(payload: { xpGain: number }): Promise<void>;
}

interface Data {
  newCharacterMintValue?: number;
  newWeaponMintValue?: number;
  currentCharacterMintValue?: number;
  currentWeaponMintValue?: number;
  currentFightXpGain?: number;
  newFightXpGain?: number;
  isLoading: boolean;
}

export default Vue.extend({
  data() {
    return {
      newCharacterMintValue: undefined,
      newWeaponMintValue: undefined,
      currentCharacterMintValue: undefined,
      currentWeaponMintValue: undefined,
      currentFightXpGain: undefined,
      newFightXpGain: undefined,
      isLoading: false,
    } as Data;
  },

  computed: {
    setCharacterMintValueButtonDisabled(): boolean {
      return this.newCharacterMintValue === undefined
        || this.isLoading;
    },
    setWeaponMintValueButtonDisabled(): boolean {
      return this.newWeaponMintValue === undefined
        || this.isLoading;
    },
    setNewFightXpGainButtonDisabled(): boolean {
      return this.newFightXpGain === undefined
        || this.isLoading;
    },
  },

  methods: {
    ...mapActions([
      'setCharacterMintValue',
      'setWeaponMintValue',
      'getCharacterMintValue',
      'getWeaponMintValue',
      'getFightXpGain',
      'setFightXpGain',
    ]) as StoreMappedActions,

    async setNewCharacterMintValue() {
      if (this.setCharacterMintValueButtonDisabled) return;
      try {
        this.isLoading = true;
        await this.setCharacterMintValue({cents: this.newCharacterMintValue!});
        await this.loadCurrentValues();
        this.newCharacterMintValue = undefined;
      } finally {
        this.isLoading = false;
      }
    },

    async setNewWeaponMintValue() {
      if (this.setWeaponMintValueButtonDisabled) return;
      try {
        this.isLoading = true;
        await this.setWeaponMintValue({cents: this.newWeaponMintValue!});
        await this.loadCurrentValues();
        this.newWeaponMintValue = undefined;
      } finally {
        this.isLoading = false;
      }
    },

    async setNewFightXpGain() {
      if (this.setNewFightXpGainButtonDisabled) return;
      try {
        this.isLoading = true;
        await this.setFightXpGain({xpGain: this.newFightXpGain!});
        await this.loadCurrentValues();
        this.newFightXpGain = undefined;
      } finally {
        this.isLoading = false;
      }
    },

    async loadCurrentValues() {
      try {
        this.isLoading = true;
        this.currentCharacterMintValue = await this.getCharacterMintValue();
        this.currentWeaponMintValue = await this.getWeaponMintValue();
        this.currentFightXpGain = await this.getFightXpGain();
      } finally {
        this.isLoading = false;
      }
    },
  },

  async mounted() {
    await this.loadCurrentValues();
  },
});
</script>

<style scoped>
</style>
