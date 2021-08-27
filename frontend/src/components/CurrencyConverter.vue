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
import Events from '@/events';
import {mapState} from 'vuex';

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
      showValueInUsd: false,
    };
  },
  computed: {
    ...mapState(['skillPriceInUsd']),
    formattedUsd(): string {
      return `$${(this.calculateSkillPriceInUsd()).toFixed(this.usdDecimals)}`;
    },
    formattedSkill(): string {
      return `${this.calculateSkillWithDecimals()} SKILL`;
    },
  },
  methods: {
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
  mounted() {
    this.checkStorage();
    Events.$on('setting:showSkillInUsd', () => this.checkStorage());
  },
});
</script>

<style>

</style>
