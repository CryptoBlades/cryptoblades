<template>
  <div class="p-1">
    <h2 class="mt-2">{{ $t('admin.raid.setRaidXpRewardCurrentDefault120', {xpReward: currentRaidXpReward}) }}</h2>
    <div class="d-flex align-items-center gap-3">
      <b-form-input v-model="newRaidXpReward" :placeholder="$t('admin.raid.raidXpReward')" number type="number"/>
      <b-button @click="setNewRaidXpReward()" :disabled="setNewRaidXpRewardButtonDisabled"
                variant="primary" class="text-nowrap">
        {{ $t('admin.raid.setRaidXpReward') }}
      </b-button>
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import {mapActions} from 'vuex';

interface StoreMappedActions {
  getRaidXpReward(): Promise<number>;

  setRaidXpReward(payload: { xp: number }): Promise<void>;
}

interface Data {
  newRaidXpReward?: number;
  currentRaidXpReward?: number;
  isLoading: boolean;
}

export default Vue.extend({
  data() {
    return {
      newRaidXpReward: undefined,
      currentRaidXpReward: undefined,
      isLoading: false,
    } as Data;
  },

  computed: {
    setNewRaidXpRewardButtonDisabled(): boolean {
      return this.newRaidXpReward === undefined
        || this.isLoading;
    },
  },

  methods: {
    ...mapActions([
      'getRaidXpReward',
      'setRaidXpReward',
    ]) as StoreMappedActions,

    async setNewRaidXpReward() {
      if (this.setNewRaidXpRewardButtonDisabled) return;
      try {
        this.isLoading = true;
        await this.setRaidXpReward({xp: this.newRaidXpReward!});
        await this.fetchCurrentRaidXpReward();
        this.newRaidXpReward = undefined;
      } finally {
        this.isLoading = false;
      }
    },

    async fetchCurrentRaidXpReward() {
      try {
        this.isLoading = true;
        this.currentRaidXpReward = await this.getRaidXpReward();
      } finally {
        this.isLoading = false;
      }
    }
  },

  async mounted() {
    await this.fetchCurrentRaidXpReward();
  }
});
</script>

<style scoped>
</style>
