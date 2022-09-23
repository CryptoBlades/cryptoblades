<template>
  <div class="p-1">
    <h2 class="mt-2">{{ $t('admin.shields.mintGiveawayShield') }}</h2>
    <div class="d-flex align-items-center gap-3">
      <b-form-input v-model="giveawayShieldMint.to" :placeholder="$t('admin.shields.playerAddress')"/>
      <b-form-select class="mt-2 mb-2" v-model="giveawayShieldMint.stars">
        <b-form-select-option :value="undefined" disabled>
          {{ $t('admin.shields.pleaseSelectStars') }}
        </b-form-select-option>
        <b-form-select-option v-for="rarity in rarities" :key="rarity" :value="rarity">
          {{ $t(`admin.shields.rarities.${Rarity[rarity]}`) }}
        </b-form-select-option>
      </b-form-select>
      <b-form-select class="mt-2 mb-2" v-model="giveawayShieldMint.type">
        <b-form-select-option :value="undefined" disabled>
          {{ $t('admin.shields.pleaseSelectShieldType') }}
        </b-form-select-option>
        <b-form-select-option v-for="type in shieldTypes" :key="type" :value="type" :disabled="type === ShieldType.FOUNDERS">
          {{ $t(`admin.shields.types.${ShieldType[type]}`) }}
        </b-form-select-option>
      </b-form-select>
      <b-button @click="mintShield()" :disabled="mintShieldButtonDisabled" variant="info" class="text-nowrap">
        {{ $t('admin.shields.mintShield') }}
      </b-button>
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import {mapActions} from 'vuex';
import {isValidWeb3Address} from '@/utils/common';

interface StoreMappedActions {
  mintGiveawayShield(payload: { to: string, stars: number, chosenElement: number }): Promise<void>;
}

enum Rarity {
  COMMON, UNCOMMON, RARE, EPIC, LEGENDARY
}

enum ShieldType {
  FOUNDERS = 1, LEGENDARY
}

interface GiveawayShieldMint {
  to: string;
  stars?: Rarity;
  type?: ShieldType;
}

interface Data {
  giveawayShieldMint: GiveawayShieldMint;
  rarities: Rarity[];
  isLoading: boolean;
}

export default Vue.extend({
  data() {
    return {
      giveawayShieldMint: {
        to: '',
        stars: undefined,
        type: undefined,
      },
      rarities: [Rarity.COMMON, Rarity.UNCOMMON, Rarity.RARE, Rarity.EPIC, Rarity.LEGENDARY],
      shieldTypes: [ShieldType.FOUNDERS, ShieldType.LEGENDARY],
      isLoading: false,
      Rarity,
      ShieldType,
    } as Data;
  },

  computed: {
    mintShieldButtonDisabled(): boolean {
      return !isValidWeb3Address(this.giveawayShieldMint.to)
        || this.giveawayShieldMint.stars === undefined
        || this.giveawayShieldMint.type === undefined
        || this.isLoading;
    },
  },

  methods: {
    ...mapActions([
      'mintGiveawayShield',
    ]) as StoreMappedActions,

    async mintShield() {
      if (!isValidWeb3Address(this.giveawayShieldMint.to)
        || this.giveawayShieldMint.stars === undefined
        || this.giveawayShieldMint.type === undefined) {
        return;
      }
      try {
        this.isLoading = true;
        await this.mintGiveawayShield({
          to: this.giveawayShieldMint.to,
          stars: this.giveawayShieldMint.stars,
          type: this.giveawayShieldMint.type,
        });
        this.clearInputs();
      } finally {
        this.isLoading = false;
      }
    },

    clearInputs() {
      this.giveawayShieldMint = {
        to: '',
        stars: undefined,
        type: undefined,
      };
    }
  },
});
</script>

<style scoped>
</style>
