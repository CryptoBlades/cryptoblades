<template>
  <div class="p-1">
    <h2>{{ $t('admin.weapons.incrementDecrementDustSupplies') }}</h2>
    <b-form-group class="m-3">
      <b-form-radio v-model="incrementDust" :value="true">
        {{ $t('admin.weapons.incrementDustSupplies') }}
      </b-form-radio>
      <b-form-radio v-model="incrementDust" :value="false">
        {{ $t('admin.weapons.decrementDustSupplies') }}
      </b-form-radio>
    </b-form-group>
    <div class="d-flex align-items-center gap-3">
      <b-form-input v-model="playerAddress" :placeholder="$t('admin.weapons.playerAddress')"/>
      <b-form-input v-model="amountLB" :placeholder="$t('admin.weapons.amountLB')" type="number" number min="0"
                    max="3"/>
      <b-form-input v-model="amount4B" :placeholder="$t('admin.weapons.amount4B')" type="number" number min="0"/>
      <b-form-input v-model="amount5B" :placeholder="$t('admin.weapons.amount5B')" type="number" number min="0"/>
      <b-button @click="incrementDust ? incrementSupplies() : decrementSupplies()" :disabled="suppliesButtonDisabled()"
                variant="primary"
                class="text-nowrap">
        {{ incrementDust ? $t('admin.weapons.incrementDustSupplies') : $t('admin.weapons.decrementDustSupplies') }}
      </b-button>
    </div>
    <h2 class="mt-2">{{ $t('admin.weapons.mintGiveawayWeapon') }}</h2>
    <div class="d-flex align-items-center gap-3">
      <b-form-input v-model="giveawayWeaponMint.to" :placeholder="$t('admin.weapons.playerAddress')"/>
      <b-form-select class="mt-2 mb-2" v-model="giveawayWeaponMint.stars">
        <b-form-select-option :value="undefined" disabled>
          {{ $t('admin.weapons.pleaseSelectStars') }}
        </b-form-select-option>
        <b-form-select-option v-for="rarity in weaponRarities" :key="rarity" :value="rarity">
          {{ $t(`admin.weapons.rarities.${Rarity[rarity]}`) }}
        </b-form-select-option>
      </b-form-select>
      <b-form-select class="mt-2 mb-2" v-model="giveawayWeaponMint.chosenElement">
        <b-form-select-option :value="undefined" disabled>
          {{ $t('admin.weapons.pleaseSelectElement') }}
        </b-form-select-option>
        <b-form-select-option v-for="element in weaponElements" :key="element" :value="element">
          {{ $t(`admin.weapons.elements.${Element[element]}`) }}
        </b-form-select-option>
      </b-form-select>
      <b-button @click="mintWeapon()" :disabled="mintWeaponButtonDisabled()" variant="primary" class="text-nowrap">
        {{ $t('admin.weapons.mintWeapon') }}
      </b-button>
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import {mapActions} from 'vuex';
import {isValidWeb3Address} from '../../../utils/common';

interface StoreMappedActions {
  incrementDustSupplies(payload: { playerAddress: string, amountLB: number, amount4B: number, amount5B: number }): Promise<void>;

  decrementDustSupplies(payload: { playerAddress: string, amountLB: number, amount4B: number, amount5B: number }): Promise<void>;

  mintGiveawayWeapon(payload: { to: string, stars: number, chosenElement: number }): Promise<void>;
}

enum Rarity {
  COMMON, UNCOMMON, RARE, EPIC, LEGENDARY
}

enum Element {
  RANDOM = 100,
  FIRE = 0,
  WATER = 1,
  EARTH = 2,
  LIGHTNING = 3,
}

interface GiveawayWeaponMint {
  to: string;
  stars?: Rarity;
  chosenElement?: Element;
}

interface Data {
  playerAddress: string;
  amountLB?: number;
  amount4B?: number;
  amount5B?: number;
  incrementDust: boolean;
  giveawayWeaponMint: GiveawayWeaponMint;
  weaponRarities: Rarity[];
  weaponElements: Element[];
  isLoading: boolean;
}

export default Vue.extend({
  data() {
    return {
      playerAddress: '',
      amountLB: undefined,
      amount4B: undefined,
      amount5B: undefined,
      incrementDust: true,
      giveawayWeaponMint: {
        to: '',
        stars: undefined,
        chosenElement: undefined,
      },
      weaponRarities: [Rarity.COMMON, Rarity.UNCOMMON, Rarity.RARE, Rarity.EPIC, Rarity.LEGENDARY],
      weaponElements: [Element.FIRE, Element.WATER, Element.EARTH, Element.LIGHTNING, Element.RANDOM],
      isLoading: false,
      Rarity,
      Element,
    } as Data;
  },

  methods: {
    ...mapActions(['incrementDustSupplies', 'decrementDustSupplies', 'mintGiveawayWeapon']) as StoreMappedActions,

    suppliesButtonDisabled(): boolean {
      return !isValidWeb3Address(this.playerAddress)
        || this.amountLB === undefined
        || this.amount4B === undefined
        || this.amount5B === undefined
        || this.isLoading;
    },

    mintWeaponButtonDisabled(): boolean {
      return !isValidWeb3Address(this.giveawayWeaponMint.to)
        || this.giveawayWeaponMint.stars === undefined
        || this.giveawayWeaponMint.chosenElement === undefined
        || this.isLoading;
    },

    async incrementSupplies() {
      if (!isValidWeb3Address(this.playerAddress)
        || this.amountLB === undefined
        || this.amount4B === undefined
        || this.amount5B === undefined) {
        return;
      }
      try {
        this.isLoading = true;
        await this.incrementDustSupplies({
          playerAddress: this.playerAddress,
          amountLB: this.amountLB,
          amount4B: this.amount4B,
          amount5B: this.amount5B,
        });
        this.clearInputs();
      } finally {
        this.isLoading = false;
      }
    },

    async decrementSupplies() {
      if (!isValidWeb3Address(this.playerAddress)
        || this.amountLB === undefined
        || this.amount4B === undefined
        || this.amount5B === undefined) {
        return;
      }
      try {
        this.isLoading = true;
        await this.decrementDustSupplies({
          playerAddress: this.playerAddress,
          amountLB: this.amountLB,
          amount4B: this.amount4B,
          amount5B: this.amount5B,
        });
        this.clearInputs();
      } finally {
        this.isLoading = false;
      }
    },

    async mintWeapon() {
      if (!isValidWeb3Address(this.giveawayWeaponMint.to)
        || this.giveawayWeaponMint.chosenElement === undefined
        || this.giveawayWeaponMint.stars === undefined) {
        return;
      }
      try {
        this.isLoading = true;
        await this.mintGiveawayWeapon({
          to: this.giveawayWeaponMint.to,
          stars: this.giveawayWeaponMint.stars,
          chosenElement: this.giveawayWeaponMint.chosenElement,
        });
        this.clearInputs();
      } finally {
        this.isLoading = false;
      }
    },

    clearInputs() {
      this.playerAddress = '';
      this.amountLB = undefined;
      this.amount4B = undefined;
      this.amount5B = undefined;
      this.giveawayWeaponMint = {
        to: '',
        stars: undefined,
        chosenElement: undefined,
      };
    }
  },
});
</script>

<style scoped>
</style>
