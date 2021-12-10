<template>
  <div>
    <div>
      <h1>ARENA</h1>
      <span>Arena Tier: {{ characterInformation.tier || '-' }}</span>
      <br/>
      <span>Wager Left: {{ formattedWager || '-' }}</span>
    </div>
    <div>
      <p>
        DECISION TIME: {{ this.loading ? '...' : this.decisionTimeLeft}}
      </p>
      <button v-if="isCharacterInDuelQueue">IN-PROGRESS</button>
      <div v-else>
        <button v-if="!hasPendingDuel" @click="findMatch" :disabled="loading">Find match</button>
        <button v-else @click="preparePerformDuel" :disabled="loading || !decisionTimeLeft || isCharacterInDuelQueue">DUEL</button>
      </div>
      <button @click="reRollOpponent" :disabled="loading || !hasPendingDuel || isCharacterInDuelQueue">
        Re-roll Opponent {{ formattedReRollCost }} $SKILL
      </button>
      <button @click="leaveArena" :disabled="loading || isCharacterInDuelQueue">Leave arena</button>
    </div>
    <div>
      <h1>CHARACTER INFO: </h1>
      <span>element: {{ characterInformation.element }}</span>
      <br/>
      <span>name: {{ characterInformation.name }}</span>
      <br/>
      <span>level: {{ characterInformation.level }}</span>
      <br/>
      <span>rank: {{ characterInformation.rank }}</span>
      <br/>
      <pvp-weapon
        v-if="activeWeaponWithInformation.weaponId"
        :stars="activeWeaponWithInformation.information.stars + 1"
        :element="activeWeaponWithInformation.information.element"
        :weaponId="activeWeaponWithInformation.weaponId"
      />
      <pvp-shield
        v-if="activeShieldWithInformation.shieldId"
        :stars="activeShieldWithInformation.information.stars + 1"
        :element="activeShieldWithInformation.information.element"
        :shieldId="activeShieldWithInformation.shieldId"
      />
    </div>

    <div>
      <h1>OPPONENT INFO: </h1>
      <span>element: {{ opponentInformation.element }}</span>
      <br/>
      <span>name: {{ opponentInformation.name }}</span>
      <br/>
      <span>level: {{ opponentInformation.level }}</span>
      <br/>
      <span>rank: {{ opponentInformation.rank }}</span>
      <br/>
      <pvp-weapon
        v-if="opponentActiveWeaponWithInformation.weaponId"
        :stars="opponentActiveWeaponWithInformation.information.stars + 1"
        :element="opponentActiveWeaponWithInformation.information.element"
        :weaponId="opponentActiveWeaponWithInformation.weaponId"
      />
      <pvp-shield
        v-if="opponentActiveShieldWithInformation.shieldId"
        :stars="opponentActiveShieldWithInformation.information.stars + 1"
        :element="opponentActiveShieldWithInformation.information.element"
        :shieldId="opponentActiveShieldWithInformation.shieldId"
      />
    </div>
    <button @click="goBackToSummary" :disabled="loading">BACK TO ARENA SUMMARY</button>
    <!-- TODO: Get rank variation from contract -->
    <pvp-duel-modal
      v-if="duelResult.result"
      :result="duelResult.result"
      :attackerRoll="duelResult.attackerRoll"
      :defenderRoll="duelResult.defenderRoll"
      :skillEarned="duelResult.skillDifference"
      :rankVariation="duelResult.result === 'win' ? 5 : -3"
      :userCurrentRank="duelResult.rankDifference"
      @close-modal="handleCloseModal"
    />
  </div>
</template>

<script>
import { mapState } from 'vuex';
import PvPWeapon from '../../components/PvPWeapon.vue';
import PvPShield from '../../components/PvPShield.vue';
import PvPDuelModal from '../../components/PvPDuelModal.vue';
import BN from 'bignumber.js';
import { duelResultFromContract as formatDuelResult } from '../../../../../contract-models';

