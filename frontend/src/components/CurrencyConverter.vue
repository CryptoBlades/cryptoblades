<template>
  <span v-if="showValueInSkillOnly || !showValueInUsd">
    {{ formattedSkill }}
  </span>
  <span v-else-if="showValueInUsd">
    {{ formattedUsd }}
  </span>
</template>

<script lang="ts">

import Vue from 'vue';
import {toBN} from '@/utils/common';
import axios from 'axios';
import Events from '@/events';

export default Vue.extend({
  props: {
    skill: {
      type: String,
      default: '0'
    },
    skillMinDecimals: {
      type: Number,
      default: 2
    },
    skillMaxDecimals: {
      type: Number,
      default: 4
    },
    usdDecimals: {
      type: Number,
      default: 2
    },
    showValueInSkillOnly: {
      type: Boolean,
      default: false
    }
  },
  data() {
    return {
      skillPriceInUsd: 0,
      showValueInUsd: false,
    };
  },
  computed: {
    formattedUsd(): string {
      return `$${(this.calculateSkillPriceInUsd()).toFixed(this.usdDecimals)}`;
    },
    formattedSkill(): string {
      return `${this.calculateSkillWithDecimals()} SKILL`;
    },
  },
  methods: {
    async fetchPrices(): Promise<void> {
      if (!this.showValueInSkillOnly) {
        const response = await axios.get('https://api.coingecko.com/api/v3/simple/price?ids=cryptoblades,binancecoin&vs_currencies=usd');
        this.skillPriceInUsd = response.data?.cryptoblades.usd;
      }
    },
    calculateSkillPriceInUsd(): number {
      return this.skill as unknown as number * this.skillPriceInUsd as unknown as number;
    },
    calculateSkillWithDecimals(): string {
      const parsedSkill = toBN(this.skill);

      if (parsedSkill < toBN(Math.pow(10, -this.skillMaxDecimals))) {
        return '< ' + Math.pow(10, -this.skillMaxDecimals).toFixed(this.skillMaxDecimals);
      }

      for (let i = this.skillMaxDecimals - 1; i >= this.skillMinDecimals; i--) {
        if (parsedSkill < toBN(Math.pow(10, -i))) {
          return parsedSkill.toFixed(i + 1);
        }
      }

      return parsedSkill.toFixed(this.skillMinDecimals);
    },
    checkStorage() {
      this.showValueInUsd = localStorage.getItem('showSkillInUsd') === 'true';
    },
  },
  async mounted() {
    this.checkStorage();
    Events.$on('setting:showSkillInUsd', () => this.checkStorage());
    await this.fetchPrices();
  },
});
</script>

<style>

</style>
