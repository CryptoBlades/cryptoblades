<template>
  <div class="wrapper">
    <nav>
      <div class="navTitle">Arena</div>
      <div class="navStats">
        <div>
          <span>Arena tier:</span>
          <span>{{ characterInformation.tier || '-' }}</span>
        </div>
        <div>
          <span>Wager left:</span>
          <span>{{ formattedWager || '-' }}</span>
        </div>
      </div>
    </nav>
    <div class="bottom">
      <div class="characterWrapper">
        <div class="elementWrapper">
          <img :src="getCharacterElementSrc" alt="element" />
        </div>
        <div class="characterImageWrapper">
          <pvp-character :characterId="currentCharacterId" />
        </div>
        <div class="info">
          <h1 class="characterName">{{ characterInformation.name }}</h1>
          <div class="infoDetails">
            <span>Level: {{ characterInformation.level }}</span>
            <pvp-separator vertical class="separator" />
            <span>Rank: {{ characterInformation.rank }}</span>
          </div>
        </div>
        <div class="weapons">
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
      </div>
      <div class="middleButtons">
        <div v-if="this.loading">
          <img class="spinner" src="../../../../../assets/loadingSpinner.svg" />
        </div>
        <p v-else>{{ this.decisionTimeLeft }}</p>
        <pvp-button v-if="isCharacterInDuelQueue" buttonText="IN-PROGRESS"/>
        <div v-else class="matchButtonsWrapper">
          <pvp-button v-if="!hasPendingDuel" @click="findMatch" :disabled="loading" buttonText="FIND MATCH" />
          <pvp-button v-else
          @click="preparePerformDuel" :disabled="loading || !decisionTimeLeft || isCharacterInDuelQueue" :duelButton="true" buttonText="DUEL" />
        </div>
        <pvp-button
          class="reRollOpponentButton"
          @click="reRollOpponent" :disabled="loading || !hasPendingDuel || isCharacterInDuelQueue"
          buttonText="Re-roll Opponent"
          :buttonsubText="'$SKILL: ' + formattedReRollCost"
          :secondary="true"
        />
        <pvp-button
          @click="leaveArena"
          :disabled="loading || isCharacterInDuelQueue"
          buttonText="Leave Arena"
          :secondary="true"
        />
      </div>
      <div class="characterWrapper">
        <div class="elementWrapper">
          <img :src="getOpponentElementSrc" alt="opponent element" />
        </div>
        <div class="characterImageWrapper">
          <!-- <pvp-character :characterId="id" /> -->
        </div>
        <div class="info">
          <h1 class="characterName">{{ opponentInformation.name }}</h1>
          <div class="infoDetails">
            <span>Level: {{ opponentInformation.level }}</span>
            <pvp-separator vertical class="separator" />
            <span>Rank: {{ opponentInformation.rank }}</span>
          </div>
        </div>
        <div class="weapons">
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
      </div>
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
// import PvPCharacter from '../../components/PvPCharacter.vue';
import BN from 'bignumber.js';
import { mapState } from 'vuex';
import PvPWeapon from '../../components/PvPWeapon.vue';
import PvPShield from '../../components/PvPShield.vue';
import PvPSeparator from '../../components/PvPSeparator.vue';
import PvPCharacter from '../../components/PvPCharacter.vue';
import PvPButton from '../../components/PvPButton.vue';
import fireIcon from '../../../../../assets/elements/fire.png';
import waterIcon from '../../../../../assets/elements/water.png';
import earthIcon from '../../../../../assets/elements/earth.png';
import lightningIcon from '../../../../../assets/elements/lightning.png';
import PvPDuelModal from '../../components/PvPDuelModal.vue';
import { duelResultFromContract as formatDuelResult } from '../../../../../contract-models';
export default {
  inject: ['web3'],

  components: {
    'pvp-weapon': PvPWeapon,
    'pvp-shield': PvPShield,
    'pvp-character': PvPCharacter,
    'pvp-separator': PvPSeparator,
    'pvp-button': PvPButton,
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
    },

    getCharacterElementSrc() {
      if (this.characterInformation.element === 'Fire') {
        return fireIcon;
      }
      if (this.characterInformation.element === 'Water') {
        return waterIcon;
      }
      if (this.characterInformation.element === 'Earth') {
        return earthIcon;
      }
      return lightningIcon;
    },

    getOpponentElementSrc() {
      if (this.opponentInformation.element === 'fire') {
        return fireIcon;
      }
      if (this.opponentInformation.element === 'water') {
        return waterIcon;
      }
      if (this.opponentInformation.element === 'earth') {
        return earthIcon;
      }
      return lightningIcon;
    },
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
            +this.characterInformation.rank + 5 :
            +this.characterInformation.rank - 3 <= 0 ?
              0 :
              +this.characterInformation.rank - 3;

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

    async handleCloseModal() {
      this.clearDuelResult();
      this.decisionTimeLeft = 0;

      this.hasPendingDuel = false;

      this.duel = {
        attackerID: null,
        defenderID: null,
        createdAt: null,
        isPending: null
      };

      this.isCharacterInDuelQueue = false;

      this.wager = await this.contracts().PvpArena.methods.getCharacterWager(this.currentCharacterId).call({ from: this.defaultAccount });

      if (this.wager < this.duelCost) {
        this.$emit('kickCharacterFromArena');
      }
    }
  },

  async created() {
    this.hasPendingDuel = await this.contracts().PvpArena.methods.hasPendingDuel(this.currentCharacterId).call();

    this.duelQueue = await this.contracts().PvpArena.methods.getDuelQueue().call({from: this.defaultAccount});

    if (this.duelQueue.includes(`${this.currentCharacterId}`)) {
      this.isCharacterInDuelQueue = true;

      await this.listenForDuel(this.contracts());
    }


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

<style scoped lang="scss">
.wrapper {
  display: flex;
  flex-direction: column;
  min-height: 100vh;
  margin-top: 3.5rem;
}
span, p, li, button {
  font-family: 'Roboto';
}
  nav {
    display: flex;
    width: 100%;
    justify-content: space-between;
    margin-bottom: 4rem;
    padding-bottom: 0.5rem;
    border-bottom: 1px solid #363636;
    .navTitle {
      color: #cec198;
      font-size: 1.25rem;
      font-family: 'Trajan';
    }
    .navStats {
      display: flex;
      div:nth-of-type(2) {
        margin-left: 1.25rem;
        margin-right: 1.25rem;
      }
      div {
        display: flex;
        align-items: flex-end;
        font-size: 0.875rem;
        line-height: 1.25rem;
        span:first-of-type {
          margin-right: 0.25rem;
          color: #cec198;
        }
        span:last-of-type {
          color: #ffffff;
        }
      }
    }
  }
.bottom {
  display: flex;
  flex-direction: row;
  width: 100%;
  justify-content: center;
  .elementWrapper {
    position: absolute;
    display: flex;
    height: 2.5rem;
    width: 2.5rem;
    top: -5.35%;
    left: 0;
    right: 0;
    padding: 0.4rem;
    transform: rotate(45deg);
    border: 1px solid #edcd90;
    margin-right: auto;
    margin-left: auto;
    background-color: #000000;
    img {
      transform: rotate(-45deg);
    }
  }
}
.characterWrapper,
.middleButtons {
  display: flex;
  height: 25rem;
  justify-content: flex-end;
  align-items: center;
}
.characterWrapper {
  position: relative;
  flex-direction: column;
  width: 35%;
  background-color: #000;
  border: 1px solid #cec198;
  @media screen and (min-width: 1240px) {
    width: 30%;
  }
  @media screen and (min-width: 1440px) {
    width: 25%;
  }
  @media screen and (min-width: 1680px) {
    width: 20%;
  }
  @media screen and (min-width: 2560px) {
    width: 15%;
  }
  .characterImageWrapper {
    display: flex;
    margin-right: auto;
    margin-left: auto;
    width: 55%;
    height: 55%;
    margin-bottom: 7rem;
  }
  .info {
    position: absolute;
    bottom: 0;
    display: flex;
    width: 100%;
    flex-direction: column;
    align-items: center;
    color: #ffffff;
    margin-bottom: 2.5rem;
    .characterName {
      margin-bottom: 0.3rem;
      color: #EDCD90;
      font-size: 1.25rem;
      line-height: 1.75rem;
      font-family: 'Trajan';
    }
    .infoDetails {
      height: 1.25rem;
      display: flex;
      align-items: center;
      vertical-align: middle;
      font-size: 0.875rem;
      line-height: 1.25rem;
      .separator {
        margin-right: 1.25rem;
        margin-left: 1.25rem;
      }
    }
  }
  .weapons {
    position: absolute;
    bottom: -15%;
    display: flex;
    left: 0;
    justify-content: center;
    right: 0;
    margin-right: auto;
    margin-left: auto;
    div:first-of-type {
      margin-right: 1rem;
    }
  }
}
.middleButtons {
  flex-direction: column;
  margin-right: 3rem;
  margin-left: 3rem;
  width: 12rem;
  .matchButtonsWrapper {
    width: 100%;
  }
  .reRollOpponentButton {
    margin-top: 1.5rem;
  }
  .spinner {
    margin-bottom: 4rem;
    animation: spin 1s linear infinite;
    @keyframes spin {
      from {
        transform: rotate(0deg);
      }
      to {
        transform: rotate(360deg);
      }
    }
  }
  .findMatchButton {
    margin-bottom: 5rem;
  }
  button {
    margin-bottom: 1.5rem;
    width: 100%;
  }
  button:last-of-type {
    margin-bottom: 0;
  }
  p {
    font-size: 2.75rem;
    margin-bottom: 4rem;
    color: white;
  }
  @media screen and (min-width: 1280px) {
    margin-right: 5rem;
    margin-left: 5rem;
  }
}
</style>