<template>
  <div class="skill-balance-display">
    <div><span class="bold">Balance</span>: {{ formattedSkillBalance }}</div>
    <button class="add-more-skill" @click="onAddMoreSkill">
      <i class="fas fa-plus-circle"></i>
    </button>
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

<style scoped>
.skill-balance-display {
  display: flex;
  align-items: center;
}

.add-more-skill {
  background: none;
  border: none;
  color: white;
  width: 48px;
  height: 100%;
  font-size: 0.8cm;
  padding: 0;
  margin-left: 10px;
  cursor: pointer;
}

.add-more-skill:hover {
  background: rgba(255, 255, 255, 0.25);
}
</style>
