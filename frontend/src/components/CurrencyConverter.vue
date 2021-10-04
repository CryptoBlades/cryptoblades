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
import { toBN } from '@/utils/common';
import Events from '@/events';
import { mapState } from 'vuex';
import BigNumber from 'bignumber.js';

export default Vue.extend({
  props: {
    skill: {
      type: String,
      default: '0',
    },
    skillMinDecimals: {
      type: Number,
      default: 2,
    },
    skillMaxDecimals: {
      type: Number,
      default: 4,
    },
    usdDecimals: {
      type: Number,
      default: 2,
    },
    showValueInSkillOnly: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      showValueInUsd: false,
    };
  },
  computed: {
    ...mapState(['skillPriceInUsd']),
    formattedUsd(): string {
      return `$${this.calculateSkillPriceInUsd().toFixed(this.usdDecimals)}`;
    },
    formattedSkill(): string {
      return `${this.calculateSkillWithDecimals()} SKILL`;
    },
  },
  methods: {
    calculateSkillPriceInUsd(): number {
      return ((this.skill as unknown as number) *
        this.skillPriceInUsd) as unknown as number;
    },
    calculateSkillWithDecimals(): string {
      const parsedSkill = toBN(this.skill);
      const decimalPlaces = this.countDecimalPlaces(parsedSkill);

      if (this.skillMaxDecimals < decimalPlaces) {
        return `~${parsedSkill.toFixed(this.skillMaxDecimals)}`;
      }

      if (
        decimalPlaces > this.skillMinDecimals &&
        decimalPlaces <= this.skillMaxDecimals
      ) {
        return parsedSkill.toString();
      }

      return parsedSkill.toFixed(this.skillMinDecimals);
    },

    countDecimalPlaces(value: BigNumber) {
      if (Math.floor(+value.valueOf()).toString() === value.valueOf()) return 0;
      return value.toString().split('.')[1].length || 0;
    },

    checkStorage() {
      this.showValueInUsd = localStorage.getItem('showSkillInUsd') === 'true';
    },
  },
  mounted() {
    this.checkStorage();
    Events.$on('setting:showSkillInUsd', () => this.checkStorage());
  },
});
</script>

<style>
</style>
