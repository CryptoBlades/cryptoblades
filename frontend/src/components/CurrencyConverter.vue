<template>
  <span v-if="showValueInSkillOnly || (!showValueInUsd && !showValueInKingOnly)">{{ formattedSkill }}</span>
  <span v-else-if="showValueInKingOnly">{{ formattedKing }}</span>
  <span v-else-if="showValueInUsd">{{ formattedUsd }}</span>
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
    king: {
      type: String,
      default: '0',
    },
    minDecimals: {
      type: Number,
      default: 2,
    },
    maxDecimals: {
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
    showValueInKingOnly: {
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
    formattedKing(): string {
      return `${this.calculateKingWithDecimals()} KING`;
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

      if (this.maxDecimals < decimalPlaces) {
        return `~${parseFloat(parsedSkill.toFixed(this.maxDecimals))}`;
      }

      if (
        decimalPlaces > this.minDecimals &&
        decimalPlaces <= this.maxDecimals
      ) {
        return parsedSkill.toString();
      }

      return parsedSkill.toFixed(this.minDecimals);
    },

    calculateKingWithDecimals(): string {
      const parsedKing = toBN(this.king);
      const decimalPlaces = this.countDecimalPlaces(parsedKing);

      if (this.maxDecimals < decimalPlaces) {
        return `~${parseFloat(parsedKing.toFixed(this.maxDecimals))}`;
      }

      if (
        decimalPlaces > this.minDecimals &&
        decimalPlaces <= this.maxDecimals
      ) {
        return parsedKing.toString();
      }

      return parsedKing.toFixed(this.minDecimals);
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
