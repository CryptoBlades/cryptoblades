<template>
  <div>
    <h1>Combat</h1>
    <h1 style="color: red" v-if="error != null">Error: {{ error }}</h1>
    <character-list :value="currentCharacterId" @input="setCurrentCharacter" />
    <weapon-grid v-model="selectedWeaponId" />

    <ul class="encounter-list" v-if="targets.length > 0">
      <li v-for="(e, i) in targets" :key="i">
        <character />
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
</template>

<script>
import Character from "../components/Character.vue";
import BigButton from "../components/BigButton.vue";
import CharacterList from "../components/smart/CharacterList.vue";
import WeaponGrid from "../components/WeaponGrid.vue";

import { mapActions, mapGetters, mapMutations, mapState } from "vuex";

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
    ...mapMutations(["setCurrentCharacter"]),
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

  created() {},

  components: {
    Character,
    BigButton,
    CharacterList,
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

.encounter-button {
  width: 8cm;
}
</style>