export default {
  inject: ['web3'],

  components: {
    'pvp-weapon': PvPWeapon,
    'pvp-shield': PvPShield,
    'pvp-duel-modal': PvPDuelModal
  },

  props: {
    characterInformation: {
      default: {
        tier: null,
        name: '',
        level: null,
        power: null,
        rank: null,
        element: null
      }
    },
    activeWeaponWithInformation: {
      default: {
        weaponId: null,
        information: {}
      }
    },
    activeShieldWithInformation: {
      default: {
        shieldId: null,
        information: {}
      }
    },
    opponentInformation: {
      default: {
        element: '',
        name: '',
        level: null,
        rank: null
      }
    },
    opponentActiveWeaponWithInformation: {
      default: {
        weaponId: null,
        information: {}
      }
    },
    opponentActiveShieldWithInformation: {
      default: {
        shieldId: null,
        information: {}
      }
    },
  },

  data() {
    return {
      loading: true,
      hasPendingDuel: false,
      decisionTimeLeft: 0,
      isWithinDecisionTime: false,
      wager: null,
      duelCost: null,
      reRollCost: null,
      duel: {
        attackerID: null,
        defenderID: null,
        createdAt: null,
        isPending: null
      },
      duelQueue: [],
      isCharacterInDuelQueue: false,
      duelResult: {
        attackerRoll: null,
        defenderRoll: null,
        skillDifference: null,
        rankDifference: null,
        result: ''
      }
    };
  },

  computed: {
    ...mapState(['contracts', 'currentCharacterId', 'defaultAccount']),

    formattedWager() {
      return new BN(this.wager).div(new BN(10).pow(18)).toFixed(2);
    },

    formattedDuelCost() {
      return new BN(this.duelCost).div(new BN(10).pow(18)).toFixed(2);
    },

    formattedReRollCost() {
      return new BN(this.reRollCost).div(new BN(10).pow(18)).toFixed(2);
    }
  },

  methods: {
    // TODO: delete this
    goBackToSummary() {
      this.$emit('goBackToSummary');
    },

    async leaveArena() {
      this.loading = true;
      try {
        await this.contracts().PvpArena.methods.withdrawFromArena(this.currentCharacterId).send({ from: this.defaultAccount });
        // TODO: Redirect to preparation view
      } catch (err) {
        console.log('leave arena error: ', err);
      }

      this.loading = false;
    },

    async findMatch() {
      this.loading = true;
      try {
        await this.contracts().PvpArena.methods.requestOpponent(this.currentCharacterId).send({ from: this.defaultAccount });
      } catch (err) {
        console.log('find match error: ', err);
      }

      this.duel = await this.contracts().PvpArena.methods.duelByAttacker(this.currentCharacterId).call();

      this.loading = false;
    },

    async reRollOpponent() {
      this.loading = true;
      try {
        await this.contracts().SkillToken.methods
          .approve(this.contracts().PvpArena.options.address, `${this.reRollCost}`).send({ from: this.defaultAccount });

        await this.contracts().PvpArena.methods.reRollOpponent(this.currentCharacterId).send({ from: this.defaultAccount });
      } catch (err) {
        console.log('reroll opponent error: ', err);
        this.loading = false;
        return;
      }

      this.duel = await this.contracts().PvpArena.methods.duelByAttacker(this.currentCharacterId).call();

      this.loading = false;
    },

    async listenForDuel(contracts) {
      const currentBlock = await this.web3.eth.getBlockNumber();

      const subscription = this.web3.eth.subscribe('newBlockHeaders', async () => {
        const duelFinishedResult = await contracts.PvpArena.getPastEvents('DuelFinished', {
          filter: { attacker: this.currentCharacterId },
          toBlock: 'latest',
          fromBlock: currentBlock
        });

        if (duelFinishedResult.length) {
          const formattedResult = formatDuelResult(duelFinishedResult[0].returnValues);

          this.duelResult.result = formattedResult.attackerRoll > formattedResult.defenderRoll ? 'win' : 'lose';
          this.duelResult.attackerRoll = formattedResult.attackerRoll;
          this.duelResult.defenderRoll = formattedResult.defenderRoll;
          this.duelResult.skillDifference = this.duelResult.result === 'win' ?
            +this.formattedDuelCost * 0.7 :
            -this.formattedDuelCost;
          // TODO: Make this prettier
          this.duelResult.rankDifference = this.duelResult.result === 'win' ?
            this.characterInformation.rank + 5 :
            this.characterInformation.rank - 3 <= 0 ?
              0 :
              this.characterInformation.rank - 3;

          subscription.unsubscribe((error, result) => {
            if (!error) {
              console.log(result);
            } else {
              console.log(error);
            }
          });
        }
      });
    },

    async preparePerformDuel() {
      try {
        await this.listenForDuel(this.contracts());

        await this.contracts().PvpArena.methods.preparePerformDuel(this.currentCharacterId).send({from: this.defaultAccount});
      } catch (err) {
        console.log('prepare perform duel error: ', err);
      }

      this.duelQueue = await this.contracts().PvpArena.methods.getDuelQueue().call({from: this.defaultAccount});

      this.isCharacterInDuelQueue = true;
    },

    clearDuelResult() {
      this.duelResult = {
        attackerRoll: null,
        defenderRoll: null,
        skillDifference: null,
        rankDifference: null
      };
    },

    handleCloseModal() {
      this.clearDuelResult();
    }
  },

  async created() {
    this.hasPendingDuel = await this.contracts().PvpArena.methods.hasPendingDuel(this.currentCharacterId).call();

    this.duelQueue = await this.contracts().PvpArena.methods.getDuelQueue().call({from: this.defaultAccount});

    if (this.duelQueue.includes(`${this.currentCharacterId}`)) {
      this.isCharacterInDuelQueue = true;

      await this.listenForDuel(this.contracts());
    }

    console.log('duel queue: ', this.duelQueue);
    // TODO: use this
    this.isWithinDecisionTime = await this.contracts().PvpArena.methods.isCharacterWithinDecisionTime(this.currentCharacterId).call();

    this.decisionSeconds = await this.contracts().PvpArena.methods.decisionSeconds().call();

    this.wager = await this.contracts().PvpArena.methods.getCharacterWager(this.currentCharacterId).call({ from: this.defaultAccount });

    this.duelCost = await this.contracts().PvpArena.methods.getDuelCost(this.currentCharacterId).call({ from: this.defaultAccount });

    this.reRollCost = this.duelCost * ((await this.contracts().PvpArena.methods.reRollFeePercent().call({ from: this.defaultAccount })) / 100);

    if (this.hasPendingDuel) {
      const timeNow = Math.floor((new Date()).getTime() / 1000);

      this.duel = await this.contracts().PvpArena.methods.duelByAttacker(this.currentCharacterId).call();

      this.decisionTimeLeft = (this.decisionSeconds - (timeNow - this.duel.createdAt), 0);

      // Note: This gives a 400 seconds decisionTimeLeft locally. Test if it's ok on testnet.
      this.timer = setInterval(() => {
        if (this.hasPendingDuel && !this.isCharacterInDuelQueue) {
          const timeNow = Math.floor((new Date()).getTime() / 1000);
          this.decisionTimeLeft = Math.max(this.decisionSeconds - (timeNow - this.duel.createdAt), 0);
        }
      }, 1000);

    } else {
      this.duel = {
        attackerID: null,
        defenderID: null,
        createdAt: null,
        isPending: null
      };

      this.decisionTimeLeft = 0;
    }

    this.duelQueue = await this.contracts().PvpArena.methods.getDuelQueue().call({from: this.defaultAccount});

    this.loading = false;
  },

  watch: {
    async duel(value) {
      this.loading = true;

      if (value.defenderID) {
        this.$emit('updateOpponentInformation', value.defenderID);
        this.hasPendingDuel = true;

        const timeNow = Math.floor((new Date()).getTime() / 1000);

        this.decisionTimeLeft = (this.decisionSeconds - (timeNow - this.duel.createdAt), 0);

        // Note: This gives a 400 seconds decisionTimeLeft locally. Test if it's ok on testnet.
        this.timer = setInterval(() => {
          if (this.hasPendingDuel && !this.isCharacterInDuelQueue) {
            const timeNow = Math.floor((new Date()).getTime() / 1000);
            this.decisionTimeLeft = Math.max(this.decisionSeconds - (timeNow - this.duel.createdAt), 0);
          }
        }, 1000);

      } else {
        this.$emit('clearOpponentInformation');
      }

      this.loading = false;
    },
  }
};

</script>
