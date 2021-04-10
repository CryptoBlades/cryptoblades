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
import BN from "bignumber.js";

export default {
  computed: {
    ...mapState(["skillBalance"]),

    formattedSkillBalance() {
      return BN(this.skillBalance).dividedBy(1e18).toFixed(4) + " SKILL";
    },
  },

  methods: {
    ...mapActions(["addMoreSkill"]),

    async onAddMoreSkill() {
      const skillToAdd = BN(prompt("How much SKILL do you want?", "5")).multipliedBy(1e18);

      try {
        await this.addMoreSkill(skillToAdd.toFixed());
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
  font-size: 1.1rem;
}

.add-more-skill {
  background: none;
  border: none;
  color: rgba(255, 255, 255, 0.6);
  height: 100%;
  font-size: 1.3em;
  padding: 0 0.5rem;
  margin-left: 0.625rem;
  cursor: pointer;
}

.add-more-skill:hover {
  color: white;
  background: rgba(255, 255, 255, 0.25);
}
</style>
