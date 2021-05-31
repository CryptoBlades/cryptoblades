<template>
  <div class="body main-font">
    <div v-if="ownWeapons.length > 0 && ownCharacters.length > 0">
      <h1 class="error" v-if="error !== null">Error: {{ error }}</h1>

      <div class="combat-hints">
        <img class="fire-icon"> {{ ">>" }}
        <img class="earth-icon"> {{ ">>" }}
        <img class="lightning-icon"> {{ ">>" }}
        <img class="water-icon"> {{ ">>" }}
        <img class="fire-icon">
      </div>
      <h1>Choose a weapon:</h1>
      <weapon-grid v-model="selectedWeaponId" />

      <ul class="encounter-list" v-if="targets.length > 0">
        <li class="encounter" v-for="(e, i) in targets" :key="i">
          <img :src="getEnemyArt(e.power)" alt="Enemy">
          <div class="encounter-element">
            <span :class="getCharacterTrait(e.trait).toLowerCase()">{{getCharacterTrait(e.trait)}}</span>
            <img :class="getCharacterTrait(e.trait).toLowerCase()+'-icon'">
          </div>
          <big-button
            class="encounter-button"
            :mainText="`Fight!`"
            :subText="`Power ${e.power}`"
            @click="onClickEncounter(e)"
          />
        </li>
      </ul>

      <p v-if="isLoadingTargets">Loading...</p>
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

import { mapActions, mapGetters, mapState } from 'vuex';

export default {
  data() {
    return {
      selectedWeaponId: null,
      error: null,
    };
  },

  computed: {
    ...mapState(['currentCharacterId']),
    ...mapGetters([
      'getTargetsByCharacterIdAndWeaponId',
      'ownCharacters',
      'ownWeapons',
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
        const results = await this.doEncounter({
          characterId: this.currentCharacterId,
          weaponId: this.selectedWeaponId,
          targetString: targetToFight.original,
        });
        // todo turn this into a proper popup with nice styling
        const success = results[0];
        const playerRoll = results[1];
        const enemyRoll = results[2];
        const xpGain = results[3];
        const skillGain = results[4];

        if (success) {
          alert('Battle succeeded! You rolled '+playerRoll
          +' and the enemy rolled '+enemyRoll
          +', you gain '+xpGain+'xp and '+skillGain+' SKILL');
        } else {
          alert('Battle failed... You rolled '+playerRoll
          +' and the enemy rolled '+enemyRoll);
        }
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
}
</style>
