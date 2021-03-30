<template>
  <div>
    <span class="bold">Balance</span>: {{ formattedSkillBalance }}
    <button @click="onAddMoreSkill">Add more</button>
  </div>
</template>

<script>
import { mapActions, mapState } from "vuex";

export default {
  computed: {
    ...mapState(["skillBalance"]),

    formattedSkillBalance() {
      const formatter = new Intl.NumberFormat("en-US", {
        style: "currency",
        currency: "ETH",
      });

      return formatter.format(this.skillBalance).replace(/ETH/g, "SKILL");
    },
  },

  methods: {
    ...mapActions(["addMoreSkill"]),

    async onAddMoreSkill() {
      const skillToAdd = prompt("How much SKILL do you want?", "100");

      try {
        await this.addMoreSkill(skillToAdd);
        alert("Successfully added SKILL to your balance!");
      } catch (e) {
        console.error(e);
        alert("Oh no, an error occured!");
      }
    },
  },

  watch: {
    skillBalance(balance, oldBalance) {
      console.log("BALANCE CHANGE:", balance, oldBalance, balance - oldBalance);
    },
  },
};
</script>

<style>
</style>
