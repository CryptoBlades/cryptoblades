<template>
  <div class="p-1">
    <h2 class="mt-2">{{ $t('admin.burningManager.mintGiveawaySoul') }}</h2>
    <div class="d-flex align-items-center gap-3">
      <b-form-input v-model="giveawaySoulMint.user" :placeholder="$t('admin.burningManager.playerAddress')"/>
      <b-form-input v-model="giveawaySoulMint.soulAmount" :placeholder="$t('admin.burningManager.soulAmount')"
                    type="number"
                    number min="0"/>
      <b-button @click="mintGiveawaySoul()" :disabled="mintGiveawaySoulDisabled()" variant="primary"
                class="text-nowrap">
        {{ $t('admin.burningManager.mintSoul') }}
      </b-button>
    </div>
    <h2 class="mt-2">{{
        $t('admin.burningManager.setSoulMultiplierCurrent', {multiplier: currentSoulMultiplier})
      }}</h2>
    <div class="d-flex align-items-center gap-3">
      <b-form-input v-model="newSoulMultiplier" :placeholder="$t('admin.weapons.multiplier')" number type="number"/>
      <b-button @click="setNewSoulMultiplier()" :disabled="setNewSoulMultiplierButtonDisabled"
                variant="primary" class="text-nowrap">
        {{ $t('admin.burningManager.setSoulMultiplier') }}
      </b-button>
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import {mapActions} from 'vuex';
import {fromWeiEther, isValidWeb3Address} from '../../../utils/common';

interface StoreMappedActions {
  giveAwaySoul(payload: { user: string, soulAmount: number }): Promise<void>;

  getSoulMultiplier(): Promise<string>;

  setSoulMultiplier(payload: { multiplier: number }): Promise<void>;
}

interface GiveawaySoulMint {
  user: string;
  soulAmount?: number;
}

interface Data {
  giveawaySoulMint: GiveawaySoulMint;
  isLoading: boolean;
  currentSoulMultiplier?: number;
  newSoulMultiplier?: number;
}

export default Vue.extend({
  data() {
    return {
      giveawaySoulMint: {
        user: '',
        soulAmount: undefined,
      },
      currentSoulMultiplier: undefined,
      newSoulMultiplier: undefined,
      isLoading: false,
    } as Data;
  },

  computed: {
    setNewSoulMultiplierButtonDisabled(): boolean {
      return this.newSoulMultiplier === undefined
        || this.isLoading;
    },
  },

  methods: {
    ...mapActions([
      'giveAwaySoul',
      'getSoulMultiplier',
      'setSoulMultiplier',
    ]) as StoreMappedActions,

    mintGiveawaySoulDisabled(): boolean {
      return !isValidWeb3Address(this.giveawaySoulMint.user)
        || this.giveawaySoulMint.soulAmount === undefined
        || this.isLoading;
    },

    async mintGiveawaySoul() {
      if (!isValidWeb3Address(this.giveawaySoulMint.user)
        || this.giveawaySoulMint.soulAmount === undefined) {
        return;
      }
      try {
        this.isLoading = true;
        await this.giveAwaySoul({
          user: this.giveawaySoulMint.user,
          soulAmount: this.giveawaySoulMint.soulAmount,
        });
        this.clearInputs();
      } finally {
        this.isLoading = false;
      }
    },

    async setNewSoulMultiplier() {
      if (this.newSoulMultiplier === undefined) return;
      try {
        this.isLoading = true;
        await this.setSoulMultiplier({
          multiplier: this.newSoulMultiplier,
        });
        await this.fetchCurrentSoulMultiplier();
        this.newSoulMultiplier = undefined;
      } finally {
        this.isLoading = false;
      }
    },

    clearInputs() {
      this.giveawaySoulMint = {
        user: '',
        soulAmount: undefined,
      };
      this.newSoulMultiplier = undefined;
    },

    async fetchCurrentSoulMultiplier() {
      try {
        this.isLoading = true;
        this.currentSoulMultiplier = +fromWeiEther(await this.getSoulMultiplier());
      } finally {
        this.isLoading = false;
      }
    },
  },

  async mounted() {
    await this.fetchCurrentSoulMultiplier();
  },
});
</script>

<style scoped>
</style>
