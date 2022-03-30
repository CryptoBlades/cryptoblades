<template>
  <div class="p-1">
    <h2 class="mt-3">{{ $t('admin.cryptoblades.setCharacterMintValueCurrent', {cents: currentCharacterMintValue}) }}</h2>
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
}

interface Data {
  newCharacterMintValue?: number;
  newWeaponMintValue?: number;
  currentCharacterMintValue?: number;
  currentWeaponMintValue?: number;
  isLoading: boolean;
}

export default Vue.extend({
  data() {
    return {
      newCharacterMintValue: undefined,
      newWeaponMintValue: undefined,
      currentCharacterMintValue: undefined,
      currentWeaponMintValue: undefined,
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
  },

  methods: {
    ...mapActions([
      'setCharacterMintValue',
      'setWeaponMintValue',
      'getCharacterMintValue',
      'getWeaponMintValue',
    ]) as StoreMappedActions,

    async setNewCharacterMintValue() {
      if (this.setCharacterMintValueButtonDisabled) return;
      try {
        this.isLoading = true;
        await this.setCharacterMintValue({cents: this.newCharacterMintValue});
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
        await this.setWeaponMintValue({cents: this.newWeaponMintValue});
        await this.loadCurrentValues();
        this.newWeaponMintValue = undefined;
      } finally {
        this.isLoading = false;
      }
    },

    async loadCurrentValues() {
      try {
        this.isLoading = true;
        this.currentCharacterMintValue = await this.getCharacterMintValue();
        this.currentWeaponMintValue = await this.getWeaponMintValue();
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
