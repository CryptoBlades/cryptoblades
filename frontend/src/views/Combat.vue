<template>
  <div class="body main-font">
    <div v-if="ownWeapons.length > 0 && ownCharacters.length > 0">
      <div class="row" v-if="error !== null">
        <div class="col error">Error: {{ error }}</div>
      </div>

      <div class="row">
        <div class="col">
          <div class="payout-info">{{getPayoutString()}}</div>
        </div>
      </div>

      <div class="row">
        <div class="col text-center">
          <div class="combat-hints">
            <span class="fire-icon" /> »
            <span class="earth-icon" /> »
            <span class="lightning-icon" /> »
            <span class="water-icon" /> »
            <span class="fire-icon" />

            <Hint text="The elements affect power:<br>
              <br>Character vs Enemy: bonus or penalty as shown above
              <br>Character and Weapon match gives bonus" />
          </div>
        </div>
      </div>

      <div class="row" v-if="resultsAvailable">
        <div class="col">
          <CombatResults v-if="resultsAvailable" :results="fightResults" />
        </div>
      </div>

      <div class="row">
        <div class="col">
          <div class="message-box" v-if="!currentCharacter">
            You need to select a character to do battle.
          </div>

          <div class="message-box" v-if="currentCharacter && currentCharacterStamina < 40">
            You need 40 stamina to do battle.
          </div>

          <div class="message-box" v-if="timeMinutes === 59 && timeSeconds >= 30">
            You cannot do battle during the last 30 seconds of the hour. Stand fast!
          </div>
        </div>
      </div>

      <div class="row" v-if="currentCharacterStamina >= 40">
        <div class="col">

          <div class="row">
            <div class="col">
              <div class="waiting" v-if="waitingResults" margin="auto">
                <i class="fas fa-spinner fa-spin"></i>
                Waiting for fight results...
              </div>
            </div>
          </div>

          <div class="row">
            <div class="col">
              <div class="header-row">
                <Hint text="Your weapon multiplies your power<br>
                  <br>+Stats determine the multiplier
                  <br>Stat element match with character gives greater bonus" />
                <h1>Choose a weapon</h1>
              </div>

              <weapon-grid v-model="selectedWeaponId" />
            </div>
          </div>

          <div class="row" v-if="targets.length > 0">
            <div class="col encounter text-center d-flex flex-column justify-content-center" v-for="(e, i) in targets" :key="i">
              <img class="mr-auto ml-auto" :src="getEnemyArt(e.power)" alt="Enemy">

              <div class="encounter-element">
                <span :class="getCharacterTrait(e.trait).toLowerCase()">{{getCharacterTrait(e.trait)}}</span>
                <span :class="getCharacterTrait(e.trait).toLowerCase()+'-icon'" />
              </div>

              <big-button
                class="encounter-button"
                :mainText="`Fight!`"
                :subText="`Power ${e.power}`"
                v-tooltip="'Cost 40 stamina'"
                :disabled="timeMinutes === 59 && timeSeconds >= 30"
                @click="onClickEncounter(e)"
              />

              <p v-if="isLoadingTargets">Loading...</p>
            </div>
          </div>

        </div>
      </div>

      <div>
      </div>
    </div>

    <div class="blank-slate" v-if="ownWeapons.length === 0 || ownCharacters.length === 0">
      <div v-if="ownWeapons.length === 0">
        You do not currently have any weapons. You can forge one at the Blacksmith.
      </div>

      <div v-if="ownCharacters.length === 0">
        You do not currently have any characters. You can recruit one at the Plaza.
      </div>
    </div>
  </div>
</template>

<script>
// import Character from "../components/Character.vue";
import BigButton from '../components/BigButton.vue';
import WeaponGrid from '../components/smart/WeaponGrid.vue';
import { getEnemyArt } from '../enemy-art';
import { CharacterTrait } from '../interfaces';
import Hint from '../components/Hint.vue';
import CombatResults from '../components/CombatResults.vue';
import Web3 from 'web3';
import BN from 'bignumber.js';

import { mapActions, mapGetters, mapState } from 'vuex';

