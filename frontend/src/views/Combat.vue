<template>
  <div class="body main-font">
    <div v-if="ownWeapons.length > 0 && ownCharacters.length > 0">
      <h1 class="error" v-if="error !== null">Error: {{ error }}</h1>

      <h1>Choose a weapon:</h1>
      <weapon-grid v-model="selectedWeaponId" />

      <ul class="encounter-list" v-if="targets.length > 0">
        <li class="encounter" v-for="(e, i) in targets" :key="i">
          <img src="../assets/chara.png" alt="Placeholder character">
          <big-button
            class="encounter-button"
            :mainText="`Monster with trait ${e.trait}`"
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
import BigButton from "../components/BigButton.vue";
import WeaponGrid from "../components/smart/WeaponGrid.vue";

import { mapActions, mapGetters, mapState } from "vuex";

export default {
  data() {
    return {
      selectedWeaponId: null,
      error: null,
    };
  },

  computed: {
    ...mapState(["currentCharacterId"]),
    ...mapGetters([
      "getTargetsByCharacterIdAndWeaponId",
      "ownCharacters",
      "ownWeapons",
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
        this.currentCharacterId != null &&
        this.selectedWeaponId != null
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
    ...mapActions(["fetchTargets", "doEncounter"]),

    async onClickEncounter(targetToFight) {
      if (this.selectedWeaponId == null || this.currentCharacterId == null) {
        return;
      }

      try {
        const success = await this.doEncounter({
          characterId: this.currentCharacterId,
          weaponId: this.selectedWeaponId,
          targetString: targetToFight.original,
        });

        if (success) {
          alert("Battle succeeded!");
        } else {
          alert("Battle failed...");
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
  max-width: 10em;
}

.encounter-button {
  width: 19rem;
}
</style>
