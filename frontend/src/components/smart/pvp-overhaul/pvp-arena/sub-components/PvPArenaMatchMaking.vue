<template>
<div>
  <div>arena matchmaking</div>
  <div>
    <p>
      {{ this.loading ? '...' : this.decisionTimeLeft}}
    </p>
    <button @click="leaveArena" :disabled="loading">Leave arena</button>
    <button v-if="!hasPendingDuel" @click="findMatch" :disabled="loading">Find match</button>
    <button v-if="hasPendingDuel"  @click="reRollOpponent" :disabled="loading || !hasPendingDuel">Re-roll Opponent</button>
  </div>
</div>
</template>

<script>
import { mapState } from 'vuex';

export default {
  inject: ['web3'],
  data() {
    return {
      loading: true,
      hasPendingDuel: false,
      decisionTimeLeft: 0,
    };
  },
  props: {

  },

  computed: {
    ...mapState(['contracts', 'currentCharacterId', 'defaultAccount'])
  },

  methods: {
    async leaveArena() {
      this.loading = true;
      try {
        await this.contracts().PvpArena.methods.withdrawFromArena(this.currentCharacterId).send({ from: this.defaultAccount });
        // TODO: Redirect to preparation view
      } catch (err) {
        console.error(err);
      }

      this.loading = false;
    },

    async findMatch() {
      this.loading = true;
      try {
        await this.contracts().PvpArena.methods.requestOpponent(this.currentCharacterId).send({ from: this.defaultAccount });
      } catch (err) {
        console.log('err', err);
        console.error(err);
      }

      this.loading = false;
    },

    async reRollOpponent() {
      this.loading = true;
      try {
        // await this.contracts().SkillToken.methods.approve(this.contracts().PvpArena.options.address, this.web3.utils.toWei(this.rerollCost)).send({ from: this.defaultAccount });
        await this.contracts().PvpArena.methods.reRollOpponent(this.currentCharacterId).send({ from: this.defaultAccount });
      } catch (err) {
        console.log('err', err);
        console.error(err);
        this.loading = false;
        return;
      }


      this.duel = await this.contracts().PvpArena.methods.getDuel(this.currentCharacterId).call();
      this.loading = false;
    }
  },

  async created() {
    // TODOS:
    // * [ ] Is player in an active duel
    // * [ ] Is player waiting for a duel to process
    // * [ ] Reroll opponent
    // * [x] Find match functionality
    // * [x] Leave arena functionality
    this.hasPendingDuel = await this.contracts().PvpArena.methods.hasPendingDuel(this.currentCharacterId).call();
    this.isWithinDecisionTime = await this.contracts().PvpArena.methods.isCharacterWithinDecisionTime(this.currentCharacterId).call();
    this.decisionSeconds = await this.contracts().PvpArena.methods.decisionSeconds().call();

    // TODO: set up reroll cost
    // this.reRollCost = 

    console.log('this.hasPendingDuel', this.hasPendingDuel);
    console.log('this.isWithinDecisionTime', this.isWithinDecisionTime);
    if (this.hasPendingDuel) {
      const timeNow = Math.floor((new Date()).getTime() / 1000);
      this.duel = await this.contracts().PvpArena.methods.duelByAttacker(this.currentCharacterId).call();
      this.decisionTimeLeft = (this.decisionSeconds - (timeNow - this.duel.createdAt), 0);

      this.timer = setInterval(() => {
        if (this.hasPendingDuel) {
          const timeNow = Math.floor((new Date()).getTime() / 1000);
          this.decisionTimeLeft = Math.max(this.decisionSeconds - (timeNow - this.duel.createdAt), 0);
        }
      }, 1000);
    }

    this.loading = false;

  }
};

</script>
