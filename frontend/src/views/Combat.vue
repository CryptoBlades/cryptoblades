<template>
  <div class="body main-font">
    <div v-if="ownWeapons.length > 0 && ownCharacters.length > 0">
      <h1 class="error" v-if="error !== null">Error: {{ error }}</h1>

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

      <CombatResults v-if="resultsAvailable" :results="fightResults" />

      <div class="stamina-warning" v-if="currentCharacterStamina < 20">
        You need 20 stamina to do battle.
      </div>

      <div v-if="currentCharacterStamina >= 20">
        <div class="loading-container waiting" v-if="waitingResults" margin="auto">
          <i class="fas fa-spinner fa-spin"></i>
          Waiting for fight results...
        </div>

        <div class="header-row">
          <Hint text="Your weapon multiplies your power<br>
            <br>+Stats determine the multiplier
            <br>Stat element match with character gives greater bonus" />
          <h1>Choose a weapon</h1>
        </div>

        <weapon-grid v-model="selectedWeaponId" />

        <ul class="encounter-list" v-if="targets.length > 0">
          <li class="encounter" v-for="(e, i) in targets" :key="i">
            <img :src="getEnemyArt(e.power)" alt="Enemy">
            <div class="encounter-element">
              <span :class="getCharacterTrait(e.trait).toLowerCase()">{{getCharacterTrait(e.trait)}}</span>
              <span :class="getCharacterTrait(e.trait).toLowerCase()+'-icon'" />
            </div>
            <big-button
              class="encounter-button"
              :mainText="`Fight!`"
              :subText="`Power ${e.power}`"
              v-tooltip="'Cost 20 stamina'"
              @click="onClickEncounter(e)"
            />
          </li>
        </ul>

        <p v-if="isLoadingTargets">Loading...</p>
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

import { mapActions, mapGetters, mapState } from 'vuex';

export default {
  data() {
    return {
      selectedWeaponId: null,
      error: null,
      waitingResults: false,
      resultsAvailable: false,
      fightResults: null,
    };
  },

  computed: {
    ...mapState(['currentCharacterId']),
    ...mapGetters([
      'getTargetsByCharacterIdAndWeaponId',
      'ownCharacters',
      'ownWeapons',
      'currentCharacterStamina'
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
    ...mapActions(['fetchTargets', 'doEncounter']),
    getEnemyArt,
    getCharacterTrait(trait) {
      return CharacterTrait[trait];
    },
    async onClickEncounter(targetToFight) {
      if (!this.selectedWeaponId || !this.currentCharacterId) {
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
.encounter-list {
  list-style-type: none;
  display: flex;
  margin: 0;
  padding: 0;
  justify-content: space-around;
}

.encounter {
  display: flex;
  flex-direction: column;
  align-items: center;
}

.encounter img {
  max-width: 19rem;
}

.encounter-button {
  width: 19rem;
}

.encounter-element {
  font-size: 2em;
}

.combat-hints {
  margin: auto;
  text-align: center;
  padding: 1em;
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

.stamina-warning {
  display: flex;
  justify-content: center;
  width: 100%;
  font-size: 2em;
}
</style>