export default {
  data() {
    return {
      selectedWeaponId: null,
      error: null,
      waitingResults: false,
      resultsAvailable: false,
      fightResults: null,
      intervalSeconds: null,
      intervalMinutes: null,
      timeSeconds: null,
      timeMinutes: null,
    };
  },

  created(){
    this.intervalSeconds = setInterval(() => this.timeSeconds = new Date().getSeconds(), 5000);
    this.intervalMinutes = setInterval(() => this.timeMinutes = new Date().getMinutes(), 20000);
  },

  computed: {
    ...mapState(['currentCharacterId']),
    ...mapGetters([
      'getTargetsByCharacterIdAndWeaponId',
      'ownCharacters',
      'ownWeapons',
      'currentCharacter',
      'currentCharacterStamina',
      'fightGasOffset',
      'fightBaseline',
    ]),

    targets() {
      return this.getTargetsByCharacterIdAndWeaponId(
        this.currentCharacterId,
        this.selectedWeaponId
      );
    },

    isLoadingTargets() {
      return (
        this.targets.length === 0 &&
        this.currentCharacterId &&
        this.selectedWeaponId
      );
    },

    selections() {
      return [this.currentCharacterId, this.selectedWeaponId];
    },
  },

  watch: {
    async selections([characterId, weaponId]) {
      await this.fetchTargets({ characterId, weaponId });
    },
  },

  methods: {
    ...mapActions(['fetchTargets', 'doEncounter', 'fetchFightRewardSkill', 'fetchFightRewardXp']),
    getEnemyArt,
    getCharacterTrait(trait) {
      return CharacterTrait[trait];
    },
    getPayoutString() {
      return 'Earnings on victory: '
        +this.formattedSkill(this.fightGasOffset) + ' gas offset + '
        +this.formattedSkill(this.fightBaseline)+' per 1000 power';
    },
    async onClickEncounter(targetToFight) {
      if (this.selectedWeaponId === null || this.currentCharacterId === null) {
        return;
      }

      try {
        this.waitingResults = true;
        const results = await this.doEncounter({
          characterId: this.currentCharacterId,
          weaponId: this.selectedWeaponId,
          targetString: targetToFight.original,
        });
        /*const success = results[0];
        const playerRoll = results[1];
        const enemyRoll = results[2];
        const xpGain = results[3];
        const skillGain = results[4];*/
        this.fightResults = results;

        this.resultsAvailable = true;
        // results are passed to the CombatResults element
        this.waitingResults = false;

        this.fetchFightRewardSkill();
        this.fetchFightRewardXp();

        /*if (success) {
          alert('Battle succeeded! You rolled '+playerRoll
          +' and the enemy rolled '+enemyRoll
          +', you gain '+xpGain+'xp and '+skillGain+' SKILL');
        } else {
          alert('Battle failed... You rolled '+playerRoll
          +' and the enemy rolled '+enemyRoll);
        }*/
        this.error = null;
      } catch (e) {
        console.error(e);
        this.error = e.message;
      }
    },
    formattedSkill(skill) {
      const skillBalance = Web3.utils.fromWei(skill, 'ether');
      return `${new BN(skillBalance).toFixed(6)} SKILL`;
    },
  },

  components: {
    // Character,
    BigButton,
    WeaponGrid,
    Hint,
    CombatResults,
  },
};
</script>

<style scoped>

.encounter img {
  max-width: 15vw;
}

.encounter-element {
  font-size: 2em;
}

.payout-info {
  margin: auto;
  text-align: center;
  padding-top: 1em;
  font-size: 1.5em;

  display: flex;
  justify-content: center;
  align-items: center;
}

.combat-hints {
  margin: auto;
  text-align: center;
  padding-right: 1em;
  padding-left: 1em;
  padding-bottom: 1em;
  font-size: 2em;

  display: flex;
  justify-content: center;
  align-items: center;
}

.combat-hints .hint {
  margin-left: 10px;
}

.waiting {
  font-size: 2em;
  margin: auto;
  text-align: center;
}

.header-row {
  display: flex;
  align-items: center;
}

.header-row h1 {
  margin-left: 10px;
  margin-bottom: 5px;
}

.header-row .hint {
  font-size: 2em;
}

.message-box {
  display: flex;
  justify-content: center;
  width: 100%;
  font-size: 2em;
}
</style>
